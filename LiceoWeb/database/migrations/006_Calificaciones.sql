-- Ejecutar una vez después de 004 y 005, en desarrollo.
SET XACT_ABORT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52400,N'Base incorrecta.',1;
IF OBJECT_ID('dbo.Evaluacion') IS NULL THROW 52400,N'Instale la migración 004 primero.',1;
IF COL_LENGTH('dbo.Evaluacion','Modo') IS NOT NULL THROW 52400,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Evaluacion ADD Modo nvarchar(20) NOT NULL CONSTRAINT DF_Evaluacion_Modo DEFAULT N'Cuantitativa';
 -- La restricción de Peso fue creada sin nombre en 004; localizarla por columna.
 DECLARE @Nombre sysname,@Sql nvarchar(max);
 SELECT @Nombre=name FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('dbo.Evaluacion') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.Evaluacion'),'Peso','ColumnId');
 IF @Nombre IS NULL THROW 52400,N'No se encontró la restricción original de Peso; revisar el esquema.',1;
 SET @Sql=N'ALTER TABLE dbo.Evaluacion DROP CONSTRAINT '+QUOTENAME(@Nombre);EXEC sp_executesql @Sql;
 EXEC(N'ALTER TABLE dbo.Evaluacion ADD CONSTRAINT CK_Evaluacion_ModoPeso CHECK ((Modo=N''Cuantitativa'' AND Peso>0 AND Peso<=100) OR (Modo=N''Cualitativa'' AND Peso=0));');
 ALTER TABLE dbo.Calificacion ADD Resultado nvarchar(100) NULL;
 EXEC(N'ALTER TABLE dbo.Calificacion ADD CONSTRAINT CK_Calificacion_UnResultado CHECK (Nota IS NULL OR Resultado IS NULL);');
 CREATE TABLE dbo.OpcionEvaluacion(EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),Valor nvarchar(100) NOT NULL,PRIMARY KEY(EvaluacionId,Valor));
 CREATE TABLE dbo.PublicacionNotas(AsignacionId int PRIMARY KEY REFERENCES dbo.AsignacionDocente(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id));
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
