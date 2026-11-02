using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;

public sealed class PersonalRepository(SqlConnectionFactory factory)
{
    public async Task<DataSet> ConsultarAsync(string actor, string? cuenta = null, int pagina = 1, string busqueda = "")
    {
        await using var connection = factory.Create(); await connection.OpenAsync();
        await using var command = new SqlCommand("dbo.Personal_Consultar", connection) { CommandType = CommandType.StoredProcedure };
        command.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = actor;
        command.Parameters.Add("@CuentaId", SqlDbType.NVarChar, 450).Value = (object?)cuenta ?? DBNull.Value;
        command.Parameters.Add("@Pagina", SqlDbType.Int).Value = pagina;
        command.Parameters.Add("@Busqueda", SqlDbType.NVarChar, 100).Value = busqueda;
        await using var reader = await command.ExecuteReaderAsync(); var data = new DataSet();
        foreach (var name in new[] { "Resumen", "Cuentas", "Cuenta", "Historial" })
        { var table = new DataTable(name); table.Load(reader); data.Tables.Add(table); }
        return data;
    }

    public async Task GuardarAsync(string actor, PersonalInput input)
    {
        Validator.ValidateObject(input, new ValidationContext(input), true);
        await using var connection = factory.Create(); await connection.OpenAsync();
        await using var command = new SqlCommand("dbo.Personal_Guardar", connection) { CommandType = CommandType.StoredProcedure };
        command.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = actor;
        command.Parameters.Add("@CuentaId", SqlDbType.NVarChar, 450).Value = input.CuentaId;
        command.Parameters.Add("@Version", SqlDbType.NVarChar, 128).Value = input.Version;
        command.Parameters.Add("@Rol", SqlDbType.NVarChar, 30).Value = input.Rol;
        command.Parameters.Add("@Activa", SqlDbType.Bit).Value = input.Activa;
        command.Parameters.Add("@Motivo", SqlDbType.NVarChar, 500).Value = input.Motivo.Trim();
        command.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = input.Operacion;
        await command.ExecuteNonQueryAsync();
    }
}
