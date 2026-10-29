CREATE OR ALTER PROCEDURE dbo.Obtener_ComprobanteHistorico
    @IdComprobante nvarchar(25)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT P.Id_Comprobante AS IdComprobante, P.Registro_Estudiante AS Registro,
        P.Fecha_Pago AS FechaPago, P.Concepto, P.Metodo_Pago AS MetodoPago,
        P.Referencia_Transaccion AS Referencia, P.Descripcion,
        H.NombreEstudiante, H.Modalidad, H.Grado, H.UsuarioNombre AS RecibidoPor,
        H.DineroRecibido, H.SaldoAnterior, H.SaldoUtilizado,
        H.DeudaCancelada, H.CambioDevuelto, H.SaldoFinal,
        CASE WHEN H.Id_Comprobante IS NULL THEN NULL
            ELSE H.DineroRecibido - H.CambioDevuelto END AS IngresoNeto,
        CONVERT(bit, CASE WHEN H.Id_Comprobante IS NULL THEN 0 ELSE 1 END)
            AS DatosHistoricosDisponibles,
        P.Monto AS MontoRegistradoOriginal
    FROM dbo.Pagos P
    LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante = P.Id_Comprobante
    WHERE P.Id_Comprobante = @IdComprobante;
END;
