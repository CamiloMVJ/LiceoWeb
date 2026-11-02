using LiceoWeb.Data;
using Microsoft.Data.SqlClient;
using System.Data;
namespace LiceoWeb.Services;

public interface IEstadoCuentaPersonal
{
    Task<bool> EstaActivaAsync(string usuarioId);
}

public sealed class EstadoCuentaPersonal(SqlConnectionFactory factory) : IEstadoCuentaPersonal
{
    public async Task<bool> EstaActivaAsync(string usuarioId)
    {
        await using var connection = factory.Create();
        await connection.OpenAsync();
        await using var command = new SqlCommand("SELECT CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.AspNetUsers U LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@Id AND ISNULL(E.Activa,1)=1) THEN 1 ELSE 0 END AS bit)", connection);
        command.Parameters.Add("@Id", SqlDbType.NVarChar, 450).Value = usuarioId;
        return (bool)(await command.ExecuteScalarAsync())!;
    }
}
