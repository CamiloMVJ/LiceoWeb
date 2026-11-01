SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53900,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.MatriculaAcademica','U') IS NULL THROW 53900,N'Instale 016 primero.',1;
IF OBJECT_ID('dbo.LoteMensualidades','U') IS NOT NULL THROW 53900,N'Migración ya instalada.',1;
CREATE TABLE dbo.LoteMensualidades(Operacion uniqueidentifier PRIMARY KEY,SolicitudHash binary(32) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),Cantidad int NOT NULL CHECK(Cantidad BETWEEN 1 AND 12),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
