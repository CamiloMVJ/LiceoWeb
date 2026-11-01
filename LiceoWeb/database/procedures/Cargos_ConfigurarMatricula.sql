CREATE OR ALTER PROCEDURE dbo.Cargos_ConfigurarMatricula @UsuarioId nvarchar(450),@ArancelId int
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53600,N'No usar transacción externa.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N'Finanzas está ocupado.',1;
 IF EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula WHERE Id=1 AND ArancelId<>@ArancelId) THROW 53602,N'El arancel de matrícula ya está definido. No se puede sustituir sin revisar el historial.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Arancel A JOIN dbo.ConfiguracionCargo C ON C.ArancelId=A.Id WHERE A.Id=@ArancelId AND A.Activo=1 AND C.Periodicidad='Anual') THROW 53602,N'Selecciona un arancel activo con periodicidad anual.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula WHERE Id=1)
 BEGIN
  INSERT dbo.ConfiguracionMatricula(Id,ArancelId) VALUES(1,@ArancelId);
  DECLARE @Operacion uniqueidentifier=NEWID(),@Json nvarchar(max)=(SELECT @ArancelId ArancelId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,'ConfigurarMatricula','ConfiguracionMatricula','1',@Operacion,NULL,@Json;
 END;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
