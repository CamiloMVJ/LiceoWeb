-- Compatibilidad con /Mensualidades antes del corte. No usa Registro_Pagos.
IF DB_NAME() NOT IN (N'LiceoWeb_Dev',N'LiceoWeb_Limpia')
    THROW 53920,N'Selecciona una base de desarrollo de LiceoWeb.',1;
GO
CREATE OR ALTER PROCEDURE dbo.Buscar_Estudiantes_Mensualidad @TextoBusqueda nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (4) Registro,NombreEstudiante,Grado
    FROM dbo.Estudiantes
    WHERE Estado=N'Activo' AND LEN(TRIM(@TextoBusqueda))>=2
      AND (CHARINDEX(TRIM(@TextoBusqueda),NombreEstudiante COLLATE Latin1_General_100_CI_AI)>0 OR Registro=TRIM(@TextoBusqueda))
    ORDER BY NombreEstudiante,Registro;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Ver_Estado_Mensualidad_Cuenta @TextoBusqueda nvarchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT E.NombreEstudiante,E.Modalidad,E.Grado,ISNULL(A.Abono_Disponible,0) SaldoFavor,
           M.Anio,M.Mes,M.Costo_Mensualidad,M.Estado
    FROM dbo.Estudiantes E LEFT JOIN dbo.Abonos A ON A.Registro_Estudiante=E.Registro
    LEFT JOIN dbo.Mensualidades M ON M.Registro_Estudiante=E.Registro AND M.Estado IN (N'Pendiente',N'Vencido')
    WHERE E.Registro=@TextoBusqueda AND E.Estado=N'Activo'
    ORDER BY M.Anio,M.Numero_Mes;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Pagar_Mensualidad
    @Registro nvarchar(10), @Monto decimal(18,2), @Descripcion nvarchar(100),
    @IntegrarSaldo bit, @Metodo_Pago nvarchar(20), @Referencia nvarchar(100),
    @Anio_Limite int, @Numero_Mes_Limite int, @UsuarioId nvarchar(450),
    @Operacion uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @@TRANCOUNT<>0 THROW 53920,N'Ejecuta el cobro sin transacciones externas.',1;
    IF @Monto IS NULL OR @Monto<0 OR @IntegrarSaldo IS NULL OR @Operacion IS NULL
       OR @Operacion='00000000-0000-0000-0000-000000000000' OR @Anio_Limite IS NULL
       OR @Numero_Mes_Limite IS NULL OR @Anio_Limite NOT BETWEEN 1900 AND 9999
       OR @Numero_Mes_Limite NOT BETWEEN 1 AND 12
       THROW 53920,N'Monto, período u operación inválidos.',1;
    IF @Monto>0 AND (@Metodo_Pago IS NULL OR @Metodo_Pago NOT IN (N'Efectivo',N'Transferencia'))
       THROW 53920,N'Método de pago inválido.',1;
    IF @Monto>0 AND @Metodo_Pago=N'Transferencia' AND NULLIF(TRIM(@Referencia),N'') IS NULL
       THROW 53920,N'La transferencia requiere referencia.',1;
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
        WHERE U.UserId=@UsuarioId AND R.Name IN (N'Administrador',N'Cajero'))
       OR EXISTS (SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
       THROW 53921,N'Acceso financiero denegado.',1;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Bloqueo int;
        EXEC @Bloqueo=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',
             @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @Bloqueo<0 THROW 53920,N'Hay otra operación financiera en curso.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ControlFinanciero WITH (UPDLOCK,HOLDLOCK) WHERE Id=1 AND Migrado=0)
            THROW 53922,N'El libro anterior está cerrado o no se pudo verificar. Usa Estado de cuenta y cobros.',1;
        IF EXISTS (SELECT 1 FROM dbo.Historial_Comprobantes WHERE IdOperacion=@Operacion)
            THROW 53923,N'La operación ya se registró. Consulta el comprobante antes de cobrar de nuevo.',1;

        DECLARE @Modalidad nvarchar(20), @Grado nvarchar(50), @Saldo decimal(18,2)=0;
        SELECT @Modalidad=Modalidad,@Grado=Grado FROM dbo.Estudiantes WITH (UPDLOCK,HOLDLOCK)
        WHERE Registro=@Registro AND Estado=N'Activo';
        IF @Modalidad IS NULL THROW 53920,N'Selecciona un estudiante activo.',1;
        SELECT @Saldo=Abono_Disponible FROM dbo.Abonos WITH (UPDLOCK,HOLDLOCK)
        WHERE Registro_Estudiante=@Registro;

        DECLARE @Cuotas TABLE (Id int PRIMARY KEY, Importe decimal(18,2));
        INSERT INTO @Cuotas
        SELECT Id,Costo_Mensualidad
        FROM (
            SELECT Id,Costo_Mensualidad,
                SUM(CONVERT(decimal(38,2),Costo_Mensualidad)) OVER
                    (ORDER BY Anio,Numero_Mes,Id ROWS UNBOUNDED PRECEDING) Acumulado
            FROM dbo.Mensualidades WITH (UPDLOCK,HOLDLOCK)
            WHERE Registro_Estudiante=@Registro AND Estado IN (N'Pendiente',N'Vencido')
              AND (Anio<@Anio_Limite OR (Anio=@Anio_Limite AND Numero_Mes<=@Numero_Mes_Limite))
        ) C WHERE Acumulado<=@Monto+@Saldo;

        DECLARE @Deuda decimal(18,2)=(SELECT ISNULL(SUM(Importe),0) FROM @Cuotas);
        IF @Deuda=0 AND (@Monto=0 OR @IntegrarSaldo=0)
            THROW 53920,N'No hay fondos suficientes para una cuota completa dentro del período.',1;
        DECLARE @Utilizado decimal(18,2)=CASE WHEN @Saldo<@Deuda THEN @Saldo ELSE @Deuda END;
        DECLARE @Cambio decimal(18,2)=CASE WHEN @IntegrarSaldo=1 THEN 0 ELSE @Monto-(@Deuda-@Utilizado) END;
        IF @Monto>0 AND @Metodo_Pago=N'Transferencia' AND @Cambio>0
            THROW 53920,N'No se devuelve cambio en transferencias. Revisa el monto o integra el sobrante al saldo.',1;
        DECLARE @Final decimal(18,2)=@Saldo+@Monto-@Deuda-@Cambio;
        DECLARE @Concepto nvarchar(35)=CASE WHEN @Monto=0 THEN N'Uso de Saldo' ELSE N'Mensualidad' END;
        DECLARE @Metodo nvarchar(15)=CASE WHEN @Monto=0 THEN N'Saldo' ELSE @Metodo_Pago END;
        DECLARE @Comprobante nvarchar(25);
        EXEC dbo.Registrar_Comprobante @Registro=@Registro,@Concepto=@Concepto,@MetodoPago=@Metodo,
            @Referencia=@Referencia,@Descripcion=@Descripcion,@UsuarioId=@UsuarioId,@IdOperacion=@Operacion,
            @Modalidad=@Modalidad,@Grado=@Grado,@DineroRecibido=@Monto,@SaldoAnterior=@Saldo,
            @SaldoUtilizado=@Utilizado,@DeudaCancelada=@Deuda,@CambioDevuelto=@Cambio,@SaldoFinal=@Final,
            @IdComprobante=@Comprobante OUTPUT;
        UPDATE M SET Estado=N'Cancelado',Id_Comprobante=@Comprobante
        FROM dbo.Mensualidades M JOIN @Cuotas C ON C.Id=M.Id;
        UPDATE dbo.Abonos SET Abono_Disponible=@Final WHERE Registro_Estudiante=@Registro;
        IF @@ROWCOUNT=0 INSERT dbo.Abonos(Registro_Estudiante,Abono_Disponible) VALUES(@Registro,@Final);
        COMMIT;
        SELECT @Comprobante IdRecibo,@Comprobante IdComprobante,@Cambio Cambio,@Final SaldoFinal;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
