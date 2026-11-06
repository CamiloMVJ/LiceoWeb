SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54700,N'Cierra las transacciones antes de instalar 023.',1;
IF OBJECT_ID('dbo.AnulacionRecibo','U') IS NULL OR COL_LENGTH('dbo.ReciboMultiple','TotalAplicado') IS NULL
 THROW 54700,N'Instala primero las etapas de recibos y anulaciones.',1;
IF COL_LENGTH('dbo.ReciboMultiple','Anticipo') IS NOT NULL
 THROW 54700,N'La migración 023 ya está instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Uq sysname=(SELECT kc.name FROM sys.key_constraints kc
  JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
  WHERE kc.parent_object_id=OBJECT_ID('dbo.SaldoFinanciero') AND kc.type='UQ' AND c.name='RevisionSaldoId');
 IF @Uq IS NULL THROW 54700,N'No se encontró la restricción de revisión de saldo.',1;
 DECLARE @Sql nvarchar(max)=N'ALTER TABLE dbo.SaldoFinanciero DROP CONSTRAINT '+QUOTENAME(@Uq);
 EXEC sys.sp_executesql @Sql;
 ALTER TABLE dbo.SaldoFinanciero ALTER COLUMN RevisionSaldoId bigint NULL;
 CREATE UNIQUE INDEX UX_SaldoFinanciero_RevisionSaldo ON dbo.SaldoFinanciero(RevisionSaldoId) WHERE RevisionSaldoId IS NOT NULL;

 ALTER TABLE dbo.ReciboMultiple ADD Anticipo decimal(18,2) NOT NULL CONSTRAINT DF_ReciboMultiple_Anticipo DEFAULT 0 WITH VALUES;
 ALTER TABLE dbo.ReciboMultiple DROP CONSTRAINT CK_ReciboMultiple_Balance;
 EXEC sys.sp_executesql N'ALTER TABLE dbo.ReciboMultiple ADD CONSTRAINT CK_ReciboMultiple_Balance CHECK (
 Metodo IN (N''Efectivo'',N''Transferencia'',N''Saldo'') AND Recibido>=0 AND Cambio>=0 AND Cambio<=Recibido AND
 SaldoAnterior>=0 AND SaldoAplicado>=0 AND SaldoAplicado<=SaldoAnterior AND SaldoFinal=SaldoAnterior-SaldoAplicado+Anticipo AND
 Anticipo>=0 AND ((Anticipo=0 AND TotalAplicado>0) OR
 (Anticipo>0 AND TotalAplicado=0 AND Cambio=0 AND SaldoAplicado=0 AND Metodo<>N''Saldo'')) AND
 Recibido+SaldoAplicado=TotalAplicado+Cambio+Anticipo AND
 (Metodo<>N''Transferencia'' OR (NULLIF(LTRIM(RTRIM(Referencia)),N'''') IS NOT NULL AND Cambio=0 AND Recibido>0)) AND
 (Metodo<>N''Saldo'' OR (Recibido=0 AND Cambio=0)) AND (Metodo<>N''Efectivo'' OR Recibido>0));';

 ALTER TABLE dbo.AnulacionRecibo ADD SaldoRetirado decimal(18,2) NOT NULL CONSTRAINT DF_AnulacionRecibo_SaldoRetirado DEFAULT 0 WITH VALUES;
 ALTER TABLE dbo.AnulacionRecibo DROP CONSTRAINT CK_AnulacionRecibo_Saldo;
 EXEC sys.sp_executesql N'ALTER TABLE dbo.AnulacionRecibo ADD CONSTRAINT CK_AnulacionRecibo_Saldo CHECK (
 SaldoRetirado>=0 AND SaldoRetirado<=SaldoAnterior AND SaldoFinal=SaldoAnterior+SaldoRestituido-SaldoRetirado);';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
