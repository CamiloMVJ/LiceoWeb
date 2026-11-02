SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54400,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.CambioPlanificacion','U') IS NULL THROW 54400,N'Instale 019 primero.',1;
IF COL_LENGTH('dbo.Evaluacion','Version') IS NOT NULL OR OBJECT_ID('dbo.HistorialEvaluacion','U') IS NOT NULL THROW 54400,N'Etapa 020 instalada o parcial. Revise antes de repetir.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Evaluacion ADD Version rowversion;
 CREATE TABLE dbo.HistorialEvaluacion(
 Id bigint IDENTITY PRIMARY KEY,EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1));
 CREATE INDEX IX_HistorialEvaluacion_Evaluacion ON dbo.HistorialEvaluacion(EvaluacionId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
