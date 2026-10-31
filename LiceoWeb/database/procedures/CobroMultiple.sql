CREATE OR ALTER PROCEDURE dbo.Finanzas_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name IN ('Administrador','Cajero')) THROW 53501,N'Acceso financiero requerido.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CobroMultiple_Registrar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@Pagador nvarchar(200),
 @Metodo nvarchar(20),@Referencia nvarchar(100)=NULL,@Recibido decimal(28,8),@SaldoAplicado decimal(28,8),@Aplicaciones nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53500,N'No usar transacción externa.',1;
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000' OR NULLIF(LTRIM(RTRIM(@Pagador)),'') IS NULL OR @Metodo NOT IN ('Efectivo','Transferencia','Saldo') OR @Metodo IS NULL THROW 53502,N'Datos incompletos.',1;
 IF @Recibido IS NULL OR @SaldoAplicado IS NULL OR @Recibido<0 OR @SaldoAplicado<0 OR @Recibido>9999999999999999.99 OR @SaldoAplicado>9999999999999999.99 OR ROUND(@Recibido,2)<>@Recibido OR ROUND(@SaldoAplicado,2)<>@SaldoAplicado THROW 53502,N'Importes inválidos: use hasta dos decimales.',1;
 IF ISJSON(@Aplicaciones)<>1 OR LEFT(LTRIM(@Aplicaciones),1)<>'[' THROW 53502,N'Aplicaciones inválidas.',1;
 DECLARE @Items TABLE(CargoId bigint,Importe decimal(28,8));
 INSERT @Items SELECT TRY_CONVERT(bigint,JSON_VALUE(value,'$.CargoId')),TRY_CONVERT(decimal(28,8),JSON_VALUE(value,'$.Importe')) FROM OPENJSON(@Aplicaciones);
 IF (SELECT COUNT(*) FROM @Items) NOT BETWEEN 1 AND 50 OR EXISTS(SELECT 1 FROM @Items WHERE CargoId IS NULL OR Importe IS NULL OR Importe<=0 OR ROUND(Importe,2)<>Importe OR Importe>9999999999999999.99) OR EXISTS(SELECT CargoId FROM @Items GROUP BY CargoId HAVING COUNT(*)>1) THROW 53502,N'Seleccione entre 1 y 50 cargos distintos con importes positivos.',1;
 DECLARE @Total decimal(38,8)=(SELECT SUM(Importe) FROM @Items);
 IF @Total>9999999999999999.99 OR @SaldoAplicado>@Total OR @Recibido+@SaldoAplicado<@Total THROW 53502,N'El dinero y saldo no cubren el importe seleccionado.',1;
 DECLARE @Cambio decimal(18,2)=@Recibido+@SaldoAplicado-@Total;
 IF (@Metodo='Transferencia' AND (NULLIF(LTRIM(RTRIM(@Referencia)),'') IS NULL OR @Cambio<>0 OR @Recibido<=0)) OR (@Metodo='Saldo' AND @Recibido<>0) OR (@Metodo='Efectivo' AND @Recibido<=0) THROW 53502,N'Revise método, referencia e importe recibido. Transferencias sin vuelto; saldo sin dinero recibido.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@Pagador Pagador,@Metodo Metodo,@Referencia Referencia,@Recibido Recibido,@SaldoAplicado SaldoAplicado,JSON_QUERY((SELECT CargoId,Importe FROM @Items ORDER BY CargoId FOR JSON PATH)) Aplicaciones FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Id bigint,@Numero nvarchar(25),@Saldo decimal(18,2)=0,@Nombre nvarchar(100),@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Mismo orden que configuración/corte; serializa cobros de este colegio pequeño.
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53503,N'Finanzas está ocupado. Reintente con la misma operación.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53502,N'El libro nuevo requiere el corte financiero aprobado.',1;
 SELECT @Id=Id,@Numero=Numero FROM dbo.ReciboMultiple WITH(UPDLOCK,HOLDLOCK) WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53502,N'Esta operación ya se usó con otros datos. Consulte el recibo antes de continuar.',1;
  COMMIT;SELECT @Id Id,@Numero Numero;RETURN;
 END;
 SELECT @Nombre=NombreEstudiante FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Nombre IS NULL THROW 53502,N'Estudiante inexistente.',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @SaldoAplicado>@Saldo THROW 53502,N'Saldo a favor insuficiente. Actualice la consulta.',1;
 IF EXISTS(SELECT 1 FROM @Items I LEFT JOIN dbo.CargoEstudiante C WITH(UPDLOCK,HOLDLOCK) ON C.Id=I.CargoId WHERE C.Id IS NULL OR C.Registro<>@Registro OR C.Anulado=1 OR I.Importe>C.Importe-ISNULL((SELECT SUM(A.Importe) FROM dbo.AplicacionPago A WITH(UPDLOCK,HOLDLOCK) WHERE A.CargoId=C.Id),0)) THROW 53502,N'Un cargo no pertenece al estudiante, está anulado o su deuda cambió.',1;
 DECLARE @Secuencia bigint=NEXT VALUE FOR dbo.Secuencia_Comprobantes;
 SET @Numero=N'RC-'+CONVERT(nvarchar(20),@Secuencia);
 IF EXISTS(SELECT 1 FROM dbo.Pagos WHERE Id_Comprobante=@Numero) THROW 53502,N'Numeración ocupada. Revise la secuencia con administración.',1;
 INSERT dbo.ReciboMultiple(Numero,Operacion,Registro,Pagador,UsuarioId,Metodo,Referencia,Recibido,Cambio,SolicitudHash,NombreEstudiante,SaldoAnterior,SaldoAplicado,SaldoFinal,TotalAplicado)
 VALUES(@Numero,@Operacion,@Registro,@Pagador,@UsuarioId,@Metodo,@Referencia,@Recibido,@Cambio,@Hash,@Nombre,@Saldo,@SaldoAplicado,@Saldo-@SaldoAplicado,@Total);
 SET @Id=SCOPE_IDENTITY();
 INSERT dbo.AplicacionPago(ReciboId,CargoId,Importe,DescripcionHistorica) SELECT @Id,I.CargoId,I.Importe,C.DescripcionHistorica FROM @Items I JOIN dbo.CargoEstudiante C ON C.Id=I.CargoId;
 IF @SaldoAplicado>0 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible-@SaldoAplicado WHERE Registro=@Registro;
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Id),@Json nvarchar(max)=(SELECT @Numero Numero,@Registro Registro,@Total TotalAplicado,@Recibido Recibido,@Cambio Cambio,@SaldoAplicado SaldoAplicado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'CobroMultiple','ReciboMultiple',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;
 SELECT @Id Id,@Numero Numero;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CuentaEstudiante_Consultar @UsuarioId nvarchar(450),@Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Shared',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53503,N'Finanzas está ocupado.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WHERE Registro=@Registro) THROW 53502,N'Estudiante inexistente.',1;
 SELECT E.Registro,E.NombreEstudiante,ISNULL(S.Disponible,0) SaldoFavor,CONVERT(bit,ISNULL((SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1),0)) Migrado FROM dbo.Estudiantes E LEFT JOIN dbo.SaldoFinanciero S ON S.Registro=E.Registro WHERE E.Registro=@Registro;
 SELECT C.Id,C.DescripcionHistorica,C.Vencimiento,C.Importe,ISNULL(A.Pagado,0) Pagado,C.Importe-ISNULL(A.Pagado,0) Pendiente FROM dbo.CargoEstudiante C OUTER APPLY(SELECT SUM(Importe) Pagado FROM dbo.AplicacionPago WHERE CargoId=C.Id) A WHERE C.Registro=@Registro AND C.Anulado=0 ORDER BY C.Id;
 SELECT Id,Numero,Fecha,Metodo,Recibido,Cambio,SaldoAplicado,TotalAplicado FROM dbo.ReciboMultiple WHERE Registro=@Registro ORDER BY Id DESC;
 -- Solo referencia histórica. NO sumarla a ingresos ni deuda del libro nuevo.
 SELECT Id_Comprobante,Fecha_Pago,Concepto,Monto FROM dbo.Pagos WHERE Registro_Estudiante=@Registro ORDER BY Fecha_Pago DESC,Id_Comprobante;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.ReciboMultiple_Consultar @UsuarioId nvarchar(450),@Id bigint
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id) THROW 53504,N'Recibo inexistente.',1;
 SELECT R.*,U.UserName Responsable FROM dbo.ReciboMultiple R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId WHERE R.Id=@Id;
 SELECT CargoId,DescripcionHistorica,Importe FROM dbo.AplicacionPago WHERE ReciboId=@Id ORDER BY CargoId;
END;
GO
