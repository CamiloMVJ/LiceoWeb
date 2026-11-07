CREATE OR ALTER PROCEDURE dbo.Anticipo_Registrar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@Pagador nvarchar(200),
 @Metodo nvarchar(20),@Referencia nvarchar(100)=NULL,@Importe decimal(28,8)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 54700,N'No usar transacción externa.',1;
 SET @Pagador=NULLIF(TRIM(@Pagador),N'');
 SET @Referencia=NULLIF(TRIM(@Referencia),N'');
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
 OR @Pagador IS NULL OR @Metodo IS NULL OR @Metodo NOT IN ('Efectivo','Transferencia')
 OR (@Metodo='Transferencia' AND @Referencia IS NULL)
 OR @Importe IS NULL OR @Importe<=0 OR @Importe>9999999999999999.99 OR ROUND(@Importe,2)<>@Importe
 THROW 54702,N'Revisa pagador, método, importe positivo y referencia de transferencia.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT N'Anticipo' Tipo,@UsuarioId UsuarioId,@Registro Registro,@Pagador Pagador,
 @Metodo Metodo,@Referencia Referencia,@Importe Importe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Id bigint,@Nombre nvarchar(100),@Saldo decimal(18,2)=0,@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54703,N'Finanzas está ocupado. Reintenta desde el mismo formulario.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54702,N'El libro nuevo requiere el corte financiero aprobado.',1;
 SELECT @Id=Id FROM dbo.ReciboMultiple WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId AND Anticipo>0)
   THROW 54702,N'La operación ya se usó con otros datos. Consulta los recibos.',1;
  COMMIT;SELECT @Id;RETURN;
 END;
 DECLARE @CorteCajaId bigint;
 SELECT @CorteCajaId=Id FROM dbo.CorteCaja WHERE Fin IS NULL;
 IF @CorteCajaId IS NULL THROW 54802,N'La caja está cerrada. Un administrador debe abrir un nuevo corte.',1;
 SELECT @Nombre=NombreEstudiante FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro AND Estado='Activo';
 IF @Nombre IS NULL THROW 54702,N'El anticipo requiere un estudiante activo.',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Saldo+@Importe>9999999999999999.99 THROW 54702,N'El saldo resultante excede el límite permitido.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SaldoFinanciero WHERE Registro=@Registro)
  INSERT dbo.SaldoFinanciero(Registro,RevisionSaldoId,SaldoInicial,Disponible) VALUES(@Registro,NULL,0,0);
 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible+@Importe WHERE Registro=@Registro;
 DECLARE @Secuencia bigint=NEXT VALUE FOR dbo.Secuencia_Comprobantes;
 DECLARE @Numero nvarchar(25)=N'RC-'+CONVERT(nvarchar(20),@Secuencia);
 INSERT dbo.ReciboMultiple(Numero,Operacion,Registro,Pagador,UsuarioId,Metodo,Referencia,Recibido,Cambio,SolicitudHash,
  NombreEstudiante,SaldoAnterior,SaldoAplicado,SaldoFinal,TotalAplicado,Anticipo,CorteCajaId)
 VALUES(@Numero,@Operacion,@Registro,@Pagador,@UsuarioId,@Metodo,@Referencia,@Importe,0,@Hash,@Nombre,@Saldo,0,@Saldo+@Importe,0,@Importe,@CorteCajaId);
 SET @Id=SCOPE_IDENTITY();
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Id),
  @Json nvarchar(max)=(SELECT @Registro Registro,@Numero Numero,@Importe Anticipo,@Saldo SaldoAnterior,@Saldo+@Importe SaldoFinal FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'RegistrarAnticipo','ReciboMultiple',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;SELECT @Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
