namespace LiceoWeb.Models
{
    public sealed record ResultadoCobro(
    string IdComprobante,
    decimal DineroRecibido,
    decimal SaldoUtilizado,
    decimal DeudaCancelada,
    decimal CambioDevuelto,
    decimal SaldoFinal);
}
