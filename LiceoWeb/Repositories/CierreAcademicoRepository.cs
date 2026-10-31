using System.Data;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Repositories;
public sealed class CierreAcademicoRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuario,int periodo)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.CierreAcademico_Consultar";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@PeriodoId",SqlDbType.Int).Value=periodo;
  await using var reader=await cmd.ExecuteReaderAsync();var result=new DataSet();
  foreach(var name in new[]{"Periodos","Asignaciones","Historial","Eventos"}){var table=new DataTable(name);table.Load(reader);result.Tables.Add(table);}return result;
 }
 public async Task GuardarAsync(CierreAcademicoInput input,string usuario)
 {
  Validator.ValidateObject(input,new ValidationContext(input),true);
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.CierreAcademico_Guardar";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@Accion",SqlDbType.NVarChar,30).Value=input.Accion;
  cmd.Parameters.Add("@PeriodoId",SqlDbType.Int).Value=input.PeriodoId;
  cmd.Parameters.Add("@AsignacionId",SqlDbType.Int).Value=input.AsignacionId;
  cmd.Parameters.Add("@Version",SqlDbType.VarChar,18).Value=input.Version;
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo.Trim();
  await cmd.ExecuteNonQueryAsync();
 }
}
