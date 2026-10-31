CREATE OR ALTER PROCEDURE dbo.Saldo_Instantanea @UsuarioId nvarchar(450),@Registro nvarchar(10),@Json nvarchar(max) OUTPUT,@Saldo decimal(18,2) OUTPUT,@Filas int OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53201,N'Se requiere administrador.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro) THROW 53200,N'Estudiante inexistente.',1;
 SELECT @Saldo=ISNULL(SUM(Abono_Disponible),0),@Filas=COUNT(*) FROM dbo.Abonos WITH(HOLDLOCK) WHERE Registro_Estudiante=@Registro;
 SET @Json=(SELECT @Registro Registro,@Saldo Saldo,@Filas FilasSaldo,
 JSON_QUERY((SELECT P.Id_Comprobante,P.Fecha_Pago,P.Concepto,P.Monto,P.Metodo_Pago,P.Referencia_Transaccion,
 H.DineroRecibido,H.CambioDevuelto,H.SaldoAnterior,H.SaldoUtilizado,H.DeudaCancelada,H.SaldoFinal
 FROM dbo.Pagos P WITH(HOLDLOCK) LEFT JOIN dbo.Historial_Comprobantes H WITH(HOLDLOCK) ON H.Id_Comprobante=P.Id_Comprobante
 WHERE P.Registro_Estudiante=@Registro ORDER BY P.Id_Comprobante FOR JSON PATH,INCLUDE_NULL_VALUES)) Pagos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Saldo_Consultar @UsuarioId nvarchar(450),@Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Json nvarchar(max),@Saldo decimal(18,2),@Filas int;
 EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
 SELECT @Registro Registro,@Saldo SaldoFavor,@Filas FilasSaldo,CONVERT(varchar(66),HASHBYTES('SHA2_256',@Json),1) Huella,
 ISNULL((SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro),0) RevisionAnterior;
 SELECT P.Id_Comprobante,P.Fecha_Pago,P.Concepto,P.Monto MontoHeredado,H.DineroRecibido,H.CambioDevuelto,H.SaldoAnterior,H.SaldoFinal,
 CASE WHEN H.Id_Comprobante IS NULL THEN N'SIN_HISTORIAL' WHEN H.SaldoAnterior+H.DineroRecibido<>H.DeudaCancelada+H.CambioDevuelto+H.SaldoFinal OR P.Monto<>H.DineroRecibido-H.CambioDevuelto THEN N'BALANCE_INCONSISTENTE' ELSE N'BALANCE_CON_HISTORIAL' END Revision
 FROM dbo.Pagos P LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante WHERE P.Registro_Estudiante=@Registro ORDER BY P.Fecha_Pago,P.Id_Comprobante;
 SELECT TOP(200) R.Id,R.SaldoObservado,R.Decision,R.Referencia,R.Motivo,U.UserName Responsable,R.Fecha,
 CASE WHEN R.Huella=HASHBYTES('SHA2_256',@Json) THEN N'COINCIDE_CON_FUENTE' ELSE N'FUENTE_CAMBIO' END EstadoFuente
 FROM dbo.RevisionSaldo R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId WHERE R.Registro=@Registro ORDER BY R.Id DESC;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Saldo_Revisar @UsuarioId nvarchar(450),@Registro nvarchar(10),@Huella varchar(66),@RevisionAnterior bigint,@Decision nvarchar(20),@Referencia nvarchar(200),@Motivo nvarchar(500)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Decision IS NULL OR @Decision NOT IN ('Aprobado','Rechazado') OR NULLIF(TRIM(@Motivo),'') IS NULL OR NULLIF(TRIM(@Referencia),'') IS NULL THROW 53200,N'Decisión, referencia y motivo obligatorios.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Json nvarchar(max),@Saldo decimal(18,2),@Filas int,@Hash binary(32),@Operacion uniqueidentifier=NEWID();
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53202,N'Hay otra operación en curso.',1;
 EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
 SET @Hash=HASHBYTES('SHA2_256',@Json);
 IF @Huella IS NULL OR TRY_CONVERT(binary(32),@Huella,1) IS NULL OR @Hash<>TRY_CONVERT(binary(32),@Huella,1) THROW 53203,N'Los saldos o pagos cambiaron. Consulta nuevamente.',1;
 IF @RevisionAnterior IS NULL OR ISNULL((SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro),0)<>@RevisionAnterior THROW 53203,N'Otra persona revisó este saldo. Consulta nuevamente.',1;
 IF @Decision='Aprobado' AND (@Filas>1 OR @Saldo<0) THROW 53204,N'No se aprueban saldos negativos ni duplicados.',1;
 IF @Decision='Aprobado' AND EXISTS(SELECT 1 FROM dbo.Pagos P JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante WHERE P.Registro_Estudiante=@Registro AND (H.SaldoAnterior+H.DineroRecibido<>H.DeudaCancelada+H.CambioDevuelto+H.SaldoFinal OR P.Monto<>H.DineroRecibido-H.CambioDevuelto)) THROW 53204,N'Hay comprobantes con balance inconsistente.',1;
 INSERT dbo.RevisionSaldo(Registro,SaldoObservado,FilasSaldo,Huella,Instantanea,Decision,Referencia,Motivo,UsuarioId) VALUES(@Registro,@Saldo,@Filas,@Hash,@Json,@Decision,TRIM(@Referencia),TRIM(@Motivo),@UsuarioId);
 DECLARE @Despues nvarchar(max)=(SELECT @Saldo SaldoObservado,@Decision Decision,@Referencia Referencia,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'RevisarSaldo',@Entidad=N'ConciliacionSaldo',@RegistroId=@Registro,@IdOperacion=@Operacion,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
