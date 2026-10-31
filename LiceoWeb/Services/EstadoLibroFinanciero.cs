using LiceoWeb.Data;
namespace LiceoWeb.Services;
public enum EstadoLibro { Anterior, Nuevo, NoDisponible }
public interface IEstadoLibroFinanciero
{
    Task<EstadoLibro> ObtenerAsync();
}
// Scoped: una consulta por petición, sin caché entre usuarios/peticiones tras el corte.
public sealed class EstadoLibroFinanciero(SqlConnectionFactory factory, ILogger<EstadoLibroFinanciero> logger) : IEstadoLibroFinanciero
{
    private Task<EstadoLibro>? consulta;
    public Task<EstadoLibro> ObtenerAsync() => consulta ??= ConsultarAsync();
    private async Task<EstadoLibro> ConsultarAsync()
    {
        try
        {
            using var limite = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            await using var c = factory.Create(); await c.OpenAsync(limite.Token);
            await using var cmd = c.CreateCommand(); cmd.CommandTimeout = 5;
            // SQL dinámico permite instalaciones anteriores a 012 sin compilar una tabla inexistente.
            cmd.CommandText = "IF OBJECT_ID('dbo.ControlFinanciero','U') IS NULL SELECT CAST(0 AS bit); ELSE EXEC sys.sp_executesql N'SELECT Migrado FROM dbo.ControlFinanciero WITH(READCOMMITTEDLOCK) WHERE Id=1';";
            var resultado = await cmd.ExecuteScalarAsync(limite.Token);
            return resultado is bool migrado ? (migrado ? EstadoLibro.Nuevo : EstadoLibro.Anterior) : EstadoLibro.NoDisponible;
        }
        catch (Exception ex)
        {
            logger.LogWarning("No se pudo consultar el estado financiero: {Tipo}", ex.GetType().Name);
            return EstadoLibro.NoDisponible;
        }
    }
}
