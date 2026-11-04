SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54600,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.EstadoCuentaPersonal','U') IS NULL THROW 54600,N'Instale 021 primero.',1;
IF COL_LENGTH('dbo.TipoEvaluacion','Version') IS NOT NULL OR OBJECT_ID('dbo.HistorialTipoEvaluacion','U') IS NOT NULL
 THROW 54600,N'Etapa 022 instalada o parcial. Revise antes de repetir.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.TipoEvaluacion ADD Version rowversion;
 CREATE TABLE dbo.HistorialTipoEvaluacion(
 Id bigint IDENTITY PRIMARY KEY,TipoId int NOT NULL REFERENCES dbo.TipoEvaluacion(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
 Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 NombreAnterior nvarchar(100) NOT NULL,NombreNuevo nvarchar(100) NOT NULL,
 ActivoAnterior bit NOT NULL,ActivoNuevo bit NOT NULL);
 CREATE INDEX IX_HistorialTipoEvaluacion_Tipo ON dbo.HistorialTipoEvaluacion(TipoId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
