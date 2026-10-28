using Microsoft.Data.SqlClient;

namespace LiceoWeb.Data;

public sealed class SqlConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        var connectionString =
            configuration.GetConnectionString("DefaultConnection");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Falta configurar la conexión DefaultConnection.");
        }

        _connectionString = connectionString;
    }

    public SqlConnection Create()
    {
        return new SqlConnection(_connectionString);
    }
}