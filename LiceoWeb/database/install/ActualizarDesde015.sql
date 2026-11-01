:ON ERROR EXIT
:setvar DatabaseRoot "C:\Users\camil\source\repos\LiceoWeb\LiceoWeb\database"
-- SSMS: activar Consulta > Modo SQLCMD. Cambiar DatabaseRoot si clonó en otra ruta.
-- Detener la aplicación y respaldar LiceoWeb_Dev. No aplica el corte financiero.
USE [LiceoWeb_Dev];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' OR @@TRANCOUNT<>0
 THROW 54100,N'Use LiceoWeb_Dev sin transacciones abiertas.',1;
DECLARE @Requisitos TABLE(Objeto sysname,Tipo char(2));
INSERT @Requisitos VALUES
(N'dbo.AnioLectivo','U'),
(N'dbo.Arancel','U'),
(N'dbo.AspNetRoles','U'),
(N'dbo.AspNetUserRoles','U'),
(N'dbo.AspNetUsers','U'),
(N'dbo.CargoEstudiante','U'),
(N'dbo.ConfiguracionCargo','U'),
(N'dbo.ControlFinanciero','U'),
(N'dbo.Estudiantes','U'),
(N'dbo.GeneracionCargo','U'),
(N'dbo.MapaConceptoLegado','U'),
(N'dbo.Mensualidades','U'),
(N'dbo.ModalidadAcademica','U'),
(N'dbo.ObligacionMigrada','U'),
(N'dbo.RevisionObligacion','U'),
(N'dbo.TarifaArancel','U'),
(N'dbo.AsignacionDocente','U'),
(N'dbo.Asignatura','U'),
(N'dbo.Aula','U'),
(N'dbo.GrupoAcademico','U'),
(N'dbo.GrupoEstudiante','U'),
(N'dbo.HorarioClase','U'),
(N'dbo.Matriculas','U'),
(N'dbo.Pensum','U'),
(N'dbo.PensumAsignatura','U'),
(N'dbo.PeriodoAcademico','U'),
(N'dbo.PublicacionNotas','U'),
(N'dbo.TurnoAcademico','U'),
(N'dbo.AnulacionRecibo','U'),
(N'dbo.ReciboMultiple','U'),
(N'dbo.Registrar_Auditoria','P'),
(N'dbo.AplicacionPagoVigente','V');
IF EXISTS(SELECT 1 FROM @Requisitos WHERE OBJECT_ID(Objeto,Tipo) IS NULL)
BEGIN
 SELECT Objeto AS RequisitoFaltante FROM @Requisitos WHERE OBJECT_ID(Objeto,Tipo) IS NULL;
 THROW 54100,N'Faltan requisitos anteriores. Complete las etapas hasta 015 antes de actualizar.',1;
END;
IF COL_LENGTH('dbo.RevisionObligacion','Generacion') IS NULL
 OR COL_LENGTH('dbo.TarifaArancel','Version') IS NULL
 OR COL_LENGTH('dbo.ReciboMultiple','TotalAplicado') IS NULL
 OR COL_LENGTH('dbo.PublicacionNotas','Vigente') IS NULL
 THROW 54100,N'Esquema previo incompleto: revise las etapas 007, 008, 010 y 013.',1;
IF (OBJECT_ID('dbo.MatriculaAcademica','U') IS NULL AND OBJECT_ID('dbo.ConfiguracionMatricula','U') IS NOT NULL)
 OR (OBJECT_ID('dbo.MatriculaAcademica','U') IS NOT NULL AND OBJECT_ID('dbo.ConfiguracionMatricula','U') IS NULL)
 THROW 54100,N'La etapa 016 está parcial. Revise su instalación; no se modificó.',1;
GO
IF OBJECT_ID('dbo.MatriculaAcademica','U') IS NULL
BEGIN
:r "$(DatabaseRoot)\migrations\016_MatriculaAcademica.sql"
END;
GO
IF OBJECT_ID('dbo.LoteMensualidades','U') IS NULL
BEGIN
:r "$(DatabaseRoot)\migrations\017_LoteMensualidades.sql"
END;
GO
-- Las migraciones se conservan si falla luego la actualización de procedimientos.
-- Los procedimientos de este bloque se actualizan en una sola transacción.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
GO
:r "$(DatabaseRoot)\procedures\GeneracionCargos.sql"
:r "$(DatabaseRoot)\procedures\LoteMensualidades.sql"
:r "$(DatabaseRoot)\procedures\Planificacion.sql"
:r "$(DatabaseRoot)\procedures\ReporteFinanciero.sql"
COMMIT;
GO
:r "$(DatabaseRoot)\verification\018_VerificarActualizacion.sql"
