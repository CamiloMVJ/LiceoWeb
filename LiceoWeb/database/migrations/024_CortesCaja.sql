SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54800,N'Cierra las transacciones antes de instalar 024.',1;
IF COL_LENGTH('dbo.ReciboMultiple','Anticipo') IS NULL THROW 54800,N'Instala 023 antes de los cortes de caja.',1;
IF OBJECT_ID('dbo.CorteCaja','U') IS NOT NULL THROW 54800,N'024 ya está instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.CorteCaja(
  Id bigint IDENTITY PRIMARY KEY,Inicio datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Fin datetime2 NULL,
  UsuarioApertura nvarchar(450) NULL REFERENCES dbo.AspNetUsers(Id),UsuarioCierre nvarchar(450) NULL REFERENCES dbo.AspNetUsers(Id),
  FondoApertura decimal(18,2) NOT NULL CHECK(FondoApertura>=0),
  EfectivoEsperado decimal(18,2) NULL,EfectivoContado decimal(18,2) NULL CHECK(EfectivoContado>=0),
  Diferencia decimal(18,2) NULL,Motivo nvarchar(500) NULL,ResumenJson nvarchar(max) NULL,
  Version rowversion,
  CONSTRAINT CK_CorteCaja_Cierre CHECK(
   (Fin IS NULL AND UsuarioCierre IS NULL AND EfectivoContado IS NULL AND ResumenJson IS NULL) OR
   (Fin IS NOT NULL AND Fin>=Inicio AND UsuarioCierre IS NOT NULL AND EfectivoEsperado IS NOT NULL
    AND EfectivoContado IS NOT NULL AND Diferencia=EfectivoContado-EfectivoEsperado AND ISJSON(ResumenJson)=1)));
 CREATE UNIQUE INDEX UX_CorteCaja_Abierto ON dbo.CorteCaja(Fin) WHERE Fin IS NULL;
 ALTER TABLE dbo.ReciboMultiple ADD CorteCajaId bigint NULL REFERENCES dbo.CorteCaja(Id);
 ALTER TABLE dbo.AnulacionRecibo ADD CorteCajaId bigint NULL REFERENCES dbo.CorteCaja(Id);
 CREATE TABLE dbo.EventoCorteCaja(
  Operacion uniqueidentifier PRIMARY KEY,SolicitudHash binary(32) NOT NULL,
  CorteId bigint NOT NULL REFERENCES dbo.CorteCaja(Id),SiguienteId bigint NULL REFERENCES dbo.CorteCaja(Id),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 -- Al actualizar una instalación activa, el primer corte recoge los movimientos sin corte.
 EXEC sys.sp_executesql N'
 IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 BEGIN
  DECLARE @Inicio datetime2=(SELECT MIN(Fecha) FROM(
   SELECT Fecha FROM dbo.ReciboMultiple UNION ALL SELECT Fecha FROM dbo.AnulacionRecibo
   UNION ALL SELECT SYSUTCDATETIME()) F);
  INSERT dbo.CorteCaja(Inicio,UsuarioApertura,FondoApertura)
   SELECT @Inicio,UsuarioId,0 FROM dbo.ControlFinanciero WHERE Id=1;
  DECLARE @Id bigint=SCOPE_IDENTITY();
  UPDATE dbo.ReciboMultiple SET CorteCajaId=@Id;
  UPDATE dbo.AnulacionRecibo SET CorteCajaId=@Id;
 END;';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
