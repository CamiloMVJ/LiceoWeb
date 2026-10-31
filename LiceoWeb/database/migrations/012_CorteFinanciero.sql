SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53400,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.RevisionSaldo','U') IS NULL THROW 53400,N'Instale 011 primero.',1;
IF OBJECT_ID('dbo.ControlFinanciero','U') IS NOT NULL THROW 53400,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.ControlFinanciero(Id int PRIMARY KEY CHECK(Id=1),Migrado bit NOT NULL DEFAULT 0,Operacion uniqueidentifier NULL,Fecha datetime2 NULL,UsuarioId nvarchar(450) NULL REFERENCES dbo.AspNetUsers(Id));
 INSERT dbo.ControlFinanciero(Id) VALUES(1);
 -- Desconocido no se convierte en fecha de mora inventada.
 ALTER TABLE dbo.CargoEstudiante ALTER COLUMN Vencimiento date NULL;
 CREATE TABLE dbo.SaldoFinanciero(Registro nvarchar(10) PRIMARY KEY REFERENCES dbo.Estudiantes(Registro),RevisionSaldoId bigint NOT NULL UNIQUE REFERENCES dbo.RevisionSaldo(Id),SaldoInicial decimal(18,2) NOT NULL CHECK(SaldoInicial>=0),Disponible decimal(18,2) NOT NULL CHECK(Disponible>=0),Version rowversion);
 CREATE TABLE dbo.ObligacionMigrada(Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,RevisionId bigint NOT NULL UNIQUE REFERENCES dbo.RevisionObligacion(Id),CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),PRIMARY KEY(Origen,OrigenId),FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 CREATE UNIQUE INDEX UQ_ObligacionMigrada_Cargo ON dbo.ObligacionMigrada(CargoId) WHERE CargoId IS NOT NULL;
 -- Triggers de transición: permanecen inactivos hasta confirmar el corte.
 DECLARE @Tabla sysname,@Sql nvarchar(max);
 DECLARE Tablas CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM (VALUES
 ('Pagos'),('Abonos'),('Matriculas'),('Mensualidades'),('Mantenimientos'),('EvBoTaS'),('Promociones'),('Arreglos_Pago'),('Historial_Comprobantes'),
 ('Costo_Matricula'),('Costo_Mensualidad'),('Costo_Mantenimiento'),('Costo_EvBoTa'),('Costo_Promocion'),
 ('PreparacionObligacion'),('RevisionObligacion'),('RevisionSaldo'),('MapaConceptoLegado'),('HistorialCaptura')) V(T);
 OPEN Tablas;FETCH NEXT FROM Tablas INTO @Tabla;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Sql=N'CREATE TRIGGER dbo.'+QUOTENAME(N'TR_Corte_'+@Tabla)+N' ON dbo.'+QUOTENAME(@Tabla)+N' AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WITH(READCOMMITTEDLOCK) WHERE Id=1 AND Migrado=1) THROW 53410,N''El libro anterior está cerrado. No se permiten escrituras.'',1; END;';
  EXEC sys.sp_executesql @Sql;
  FETCH NEXT FROM Tablas INTO @Tabla;
 END;
 CLOSE Tablas;DEALLOCATE Tablas;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
