-- Después de 004–007. No transforma pagos ni activa el nuevo libro.
SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52800,N'Base incorrecta.',1;
IF OBJECT_ID('dbo.TarifaArancel','U') IS NULL THROW 52800,N'Falta la estructura de 004.',1;
IF OBJECT_ID('dbo.HistorialTarifa','U') IS NOT NULL THROW 52800,N'Migración ya instalada.',1;
IF @@TRANCOUNT<>0 THROW 52800,N'Use una ventana sin transacciones abiertas.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Arancel ADD Version rowversion;
 ALTER TABLE dbo.TarifaArancel ADD Activo bit NOT NULL CONSTRAINT DF_Tarifa_Activo DEFAULT 1,Version rowversion;
 CREATE TABLE dbo.HistorialTarifa(
  Id bigint IDENTITY PRIMARY KEY,TarifaId int NOT NULL REFERENCES dbo.TarifaArancel(Id),
  ImporteAnterior decimal(18,2) NULL,ImporteNuevo decimal(18,2) NOT NULL,
  ActivoAnterior bit NULL,ActivoNuevo bit NOT NULL,Motivo nvarchar(500) NOT NULL,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 CREATE TABLE dbo.MapaConceptoLegado(
  Origen nvarchar(30) PRIMARY KEY CHECK(Origen IN ('Matriculas','Mensualidades','Mantenimientos','EvBoTaS','Promociones')),
  ArancelId int NOT NULL REFERENCES dbo.Arancel(Id),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 -- Una fila por obligación original. Es preparación, no un cargo cobrable.
 CREATE TABLE dbo.PreparacionObligacion(
  Origen nvarchar(30) NOT NULL REFERENCES dbo.MapaConceptoLegado(Origen),OrigenId int NOT NULL,
  Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),Anio int NOT NULL,
  Modalidad nvarchar(20) NOT NULL,Importe decimal(18,2) NOT NULL,Estado nvarchar(10) NOT NULL,
  Comprobante nvarchar(25) NULL,ArancelId int NOT NULL REFERENCES dbo.Arancel(Id),
  Capturado datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),
  PRIMARY KEY(Origen,OrigenId));
 CREATE UNIQUE INDEX UQ_Preparacion_Cargo ON dbo.PreparacionObligacion(CargoId) WHERE CargoId IS NOT NULL;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
