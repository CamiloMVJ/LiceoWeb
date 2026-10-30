using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Estudiantes;
[Authorize(Policy="SoloAdministrador")]
public class DarBajaModel(SqlConnectionFactory factory, UsuarioActual usuario) : PageModel
{
 [BindProperty(SupportsGet=true),Required,StringLength(10)] public string Registro {get;set;}="";
 [BindProperty,Required,StringLength(500)] public string Motivo {get;set;}="";
 public string Nombre {get;private set;}="";
 private async Task<bool> CargarAsync()
 {
  await using var c=factory.Create(); await c.OpenAsync(); await using var cmd=c.CreateCommand();
  cmd.CommandText="SELECT NombreEstudiante FROM dbo.Estudiantes WHERE Registro=@Registro";
  cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=Registro;
  var value=await cmd.ExecuteScalarAsync(); Nombre=value as string ?? ""; return value is string;
 }
 public async Task<IActionResult> OnGetAsync()
 {
  if(string.IsNullOrWhiteSpace(Registro)||Registro.Length>10)return BadRequest();
  return await CargarAsync()? Page():NotFound();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(!ModelState.IsValid)return Page();
  if(!await CargarAsync())return NotFound();
  await using var c=factory.Create(); await c.OpenAsync(); await using var cmd=c.CreateCommand();
  cmd.CommandText="dbo.Estudiante_DarBaja";cmd.CommandType=CommandType.StoredProcedure;
  cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=Registro;
  cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=Motivo;
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();
  try { await cmd.ExecuteNonQueryAsync(); return RedirectToPage("Index"); }
  catch(SqlException ex) when(ex.Number is >=52110 and <=52116){ModelState.AddModelError("",ex.Message);return Page();}
 }
}
