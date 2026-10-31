SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52600,N'Base incorrecta.',1;
IF OBJECT_ID('dbo.PublicacionNotas') IS NULL THROW 52600,N'Instale 006 primero.',1;
IF OBJECT_ID('dbo.HistorialCalificacion') IS NOT NULL THROW 52600,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.PublicacionNotas ADD Vigente bit NOT NULL CONSTRAINT DF_Publicacion_Vigente DEFAULT 1,Version rowversion;
 ALTER TABLE dbo.PeriodoAcademico ADD Version rowversion;
 CREATE TABLE dbo.HistorialCalificacion(
  Id bigint IDENTITY PRIMARY KEY,EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
  NotaAnterior decimal(7,2) NULL,NotaNueva decimal(7,2) NULL,ResultadoAnterior nvarchar(100) NULL,ResultadoNuevo nvarchar(100) NULL,
  ObservacionAnterior nvarchar(500) NULL,ObservacionNueva nvarchar(500) NULL,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Motivo nvarchar(500) NOT NULL
 );
 CREATE INDEX IX_HistorialCalificacion_Evaluacion ON dbo.HistorialCalificacion(EvaluacionId,Id);
 CREATE TABLE dbo.EventoAcademico(
  Id bigint IDENTITY PRIMARY KEY,PeriodoId int NOT NULL REFERENCES dbo.PeriodoAcademico(Id),AsignacionId int NULL REFERENCES dbo.AsignacionDocente(Id),
  Accion nvarchar(30) NOT NULL CHECK(Accion IN ('Publicar','ReabrirAsignacion','CerrarPeriodo','ReabrirPeriodo')),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Motivo nvarchar(500) NOT NULL,
  Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1)
 );
 CREATE INDEX IX_EventoAcademico_Periodo ON dbo.EventoAcademico(PeriodoId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
