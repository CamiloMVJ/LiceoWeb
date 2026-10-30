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
public class IndexModel(PlanificacionRepository repository,PlanificacionService service,UsuarioActual usuario,ILogger<IndexModel> logger):PageModel
{
 public static readonly string[] Acciones=["Pensum","Materia","Grupo","Docente","Horario","Estudiante"];
 [BindProperty] public PlanificacionInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<SelectListItem> Opciones(string tabla)=>Datos.Tables.Contains(tabla)?Datos.Tables[tabla]!.AsEnumerable().Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString())):[];
 public async Task<IActionResult> OnGetAsync(string accion="Pensum")
 {if(!Acciones.Contains(accion))return BadRequest();Input.Accion=accion;Datos=await repository.ConsultarAsync(usuario.ObtenerId());return Page();}
 public async Task<IActionResult> OnPostAsync()
 {
  if(!Acciones.Contains(Input.Accion))return BadRequest();
  if(ModelState.IsValid)try{await service.GuardarPlanAsync(Input);Mensaje="Operación de planificación registrada.";return RedirectToPage(new{accion=Input.Accion});}
  catch(SqlException ex) when(ex.Number is >=52300 and <=52316){ModelState.AddModelError("",ex.Message);}
  catch(SqlException ex) when(ex.Number is 2601 or 2627){ModelState.AddModelError("","La planificación ya contiene esa relación. No se duplicó.");}
  catch(Exception ex){logger.LogError("Fallo de planificación: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa los scripts instalados.");}
  Datos=await repository.ConsultarAsync(usuario.ObtenerId());return Page();
 }
}
