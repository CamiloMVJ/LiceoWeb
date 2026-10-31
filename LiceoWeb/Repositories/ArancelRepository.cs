using System.Data;
using System.Text.Json;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Repositories;
public sealed class ArancelRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuario)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="dbo.Aranceles_Consultar";
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  await using var reader=await cmd.ExecuteReaderAsync();var result=new DataSet();
  foreach(var name in new[]{"Aranceles","Tarifas","Anios","Modalidades","Mapeos","Historial","Preparacion","Resumen"}){var t=new DataTable(name);t.Load(reader);result.Tables.Add(t);}return result;
 }
 public async Task GuardarAsync(ArancelInput input,string usuario)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="dbo.Aranceles_Guardar";
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@Datos",SqlDbType.NVarChar,-1).Value=JsonSerializer.Serialize(input);await cmd.ExecuteNonQueryAsync();
 }
}
