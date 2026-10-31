SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53100,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.RevisionObligacion','U') IS NULL THROW 53100,N'Instale 009 primero.',1;
IF COL_LENGTH('dbo.PreparacionObligacion','Generacion') IS NOT NULL THROW 53100,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.PreparacionObligacion ADD Generacion int NOT NULL CONSTRAINT DF_Preparacion_Generacion DEFAULT 1;
 ALTER TABLE dbo.RevisionObligacion ADD Generacion int NOT NULL CONSTRAINT DF_Revision_Generacion DEFAULT 1;
 CREATE TABLE dbo.HistorialCaptura(
 Id bigint IDENTITY PRIMARY KEY,Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,
 GeneracionAnterior int NOT NULL,GeneracionNueva int NOT NULL,
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),
 DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1),
 Motivo nvarchar(500) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
 Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
