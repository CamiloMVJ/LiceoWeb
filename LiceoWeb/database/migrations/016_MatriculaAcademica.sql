SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53800,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.AnulacionRecibo','U') IS NULL THROW 53800,N'Instale 015 primero.',1;
IF OBJECT_ID('dbo.MatriculaAcademica','U') IS NOT NULL THROW 53800,N'Migración ya instalada.',1;
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE dbo.ConfiguracionMatricula(Id int PRIMARY KEY CHECK(Id=1),ArancelId int NOT NULL UNIQUE REFERENCES dbo.Arancel(Id));
INSERT dbo.ConfiguracionMatricula(Id,ArancelId) SELECT 1,ArancelId FROM dbo.MapaConceptoLegado WHERE Origen='Matriculas';
CREATE TABLE dbo.MatriculaAcademica(
 Id bigint IDENTITY PRIMARY KEY,Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 Anio int NOT NULL,Modalidad nvarchar(80) NOT NULL,Nivel nvarchar(50) NOT NULL,
 CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),MatriculaLegadaId int NULL REFERENCES dbo.Matriculas(Id),
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_MatriculaAcademica_Anio UNIQUE(Registro,Anio),
 CONSTRAINT CK_MatriculaAcademica_Origen CHECK((CargoId IS NOT NULL AND MatriculaLegadaId IS NULL) OR (CargoId IS NULL AND MatriculaLegadaId IS NOT NULL)));

COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
