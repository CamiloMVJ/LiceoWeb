SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54500,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.HistorialEvaluacion','U') IS NULL THROW 54500,N'Instale 020 primero.',1;
IF OBJECT_ID('dbo.EstadoCuentaPersonal','U') IS NOT NULL OR OBJECT_ID('dbo.HistorialCuentaPersonal','U') IS NOT NULL THROW 54500,N'Etapa 021 instalada o parcial. Revise antes de repetir.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.EstadoCuentaPersonal(
  UsuarioId nvarchar(450) NOT NULL PRIMARY KEY REFERENCES dbo.AspNetUsers(Id),
  Activa bit NOT NULL);
 CREATE TABLE dbo.HistorialCuentaPersonal(
  Id bigint IDENTITY PRIMARY KEY, CuentaId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Operacion uniqueidentifier NOT NULL UNIQUE, SolicitudHash binary(32) NOT NULL,
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
  AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),
  DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1));
 CREATE INDEX IX_HistorialCuentaPersonal_Cuenta ON dbo.HistorialCuentaPersonal(CuentaId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
