using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;
public sealed class HorarioRepository(SqlConnectionFactory factory)
{
 public async Task<DataRow?> ConsultarAsync(string usuarioId,int id)
 {
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Horario_Consultar",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@HorarioId",SqlDbType.Int).Value=id;
  await using var reader=await cmd.ExecuteReaderAsync();var table=new DataTable();table.Load(reader);
  return table.Rows.Count==0?null:table.Rows[0];
 }
 public async Task CancelarAsync(string usuarioId,CancelarHorarioInput input)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Horario_Cancelar",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@HorarioId",SqlDbType.Int).Value=input.HorarioId;
  cmd.Parameters.Add("@Version",SqlDbType.VarChar,18).Value=input.Version;
  cmd.Parameters.Add("@Operacion",SqlDbType.UniqueIdentifier).Value=input.Operacion;
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo.Trim();
  await cmd.ExecuteNonQueryAsync();
 }
 public async Task<DataSet> HistorialAsync(string usuarioId,int pagina)
 {
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Horario_Historial",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@Pagina",SqlDbType.Int).Value=pagina;
  await using var reader=await cmd.ExecuteReaderAsync();var datos=new DataSet();
  foreach(var name in new[]{"Resumen","Historial"}){var table=new DataTable(name);table.Load(reader);datos.Tables.Add(table);}
  return datos;
 }
}
