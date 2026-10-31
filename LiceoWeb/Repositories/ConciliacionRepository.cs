using System.Data;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Repositories;
public sealed class ConciliacionRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuario,int pagina,string? registro,string origen,int origenId)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.Conciliacion_Pantalla";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@Pagina",SqlDbType.Int).Value=pagina;
  cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=registro?.Trim()??"";
  cmd.Parameters.Add("@Origen",SqlDbType.NVarChar,30).Value=origen;
  cmd.Parameters.Add("@OrigenId",SqlDbType.Int).Value=origenId;
  await using var reader=await cmd.ExecuteReaderAsync();var ds=new DataSet();
  foreach(var name in new[]{"Obligaciones","Seleccion","Tarifas","Historial","Capturas"}){var t=new DataTable(name);t.Load(reader);ds.Tables.Add(t);}return ds;
 }
 public async Task GuardarAsync(ConciliacionInput input,string usuario)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText=input.Recapturar?"dbo.Conciliacion_Recapturar":"dbo.Conciliacion_Revisar";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@Origen",SqlDbType.NVarChar,30).Value=input.Origen;
  cmd.Parameters.Add("@OrigenId",SqlDbType.Int).Value=input.OrigenId;
  if(!input.Recapturar){
  cmd.Parameters.Add("@TarifaId",SqlDbType.Int).Value=input.TarifaId;
  cmd.Parameters.Add("@Decision",SqlDbType.NVarChar,20).Value=input.Decision;
  }
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo.Trim();
  cmd.Parameters.Add("@RevisionAnterior",SqlDbType.BigInt).Value=input.RevisionAnterior;
  cmd.Parameters.Add("@GeneracionEsperada",SqlDbType.Int).Value=input.GeneracionEsperada;
  await cmd.ExecuteNonQueryAsync();
 }
}
