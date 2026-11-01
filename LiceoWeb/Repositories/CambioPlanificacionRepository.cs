using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;
public sealed class CambioPlanificacionRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuarioId,string tipo,int origenId,string? registro)
 {
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Planificacion_CambioConsultar",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@Tipo",SqlDbType.NVarChar,20).Value=tipo;
  cmd.Parameters.Add("@OrigenId",SqlDbType.Int).Value=origenId;
  cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=(object?)registro??DBNull.Value;
  return await LeerAsync(cmd,["Origen","Destinos"]);
 }
 public async Task GuardarAsync(string usuarioId,CambioPlanificacionInput input)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Planificacion_Cambiar",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@Tipo",SqlDbType.NVarChar,20).Value=input.Tipo;
  cmd.Parameters.Add("@OrigenId",SqlDbType.Int).Value=input.OrigenId;
  cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=(object?)input.Registro??DBNull.Value;
  cmd.Parameters.Add("@DocenteId",SqlDbType.NVarChar,450).Value=(object?)input.DocenteId??DBNull.Value;
  cmd.Parameters.Add("@GrupoDestino",SqlDbType.Int).Value=(object?)input.GrupoDestino??DBNull.Value;
  cmd.Parameters.Add("@Version",SqlDbType.VarChar,18).Value=input.Version;
  cmd.Parameters.Add("@Operacion",SqlDbType.UniqueIdentifier).Value=input.Operacion;
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo.Trim();
  await cmd.ExecuteNonQueryAsync();
 }
 public async Task<DataSet> HistorialAsync(string usuarioId,int pagina)
 {
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Planificacion_CambiosHistorial",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@Pagina",SqlDbType.Int).Value=pagina;
  return await LeerAsync(cmd,["Resumen","Historial"]);
 }
 private static async Task<DataSet> LeerAsync(SqlCommand cmd,string[] nombres)
 {
  await using var reader=await cmd.ExecuteReaderAsync();var datos=new DataSet();
  foreach(var name in nombres){var t=new DataTable(name);t.Load(reader);datos.Tables.Add(t);}return datos;
 }
}
