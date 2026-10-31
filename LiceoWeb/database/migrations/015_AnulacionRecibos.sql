SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53700,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.GeneracionCargo','U') IS NULL THROW 53700,N'Instale 014 primero.',1;
IF OBJECT_ID('dbo.AnulacionRecibo','U') IS NOT NULL THROW 53700,N'Migración ya instalada.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.AnulacionRecibo(
 Id bigint IDENTITY PRIMARY KEY,ReciboId bigint NOT NULL UNIQUE REFERENCES dbo.ReciboMultiple(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL,ReferenciaDevolucion nvarchar(100) NOT NULL,Receptor nvarchar(200) NOT NULL,
 DineroDevuelto decimal(18,2) NOT NULL CHECK(DineroDevuelto>=0),SaldoRestituido decimal(18,2) NOT NULL CHECK(SaldoRestituido>=0),
 SaldoAnterior decimal(18,2) NOT NULL CHECK(SaldoAnterior>=0),SaldoFinal decimal(18,2) NOT NULL,
 TotalRevertido decimal(18,2) NOT NULL CHECK(TotalRevertido>0),CONSTRAINT CK_AnulacionRecibo_Total CHECK(TotalRevertido=DineroDevuelto+SaldoRestituido),
 CONSTRAINT CK_AnulacionRecibo_Saldo CHECK(SaldoFinal=SaldoAnterior+SaldoRestituido));
 -- Crear la vista en la misma transacción, una vez creada la tabla.
 EXEC sys.sp_executesql N'CREATE OR ALTER VIEW dbo.AplicacionPagoVigente
 AS SELECT A.ReciboId,A.CargoId,A.Importe,A.DescripcionHistorica FROM dbo.AplicacionPago A
 WHERE NOT EXISTS(SELECT 1 FROM dbo.AnulacionRecibo R WHERE R.ReciboId=A.ReciboId);';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
