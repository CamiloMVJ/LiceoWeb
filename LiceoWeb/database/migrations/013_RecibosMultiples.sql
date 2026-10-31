SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53500,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.SaldoFinanciero','U') IS NULL THROW 53500,N'Instale 012 primero.',1;
IF COL_LENGTH('dbo.ReciboMultiple','SolicitudHash') IS NOT NULL THROW 53500,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 -- No reinterpretar recibos existentes con reglas nuevas.
 IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple WITH(TABLOCKX,HOLDLOCK)) THROW 53500,N'Existen recibos: requiere conciliación antes de instalar.',1;
 DECLARE @Sql nvarchar(max)=N'';
 SELECT @Sql+=N'ALTER TABLE dbo.ReciboMultiple DROP CONSTRAINT '+QUOTENAME(name)+N';' FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('dbo.ReciboMultiple');
 EXEC sys.sp_executesql @Sql;
 ALTER TABLE dbo.ReciboMultiple ADD SolicitudHash binary(32) NOT NULL,NombreEstudiante nvarchar(100) NOT NULL,SaldoAnterior decimal(18,2) NOT NULL,SaldoAplicado decimal(18,2) NOT NULL,SaldoFinal decimal(18,2) NOT NULL,TotalAplicado decimal(18,2) NOT NULL;
 -- SQL dinámico evita compilación anticipada de las columnas agregadas.
 EXEC sys.sp_executesql N'ALTER TABLE dbo.ReciboMultiple ADD CONSTRAINT CK_ReciboMultiple_Balance CHECK (
 Metodo IN (N''Efectivo'',N''Transferencia'',N''Saldo'') AND Recibido>=0 AND Cambio>=0 AND Cambio<=Recibido AND
 SaldoAnterior>=0 AND SaldoAplicado>=0 AND SaldoAplicado<=SaldoAnterior AND SaldoFinal=SaldoAnterior-SaldoAplicado AND
 TotalAplicado>0 AND Recibido+SaldoAplicado=TotalAplicado+Cambio AND
 (Metodo<>N''Transferencia'' OR (NULLIF(LTRIM(RTRIM(Referencia)),N'''') IS NOT NULL AND Cambio=0 AND Recibido>0)) AND
 (Metodo<>N''Saldo'' OR (Recibido=0 AND Cambio=0)) AND (Metodo<>N''Efectivo'' OR Recibido>0));';
 CREATE INDEX IX_AplicacionPago_Cargo ON dbo.AplicacionPago(CargoId) INCLUDE(Importe);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
