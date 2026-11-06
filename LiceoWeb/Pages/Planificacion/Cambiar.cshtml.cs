using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Planificacion;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class CambiarModel(CambioPlanificacionRepository repository,UsuarioActual usuario,ILogger<CambiarModel> logger):PageModel
{
 [BindProperty(SupportsGet=true)] public string? Retorno {get;set;}
 public string Volver => Url.IsLocalUrl(Retorno) ? Retorno! : Url.Page("/Planificacion/Index")!;
 [BindProperty] public CambioPlanificacionInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 public DataRow? Origen=>Datos.Tables.Contains("Origen")&&Datos.Tables["Origen"]!.Rows.Count>0?Datos.Tables["Origen"]!.Rows[0]:null;
 public IEnumerable<SelectListItem> Destinos=>Datos.Tables.Contains("Destinos")?Datos.Tables["Destinos"]!.AsEnumerable().Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString())):[];
 public async Task<IActionResult> OnGetAsync(string tipo,int origenId,string? registro)
 {
  if(tipo is not ("Docente" or "Estudiante")||origenId<=0||registro?.Length>10)return BadRequest();
  Input=new(){Tipo=tipo,OrigenId=origenId,Registro=registro,Operacion=Guid.NewGuid()};
  var error=await CargarAsync();if(error is not null)return error;
  if(Origen is null)return NotFound();Input.Version=(string)Origen["Version"];return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(Input.Tipo is not ("Docente" or "Estudiante")||Input.OrigenId<=0||Input.Registro?.Length>10)return BadRequest();
  if(ModelState.IsValid)
  {
   try{await repository.GuardarAsync(usuario.ObtenerId(),Input);TempData["Mensaje"]="Cambio registrado con historial y auditoría.";return Url.IsLocalUrl(Retorno)?LocalRedirect(Retorno!):RedirectToPage("HistorialCambios");}
   catch(SqlException ex) when(ex.Number==54301){return Forbid();}
   catch(SqlException ex) when(ex.Number is >=54302 and <=54312){ModelState.AddModelError("",ex.Message);}
   catch(Exception ex){logger.LogError("Cambio de planificación: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa conexión y scripts de cambios de planificación.");}
  }
  return await CargarAsync()??Page();
 }
 private async Task<IActionResult?> CargarAsync()
 {
  try{Datos=await repository.ConsultarAsync(usuario.ObtenerId(),Input.Tipo,Input.OrigenId,Input.Registro);}
  catch(SqlException ex) when(ex.Number==54301){return Forbid();}
  catch(Exception ex){logger.LogError("Consulta de cambio: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo consultar. Revisa migración 019 y Planificacion_CambioConsultar.sql.");return Page();}
  return null;
 }
}
