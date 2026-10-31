using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Notas;
[Authorize(Policy="GestionAcademica")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class IndexModel(NotasRepository repository,NotasService service,UsuarioActual usuario,ILogger<IndexModel> logger):PageModel
{
 [BindProperty] public NotasInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<DataRow> Filas(string tabla)=>Datos.Tables.Contains(tabla)?Datos.Tables[tabla]!.AsEnumerable():[];
 public IEnumerable<SelectListItem> Opciones(string tabla)=>Filas(tabla).Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString()));
 public DataRow? Evaluacion=>Filas("Evaluaciones").FirstOrDefault(r=>(int)r["Id"]==Input.EvaluacionId);
 public bool Bloqueado=>Filas("Asignaciones").Any(r=>(int)r["Id"]==Input.AsignacionId && ((bool)r["Publicado"] || (bool)r["Cerrado"]));
 private async Task Cargar()=>Datos=await repository.ConsultarAsync(usuario.ObtenerId(),Input.AsignacionId,Input.EvaluacionId);
 public async Task<IActionResult> OnGetAsync(int asignacionId=0,int evaluacionId=0,string accion="Evaluacion",string? registro=null)
 {
  if(accion is not ("Evaluacion" or "Tipo" or "Nota" or "Publicar") || asignacionId<0 || evaluacionId<0)return BadRequest();
  if(accion=="Tipo" && !User.IsInRole("Administrador"))return Forbid();
  Input=new(){AsignacionId=asignacionId,EvaluacionId=evaluacionId,Accion=accion,Registro=registro};
  try{await Cargar();}catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  if(registro is not null)
  {
   var row=Filas("Estudiantes").FirstOrDefault(r=>r["Registro"].ToString()==registro);
   if(row is null)return NotFound();
   Input.Nota=row.Field<decimal?>("Nota");Input.Resultado=row.Field<string?>("Resultado");Input.Observacion=row.Field<string?>("Observacion");Input.Version=row.Field<string?>("Version");
  }
  return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(Input.Accion=="Tipo" && !User.IsInRole("Administrador"))return Forbid();
  if(ModelState.IsValid)
  try{await service.GuardarAsync(Input);Mensaje=Input.Accion=="Publicar"?"Resultados publicados y bloqueados para edición.":"Cambio guardado.";return RedirectToPage(new{asignacionId=Input.AsignacionId,evaluacionId=Input.EvaluacionId,accion=Input.Accion=="Nota"?"Nota":"Evaluacion"});}
  catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=52400 and <=52409){ModelState.AddModelError("",ex.Message);}
  catch(SqlException ex) when(ex.Number is 2601 or 2627){ModelState.AddModelError("","Ese nombre o resultado ya existe.");}
  catch(Exception ex){logger.LogError("Error de notas: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  try{await Cargar();}catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  return Page();
 }
}
