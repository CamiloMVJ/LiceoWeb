-- Ejecutar COMPLETO con F5. Prueba de infraestructura, NO de cancelacion de deudas.
-- No conserva estudiante, pago ni auditoria. La secuencia y los IDENTITY pueden saltar.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 51400, N'Seleccione LiceoWeb_Dev.', 1;
IF @@TRANCOUNT <> 0
    THROW 51401, N'Cierre cualquier transaccion anterior antes de esta prueba.', 1;

DECLARE @UsuarioId nvarchar(450) = (
    SELECT TOP (1) U.Id FROM dbo.AspNetUsers U
    JOIN dbo.AspNetUserRoles UR ON UR.UserId = U.Id
    JOIN dbo.AspNetRoles R ON R.Id = UR.RoleId
    WHERE R.Name = N'Administrador' AND U.EmailConfirmed = 1 ORDER BY U.Id);
IF @UsuarioId IS NULL
    THROW 51402, N'Primero cree la cuenta de administrador del paso 6.', 1;

DECLARE @PagosAntes int = (SELECT COUNT(*) FROM dbo.Pagos);
DECLARE @HistorialAntes int = (SELECT COUNT(*) FROM dbo.Historial_Comprobantes);
DECLARE @AuditoriaAntes bigint = (SELECT COUNT_BIG(*) FROM dbo.Auditoria);
DECLARE @Registros TABLE (Registro nvarchar(10));
DECLARE @Registro nvarchar(10), @Recibo nvarchar(25), @Operacion uniqueidentifier = NEWID();

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Estudiantes (
        NombreEstudiante, Modalidad, Grado, FechaNacimiento,
        Sexo, NombreTutor, Telefono, Direccion)
    OUTPUT inserted.Registro INTO @Registros
    VALUES (
        N'PRUEBA TEMPORAL ETAPA 8', N'Primaria', N'1er Grado', '20180115',
        'M', N'TUTOR FICTICIO', N'00000000', N'DIRECCION FICTICIA');
    SELECT @Registro = Registro FROM @Registros;

    EXEC dbo.Registrar_Comprobante
        @Registro = @Registro, @Concepto = N'Mensualidad',
        @MetodoPago = N'Efectivo', @Referencia = NULL,
        @Descripcion = N'PRUEBA QUE SE REVIERTE',
        @UsuarioId = @UsuarioId, @IdOperacion = @Operacion,
        @Modalidad = N'Primaria', @Grado = N'1er Grado',
        @DineroRecibido = 1000.00, @SaldoAnterior = 0.00,
        @SaldoUtilizado = 0.00, @DeudaCancelada = 800.00,
        @CambioDevuelto = 200.00, @SaldoFinal = 0.00,
        @IdComprobante = @Recibo OUTPUT;

    -- Simula un cambio posterior: el recibo debe seguir mostrando Primaria/1er Grado.
    UPDATE dbo.Estudiantes SET Modalidad = N'Secundaria', Grado = N'7mo Grado'
    WHERE Registro = @Registro;

    IF NOT EXISTS (SELECT 1 FROM dbo.Historial_Comprobantes
        WHERE Id_Comprobante = @Recibo AND Modalidad = N'Primaria'
        AND Grado = N'1er Grado' AND DineroRecibido = 1000.00
        AND CambioDevuelto = 200.00)
        THROW 51403, N'Fallo la captura historica.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Auditoria
        WHERE RegistroId = @Recibo AND IdOperacion = @Operacion
        AND UsuarioId = @UsuarioId AND Accion = N'RegistrarCobro')
        THROW 51404, N'Fallo la auditoria.', 1;

    EXEC dbo.Obtener_ComprobanteHistorico @IdComprobante = @Recibo;
    SELECT * FROM dbo.Auditoria WHERE IdOperacion = @Operacion;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

IF @PagosAntes <> (SELECT COUNT(*) FROM dbo.Pagos)
   OR @HistorialAntes <> (SELECT COUNT(*) FROM dbo.Historial_Comprobantes)
   OR @AuditoriaAntes <> (SELECT COUNT_BIG(*) FROM dbo.Auditoria)
    THROW 51405, N'Los conteos cambiaron. Revise si hubo otras operaciones concurrentes.', 1;

SELECT N'PRUEBA CORRECTA: datos temporales revertidos.' AS Resultado;
