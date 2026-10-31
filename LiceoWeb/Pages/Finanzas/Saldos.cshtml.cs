using System.Data;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class SaldosModel(SqlConnectionFactory factory,UsuarioActual usuario,ILogger<SaldosModel> logger):PageModel
{
 public sealed class RevisionInput
 {
  [Required,StringLength(10)] public string Registro {get;set;}="";
  [Required,RegularExpression("^0x[0-9A-Fa-f]{64}$")] public string Huella {get;set;}="";
  [Range(typeof(long),"0","9223372036854775807")] public long RevisionAnterior {get;set;}
  [Required,RegularExpression("^(Aprobado|Rechazado)$")] public string Decision {get;set;}="";
  [Required,StringLength(200)] public string Referencia {get;set;}="";
  [Required,StringLength(500)] public string Motivo {get;set;}="";
 }
 [BindProperty] public RevisionInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 public bool Cargado=>Datos.Tables.Contains("Resumen");
 [TempData] public string? Mensaje {get;set;}
 private async Task CargarAsync()
 {
  await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="dbo.Saldo_Consultar";
  cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=Input.Registro;
  await using var reader=await cmd.ExecuteReaderAsync();var ds=new DataSet();foreach(var n in new[]{"Resumen","Pagos","Historial"}){var t=new DataTable(n);t.Load(reader);ds.Tables.Add(t);}Datos=ds;
 }
 public async Task<IActionResult> OnGetAsync(string? registro=null)
 {
  if(string.IsNullOrWhiteSpace(registro))return Page();if(registro.Length>10)return BadRequest();Input.Registro=registro.Trim();
  try{await CargarAsync();}catch(SqlException ex) when(ex.Number==53200){ModelState.AddModelError("",ex.Message);return Page();}
  var r=Datos.Tables["Resumen"]!.Rows[0];Input.Huella=(string)r["Huella"];Input.RevisionAnterior=(long)r["RevisionAnterior"];return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(ModelState.IsValid)try
  {
   await using var c=factory.Create();await c.OpenAsync();await using var cmd=c.CreateCommand();cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="dbo.Saldo_Revisar";
   cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();
   cmd.Parameters.Add("@Registro",SqlDbType.NVarChar,10).Value=Input.Registro;
   cmd.Parameters.Add("@Huella",SqlDbType.VarChar,66).Value=Input.Huella;
   cmd.Parameters.Add("@RevisionAnterior",SqlDbType.BigInt).Value=Input.RevisionAnterior;
   cmd.Parameters.Add("@Decision",SqlDbType.NVarChar,20).Value=Input.Decision;
   cmd.Parameters.Add("@Referencia",SqlDbType.NVarChar,200).Value=Input.Referencia.Trim();
   cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=Input.Motivo.Trim();
   await cmd.ExecuteNonQueryAsync();Mensaje="Revisión registrada. No se movió dinero ni se generaron pagos.";return RedirectToPage(new{registro=Input.Registro});
  }
  catch(SqlException ex) when(ex.Number==53201){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=53200 and <=53204){ModelState.AddModelError("",ex.Message);}
  catch(Exception ex){logger.LogError("Error de revisión de saldo: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  if(!string.IsNullOrWhiteSpace(Input.Registro)&&Input.Registro.Length<=10)
   try{await CargarAsync();}catch(SqlException ex) when(ex.Number==53200){ModelState.AddModelError("",ex.Message);}
  return Page();
 }
}
