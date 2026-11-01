SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54300,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.CancelacionHorario','U') IS NULL THROW 54300,N'Instale 018 primero.',1;
IF OBJECT_ID('dbo.CambioPlanificacion','U') IS NOT NULL OR COL_LENGTH('dbo.AsignacionDocente','Version') IS NOT NULL OR COL_LENGTH('dbo.GrupoEstudiante','Version') IS NOT NULL THROW 54300,N'Etapa 019 instalada o parcial. Revise antes de repetir.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.AsignacionDocente ADD Version rowversion;
 ALTER TABLE dbo.GrupoEstudiante ADD Version rowversion;
 CREATE TABLE dbo.CambioPlanificacion(
 Id bigint IDENTITY PRIMARY KEY,Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 Tipo nvarchar(20) NOT NULL CHECK(Tipo IN ('Docente','Estudiante')),OrigenId int NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1)
 );
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
