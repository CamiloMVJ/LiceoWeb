CREATE OR ALTER PROCEDURE dbo.ReciboMultiple_Anular
 @UsuarioId nvarchar(450),@ReciboId bigint,@Operacion uniqueidentifier,@Motivo nvarchar(500),
 @ReferenciaDevolucion nvarchar(100),@Receptor nvarchar(200),@Confirmado bit
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @@TRANCOUNT<>0 THROW 53700,N'No usar transacción externa.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53701,N'Solo administración puede anular recibos.',1;
 IF @Confirmado IS NULL OR @Confirmado<>1 OR @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000' OR NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL OR NULLIF(LTRIM(RTRIM(@ReferenciaDevolucion)),'') IS NULL OR NULLIF(LTRIM(RTRIM(@Receptor)),'') IS NULL THROW 53702,N'Confirme la devolución y complete motivo, receptor y referencia documental.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@ReciboId ReciboId,@Motivo Motivo,@ReferenciaDevolucion Referencia,@Receptor Receptor FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@Hash binary(32);
 SET @Hash=HASHBYTES('SHA2_256',@Solicitud);
 DECLARE @Id bigint,@Lock int,@Registro nvarchar(10),@Dinero decimal(18,2),@SaldoUsado decimal(18,2),@Total decimal(18,2),@Saldo decimal(18,2)=0;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53703,N'Finanzas está ocupado. Reintente la misma operación.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53702,N'El libro nuevo no está habilitado.',1;
 SELECT @Id=Id FROM dbo.AnulacionRecibo WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.AnulacionRecibo WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53702,N'La operación ya se usó con otros datos.',1;
  COMMIT;SELECT @Id Id;RETURN;
 END;
 SELECT @Registro=Registro,@Dinero=Recibido-Cambio,@SaldoUsado=SaldoAplicado,@Total=TotalAplicado FROM dbo.ReciboMultiple WITH(UPDLOCK,HOLDLOCK) WHERE Id=@ReciboId;
 IF @Registro IS NULL THROW 53704,N'Recibo inexistente.',1;
 IF EXISTS(SELECT 1 FROM dbo.AnulacionRecibo WHERE ReciboId=@ReciboId) THROW 53702,N'El recibo ya está anulado. Consulte su historial.',1;
 IF @Total<>ISNULL((SELECT SUM(Importe) FROM dbo.AplicacionPago WHERE ReciboId=@ReciboId),0) OR @Total<>@Dinero+@SaldoUsado THROW 53702,N'El recibo presenta un balance inconsistente. Requiere revisión.',1;
 IF EXISTS(SELECT 1 FROM dbo.AplicacionPago A JOIN dbo.CargoEstudiante C ON C.Id=A.CargoId WHERE A.ReciboId=@ReciboId AND (C.Anulado=1 OR C.Registro<>@Registro)) THROW 53702,N'Un cargo fue anulado o no corresponde al estudiante. Requiere revisión.',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @SaldoUsado>0 AND NOT EXISTS(SELECT 1 FROM dbo.SaldoFinanciero WHERE Registro=@Registro) THROW 53702,N'No existe la cuenta de saldo original.',1;
 IF CONVERT(decimal(19,2),@Saldo)+@SaldoUsado>9999999999999999.99 THROW 53702,N'El saldo resultante excede el límite permitido.',1;
 INSERT dbo.AnulacionRecibo(ReciboId,Operacion,SolicitudHash,UsuarioId,Motivo,ReferenciaDevolucion,Receptor,DineroDevuelto,SaldoRestituido,SaldoAnterior,SaldoFinal,TotalRevertido)
 VALUES(@ReciboId,@Operacion,@Hash,@UsuarioId,@Motivo,@ReferenciaDevolucion,@Receptor,@Dinero,@SaldoUsado,@Saldo,@Saldo+@SaldoUsado,@Total);
 SET @Id=SCOPE_IDENTITY();
 IF @SaldoUsado>0 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible+@SaldoUsado WHERE Registro=@Registro;
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@ReciboId),@Json nvarchar(max)=(SELECT @Id AnulacionId,@Dinero DineroDevuelto,@SaldoUsado SaldoRestituido,@Total DeudaReabierta,@Motivo Motivo,@ReferenciaDevolucion ReferenciaDevolucion,@Receptor Receptor FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'AnularRecibo','ReciboMultiple',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;SELECT @Id Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
