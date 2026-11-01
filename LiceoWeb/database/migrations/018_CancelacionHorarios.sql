SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54200,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.HorarioClase','U') IS NULL OR OBJECT_ID('dbo.LoteMensualidades','U') IS NULL THROW 54200,N'Complete las migraciones anteriores hasta 017.',1;
IF OBJECT_ID('dbo.CancelacionHorario','U') IS NOT NULL OR COL_LENGTH('dbo.HorarioClase','Version') IS NOT NULL THROW 54200,N'Etapa 018 instalada o parcial. Revise antes de repetir.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.HorarioClase ADD Version rowversion;
 CREATE TABLE dbo.CancelacionHorario(
  HorarioId int NOT NULL CONSTRAINT PK_CancelacionHorario PRIMARY KEY REFERENCES dbo.HorarioClase(Id),
  Operacion uniqueidentifier NOT NULL CONSTRAINT UQ_CancelacionHorario_Operacion UNIQUE,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),VersionHorario binary(8) NOT NULL,
  Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1)
 );
 EXEC sys.sp_executesql N'CREATE OR ALTER VIEW dbo.HorarioClaseVigente AS
 SELECT H.Id,H.AsignacionId,H.Dia,H.Inicio,H.Fin,H.Version FROM dbo.HorarioClase H
 WHERE NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario C WHERE C.HorarioId=H.Id);';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
