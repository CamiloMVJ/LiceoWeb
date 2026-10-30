SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52100,N'Base incorrecta.',1;
IF OBJECT_ID('dbo.ExpedienteAmpliado') IS NULL THROW 52101,N'Instale 004 primero.',1;
BEGIN TRANSACTION;
-- Contactos internacionales no caben en los nueve caracteres originales.
ALTER TABLE dbo.Estudiantes ALTER COLUMN Telefono nvarchar(30) NOT NULL;
ALTER TABLE dbo.Estudiantes ALTER COLUMN NombreTutor nvarchar(200) NOT NULL;
IF COL_LENGTH('dbo.ExpedienteAmpliado','FormularioJson') IS NULL
 ALTER TABLE dbo.ExpedienteAmpliado ADD FormularioJson nvarchar(max) NULL;
-- El JSON contiene datos sensibles y no se expone al listado financiero.
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Expediente_FormularioJson')
 ALTER TABLE dbo.ExpedienteAmpliado ADD CONSTRAINT CK_Expediente_FormularioJson CHECK(FormularioJson IS NULL OR ISJSON(FormularioJson)=1);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UQ_Responsable_Vigente' AND object_id=OBJECT_ID('dbo.ResponsableEstudiante'))
 CREATE UNIQUE INDEX UQ_Responsable_Vigente ON dbo.ResponsableEstudiante(Registro,Vinculo) WHERE Hasta IS NULL;
COMMIT;
