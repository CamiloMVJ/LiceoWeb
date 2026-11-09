-- Solo lectura. Ejecutar después de 025 en la misma base de la aplicación.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.CorteCaja','U') IS NULL THROW 54921,N'Falta la estructura de caja.',1;
IF EXISTS(SELECT 1 FROM (VALUES
 (N'Conciliacion_Revisar'),(N'Conciliacion_Consultar'),(N'Conciliacion_Pantalla'),(N'Conciliacion_Recapturar'),
 (N'Saldo_Instantanea'),(N'Saldo_Consultar'),(N'Saldo_Revisar'),(N'CorteFinanciero_Ejecutar'),
 (N'ObligacionLegada'),(N'ObligacionMigrada'),(N'RevisionObligacion'),(N'HistorialCaptura'),
 (N'PreparacionObligacion'),(N'MapaConceptoLegado'),(N'RevisionSaldo')) V(Nombre)
 WHERE OBJECT_ID(N'dbo.'+Nombre) IS NOT NULL)
 THROW 54921,N'Quedan objetos de conciliación. Ejecuta completa la migración 025.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54921,N'El esquema financiero web no está habilitado.',1;
IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple R OUTER APPLY(SELECT SUM(Importe) Total FROM dbo.AplicacionPago WHERE ReciboId=R.Id) A
 WHERE R.TotalAplicado<>ISNULL(A.Total,0) OR R.SaldoFinal<>R.SaldoAnterior-R.SaldoAplicado+R.Anticipo
 OR R.Recibido+R.SaldoAplicado<>R.TotalAplicado+R.Cambio+R.Anticipo)
 THROW 54921,N'Hay un recibo con balance inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante C OUTER APPLY(SELECT SUM(Importe) Pagado FROM dbo.AplicacionPagoVigente WHERE CargoId=C.Id) A
 WHERE ISNULL(A.Pagado,0)>C.Importe)
 THROW 54921,N'Hay un cargo sobrepagado.',1;
IF EXISTS(SELECT 1 FROM dbo.SaldoFinanciero S
 OUTER APPLY(SELECT SUM(Anticipo) Anticipos,SUM(SaldoAplicado) Usado FROM dbo.ReciboMultiple WHERE Registro=S.Registro) R
 OUTER APPLY(SELECT SUM(X.SaldoRestituido) Restituido,SUM(X.SaldoRetirado) Retirado FROM dbo.AnulacionRecibo X
 JOIN dbo.ReciboMultiple M ON M.Id=X.ReciboId WHERE M.Registro=S.Registro) D
 WHERE S.Disponible<>S.SaldoInicial+ISNULL(R.Anticipos,0)-ISNULL(R.Usado,0)+ISNULL(D.Restituido,0)-ISNULL(D.Retirado,0))
 THROW 54921,N'Un saldo no coincide con sus movimientos.',1;
IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple R LEFT JOIN dbo.CorteCaja C ON C.Id=R.CorteCajaId WHERE C.Id IS NULL)
 THROW 54921,N'Hay recibos sin corte de caja.',1;
SELECT N'RETIRO E INTEGRIDAD OK' Resultado,
 (SELECT COUNT_BIG(*) FROM dbo.Estudiantes) Estudiantes,
 (SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante) Cargos,
 (SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple) Recibos,
 (SELECT ISNULL(SUM(Disponible),0) FROM dbo.SaldoFinanciero) SaldoFavor,
 (SELECT COUNT_BIG(*) FROM dbo.CorteCaja) Cortes;
