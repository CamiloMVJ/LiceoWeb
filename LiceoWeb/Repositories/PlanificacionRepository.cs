using System.Data;
using System.Text.Json;
using LiceoWeb.Data;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;
public sealed class PlanificacionRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuarioId,bool soloDocente=false)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.Planificacion_Consultar";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  cmd.Parameters.Add("@SoloDocente",SqlDbType.Bit).Value=soloDocente;
  await using var reader=await cmd.ExecuteReaderAsync();var result=new DataSet();
  // DataTable.Load avanza al siguiente resultado; los nombres son un contrato SQL.
  var names=soloDocente?new[]{"Horario"}:new[]{"Anios","Periodos","Modalidades","Turnos","Aulas","Asignaturas","Pensums","Materias","Grupos","Docentes","Asignaciones","Horario","EstudiantesGrupo"};
  foreach(var name in names){var table=new DataTable(name);table.Load(reader);result.Tables.Add(table);}
  return result;
 }
 public async Task GuardarAsync(string procedimiento,object input,string usuarioId)
 {
  if(procedimiento is not ("dbo.CatalogoAcademico_Guardar" or "dbo.Planificacion_Guardar"))throw new ArgumentException("Procedimiento inválido.");
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText=procedimiento;cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@Datos",SqlDbType.NVarChar,-1).Value=JsonSerializer.Serialize(input);
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuarioId;
  await cmd.ExecuteNonQueryAsync();
 }
}
