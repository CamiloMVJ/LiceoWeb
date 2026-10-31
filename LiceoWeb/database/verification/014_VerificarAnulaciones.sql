-- Solo lectura, después de instalar 015 y probar anulaciones en desarrollo.
IF DB_NAME()<>'LiceoWeb_Dev' THROW 53700,N'Use desarrollo.',1;
IF OBJECT_ID('dbo.AnulacionRecibo','U') IS NULL THROW 53700,N'Instale 015.',1;
GO
IF EXISTS(SELECT 1 FROM dbo.AnulacionRecibo X JOIN dbo.ReciboMultiple R ON R.Id=X.ReciboId WHERE X.DineroDevuelto<>R.Recibido-R.Cambio OR X.SaldoRestituido<>R.SaldoAplicado OR X.TotalRevertido<>R.TotalAplicado OR X.SaldoFinal-X.SaldoAnterior<>X.SaldoRestituido) THROW 53700,N'Contrapartida inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.AnulacionRecibo X WHERE NOT EXISTS(SELECT 1 FROM dbo.Auditoria A WHERE A.IdOperacion=X.Operacion AND A.Accion='AnularRecibo' AND A.Entidad='ReciboMultiple')) THROW 53700,N'Anulación sin auditoría.',1;
IF EXISTS(SELECT 1 FROM dbo.AplicacionPagoVigente A JOIN dbo.AnulacionRecibo X ON X.ReciboId=A.ReciboId) THROW 53700,N'Aplicación anulada aún vigente.',1;
IF EXISTS(SELECT 1 FROM dbo.SaldoFinanciero S OUTER APPLY(SELECT SUM(R.SaldoAplicado) Usado FROM dbo.ReciboMultiple R WHERE R.Registro=S.Registro) P OUTER APPLY(SELECT SUM(X.SaldoRestituido) Restituido FROM dbo.AnulacionRecibo X JOIN dbo.ReciboMultiple R ON R.Id=X.ReciboId WHERE R.Registro=S.Registro) D WHERE S.Disponible<>S.SaldoInicial-ISNULL(P.Usado,0)+ISNULL(D.Restituido,0)) THROW 53700,N'Saldo disponible inconsistente.',1;
SELECT 'INTEGRIDAD_OK' Resultado,COUNT(*) Anulaciones FROM dbo.AnulacionRecibo;
