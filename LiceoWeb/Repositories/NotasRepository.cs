using System.Data;
using System.Text.Json;
using LiceoWeb.Data;
using LiceoWeb.ViewModels;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Repositories;
public sealed class NotasRepository(SqlConnectionFactory factory)
{
 public async Task<DataSet> ConsultarAsync(string usuario,int asignacion,int evaluacion)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.Notas_Consultar";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@AsignacionId",SqlDbType.Int).Value=asignacion;
  cmd.Parameters.Add("@EvaluacionId",SqlDbType.Int).Value=evaluacion;
  await using var reader=await cmd.ExecuteReaderAsync();var result=new DataSet();
  foreach(var name in new[]{"Asignaciones","Tipos","Evaluaciones","Estudiantes","Opciones","Resumen"})
  {var table=new DataTable(name);table.Load(reader);result.Tables.Add(table);}
  return result;
 }
 public async Task GuardarAsync(NotasInput input,string usuario)
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.Notas_Guardar";cmd.CommandType=CommandType.StoredProcedure;
  // Valores se obtiene en servidor de las líneas del formulario.
  var datos=new{input.Accion,input.AsignacionId,input.EvaluacionId,input.TipoId,input.Nombre,input.Fecha,input.Modo,input.Maximo,input.Peso,Valores=input.Valores(),input.Registro,input.Nota,input.Resultado,input.Observacion,input.Version};
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario;
  cmd.Parameters.Add("@Datos",SqlDbType.NVarChar,-1).Value=JsonSerializer.Serialize(datos);
  await cmd.ExecuteNonQueryAsync();
 }
}
