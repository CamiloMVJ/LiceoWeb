SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 53000,N'Base incorrecta.',1;
IF OBJECT_ID('dbo.PreparacionObligacion','U') IS NULL THROW 53000,N'Instale 008 primero.',1;
IF OBJECT_ID('dbo.RevisionObligacion','U') IS NOT NULL THROW 53000,N'Migración ya instalada.',1;
IF @@TRANCOUNT<>0 THROW 53000,N'Use una ventana sin transacciones abiertas.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.RevisionObligacion(
  Id bigint IDENTITY PRIMARY KEY,
  Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,
  TarifaId int NOT NULL REFERENCES dbo.TarifaArancel(Id),
  Decision nvarchar(20) NOT NULL CHECK(Decision IN ('Deuda','SinDeuda','Rechazada')),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo)))>0),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
  Registro nvarchar(10) NOT NULL,Anio int NOT NULL,Modalidad nvarchar(20) NOT NULL,
  Importe decimal(18,2) NOT NULL,Estado nvarchar(10) NOT NULL,Comprobante nvarchar(25) NULL,
  FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 CREATE INDEX IX_RevisionObligacion_Origen ON dbo.RevisionObligacion(Origen,OrigenId,Id DESC);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
