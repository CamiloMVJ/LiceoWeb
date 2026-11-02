using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Text.Json;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;
public sealed class EvaluacionRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuarioId,int id,int pagina)
 {
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Evaluacion_ConsultarEdicion",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@EvaluacionId",SqlDbType.Int).Value=id;
  cmd.Parameters.Add("@Pagina",SqlDbType.Int).Value=pagina;
  await using var reader=await cmd.ExecuteReaderAsync();var datos=new DataSet();
  foreach(var name in new[]{"Evaluacion","Tipos","Opciones","Resumen","Historial"}){var t=new DataTable(name);t.Load(reader);datos.Tables.Add(t);}return datos;
 }
 public async Task GuardarAsync(string usuarioId,EditarEvaluacionInput input)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();
  await using var cmd=new SqlCommand("dbo.Evaluacion_Editar",c){CommandType=CommandType.StoredProcedure};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@EvaluacionId",SqlDbType.Int).Value=input.Id;
  cmd.Parameters.Add("@Version",SqlDbType.VarChar,18).Value=input.Version;
  cmd.Parameters.Add("@Operacion",SqlDbType.UniqueIdentifier).Value=input.Operacion;
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo.Trim();
  cmd.Parameters.Add("@Datos",SqlDbType.NVarChar,-1).Value=JsonSerializer.Serialize(new{input.TipoId,input.Nombre,input.Fecha,input.Modo,input.Maximo,input.Peso,Valores=input.Valores()});
  await cmd.ExecuteNonQueryAsync();
 }
}
