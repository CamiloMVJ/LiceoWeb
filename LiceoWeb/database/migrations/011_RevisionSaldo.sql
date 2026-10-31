SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53200,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.HistorialCaptura','U') IS NULL THROW 53200,N'Instale 010 primero.',1;
IF OBJECT_ID('dbo.RevisionSaldo','U') IS NOT NULL THROW 53200,N'Migración ya instalada.',1;
CREATE TABLE dbo.RevisionSaldo(
 Id bigint IDENTITY PRIMARY KEY,Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 SaldoObservado decimal(18,2) NOT NULL,FilasSaldo int NOT NULL,
 Huella binary(32) NOT NULL,Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1),
 Decision nvarchar(20) NOT NULL CHECK(Decision IN ('Aprobado','Rechazado')),
 Referencia nvarchar(200) NOT NULL,Motivo nvarchar(500) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE INDEX IX_RevisionSaldo_Registro ON dbo.RevisionSaldo(Registro,Id DESC);
