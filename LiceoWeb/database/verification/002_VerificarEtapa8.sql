SET NOCOUNT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 51300, N'Seleccione LiceoWeb_Dev.', 1;

SELECT name, current_value, is_cycling FROM sys.sequences
WHERE name = N'Secuencia_Comprobantes';
SELECT name AS Tabla FROM sys.tables
WHERE name IN (N'Historial_Comprobantes', N'Auditoria');
SELECT name AS Procedimiento FROM sys.procedures
WHERE name IN (N'Registrar_Auditoria', N'Registrar_Comprobante', N'Obtener_ComprobanteHistorico');

-- Cero filas significa que los movimientos nuevos cumplen el balance.
SELECT Id_Comprobante AS ComprobanteDescuadrado
FROM dbo.Historial_Comprobantes
WHERE SaldoAnterior + DineroRecibido <> DeudaCancelada + CambioDevuelto + SaldoFinal;

-- Pueden existir pagos anteriores sin captura historica; NO se rellenan ficticiamente.
SELECT P.Id_Comprobante AS PagoAnteriorSinHistorial
FROM dbo.Pagos P LEFT JOIN dbo.Historial_Comprobantes H
ON H.Id_Comprobante = P.Id_Comprobante
WHERE H.Id_Comprobante IS NULL;
