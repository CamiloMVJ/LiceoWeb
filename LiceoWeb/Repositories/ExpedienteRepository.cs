using System.Data;
using System.Text.Json;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;

namespace LiceoWeb.Repositories;

public sealed class ExpedienteRepository(SqlConnectionFactory factory)
{
    public async Task<IReadOnlyList<EstudianteListadoViewModel>> ListarAsync(string? busqueda, string? modalidad, string? estado)
    {
        await using var connection = factory.Create();
        await connection.OpenAsync();
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = """
            SELECT TOP(200) Registro,NombreEstudiante,Modalidad,Grado,Estado FROM dbo.Estudiantes
            WHERE (@Busqueda='' OR CHARINDEX(@Busqueda,NombreEstudiante)>0 OR CHARINDEX(@Busqueda,Registro)>0)
            AND (@Modalidad='' OR Modalidad=@Modalidad) AND (@Estado='' OR Estado=@Estado)
            ORDER BY NombreEstudiante,Registro
            """;
        cmd.Parameters.Add("@Busqueda",SqlDbType.NVarChar,100).Value=busqueda?.Trim() ?? "";
        cmd.Parameters.Add("@Modalidad",SqlDbType.NVarChar,20).Value=modalidad ?? "";
        cmd.Parameters.Add("@Estado",SqlDbType.NVarChar,10).Value=estado ?? "";
        var result = new List<EstudianteListadoViewModel>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while(await reader.ReadAsync()) result.Add(new() { Registro=reader.GetString(0),NombreEstudiante=reader.GetString(1),Modalidad=reader.GetString(2),Grado=reader.GetString(3),Activo=reader.GetString(4)=="Activo" });
        return result;
    }
    public async Task<ExpedienteInput?> ObtenerAsync(string registro)
    {
        await using var connection = factory.Create();
        await connection.OpenAsync();
        await using var cmd = connection.CreateCommand();
        cmd.CommandText="dbo.Expediente_Obtener";
        cmd.CommandType=CommandType.StoredProcedure;
        cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=registro;
        var json = await cmd.ExecuteScalarAsync() as string;
        return string.IsNullOrWhiteSpace(json) ? null : JsonSerializer.Deserialize<ExpedienteInput>(json);
    }
    public async Task<string> GuardarAsync(ExpedienteInput input, string usuarioId)
    {
        await using var connection = factory.Create();
        await connection.OpenAsync();
        await using var cmd = connection.CreateCommand();
        cmd.CommandText="dbo.Expediente_Guardar";
        cmd.CommandType=CommandType.StoredProcedure;
        cmd.Parameters.Add("@Datos",SqlDbType.NVarChar,-1).Value=JsonSerializer.Serialize(input);
        cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
        return (string)(await cmd.ExecuteScalarAsync() ?? throw new InvalidOperationException("Sin registro devuelto."));
    }
    public async Task<DataTable> TutelasAsync(string registro)
    {
        await using var connection=factory.Create(); await connection.OpenAsync();
        await using var cmd=connection.CreateCommand();
        cmd.CommandText="SELECT T.NombreHistorico, R.Vinculo, T.Desde, T.Hasta, T.Motivo FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro ORDER BY T.Id DESC";
        cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=registro;
        await using var reader=await cmd.ExecuteReaderAsync(); var table=new DataTable(); table.Load(reader); return table;
    }
}
