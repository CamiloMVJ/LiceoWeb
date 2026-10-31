-- Solo lectura. Ejecutar después de pruebas de cobro en una copia de desarrollo.
IF DB_NAME()<>'LiceoWeb_Dev' THROW 53500,N'Use desarrollo.',1;
IF COL_LENGTH('dbo.ReciboMultiple','SolicitudHash') IS NULL THROW 53500,N'Instale 013.',1;
GO
IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple R OUTER APPLY(SELECT SUM(A.Importe) Aplicado FROM dbo.AplicacionPago A WHERE A.ReciboId=R.Id) D
 WHERE R.TotalAplicado<>ISNULL(D.Aplicado,0) OR R.Recibido+R.SaldoAplicado<>R.TotalAplicado+R.Cambio OR R.SaldoAnterior-R.SaldoAplicado<>R.SaldoFinal)
 THROW 53500,N'Balance de recibo inconsistente.',1;
IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante C CROSS APPLY(SELECT SUM(A.Importe) Pagado FROM dbo.AplicacionPago A WHERE A.CargoId=C.Id) P WHERE P.Pagado>C.Importe)
 THROW 53500,N'Cargo sobrepagado.',1;
IF EXISTS(SELECT 1 FROM dbo.AplicacionPago A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId JOIN dbo.CargoEstudiante C ON C.Id=A.CargoId WHERE C.Registro<>R.Registro)
 THROW 53500,N'Aplicación a otro estudiante.',1;
IF EXISTS(SELECT 1 FROM dbo.SaldoFinanciero S OUTER APPLY(SELECT SUM(R.SaldoAplicado) Utilizado FROM dbo.ReciboMultiple R WHERE R.Registro=S.Registro) R WHERE S.Disponible<>S.SaldoInicial-ISNULL(R.Utilizado,0))
 THROW 53500,N'Saldo disponible no corresponde al movimiento de recibos.',1;
IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple R JOIN dbo.Pagos P ON P.Id_Comprobante=R.Numero)
 THROW 53500,N'Numeración duplicada entre libros.',1;
IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple R WHERE NOT EXISTS(SELECT 1 FROM dbo.Auditoria A WHERE A.IdOperacion=R.Operacion AND A.Entidad='ReciboMultiple' AND A.Accion='CobroMultiple'))
 THROW 53500,N'Recibo sin auditoría.',1;
SELECT 'INTEGRIDAD_OK' Resultado,(SELECT COUNT(*) FROM dbo.ReciboMultiple) Recibos;
