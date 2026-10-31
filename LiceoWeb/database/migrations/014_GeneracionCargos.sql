SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53600,N'Use desarrollo sin transacciones abiertas.',1;
IF COL_LENGTH('dbo.ReciboMultiple','SolicitudHash') IS NULL THROW 53600,N'Instale 013 primero.',1;
IF OBJECT_ID('dbo.ConfiguracionCargo','U') IS NOT NULL THROW 53600,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.ConfiguracionCargo(ArancelId int PRIMARY KEY REFERENCES dbo.Arancel(Id),Periodicidad nvarchar(10) NOT NULL CHECK(Periodicidad IN ('Anual','Mensual','Eventual')));
 -- Solo inferir periodicidad cuando todos los mapeos heredados coinciden.
 INSERT dbo.ConfiguracionCargo(ArancelId,Periodicidad)
 SELECT ArancelId,MIN(CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END)
 FROM dbo.MapaConceptoLegado GROUP BY ArancelId
 HAVING MIN(CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END)=MAX(CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END);
 CREATE TABLE dbo.GeneracionCargo(Operacion uniqueidentifier PRIMARY KEY,CargoId bigint NOT NULL UNIQUE REFERENCES dbo.CargoEstudiante(Id),SolicitudHash binary(32) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
