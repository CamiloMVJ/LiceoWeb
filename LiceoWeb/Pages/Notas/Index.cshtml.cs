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
 public DataRow? Clase=>Filas("Asignaciones").FirstOrDefault(r=>(int)r["Id"]==Input.AsignacionId);
 public bool Cargado {get;private set;}
 public decimal PesoTotal=>Filas("Evaluaciones").Where(r=>r["Modo"].ToString()=="Cuantitativa").Sum(r=>r.Field<decimal>("Peso"));
 public int Pendientes=>Filas("Resumen").Sum(r=>r.Field<int?>("Pendientes")??0);
 public bool PuedePublicar=>!Bloqueado && Filas("Evaluaciones").Any() && Filas("Resumen").Any() && Pendientes==0 && (!Filas("Evaluaciones").Any(r=>r["Modo"].ToString()=="Cuantitativa") || PesoTotal==100);
 public DataRow? Evaluacion=>Filas("Evaluaciones").FirstOrDefault(r=>(int)r["Id"]==Input.EvaluacionId);
 public bool Bloqueado=>Filas("Asignaciones").Any(r=>(int)r["Id"]==Input.AsignacionId && ((bool)r["Publicado"] || (bool)r["Cerrado"]));
 private async Task Cargar()
 {
  var datos=await repository.ConsultarAsync(usuario.ObtenerId(),Input.AsignacionId,Input.EvaluacionId);
  if(datos.Tables["Asignaciones"]?.Columns.Contains("GrupoId")!=true || datos.Tables["Resumen"]?.Columns.Contains("NombreEstudiante")!=true)
   throw new InvalidDataException("Notas_Consultar necesita actualizarse desde Notas.sql.");
  Datos=datos;Cargado=true;
 }
 public async Task<IActionResult> OnGetAsync(int asignacionId=0,int evaluacionId=0,string accion="Evaluacion",string? registro=null,int tipoId=0)
 {
  if(accion is not ("Evaluacion" or "Tipo" or "Nota" or "Publicar") || asignacionId<0 || evaluacionId<0)return BadRequest();
  if(accion=="Tipo" && !User.IsInRole("Administrador"))return Forbid();
  Input=new(){AsignacionId=asignacionId,EvaluacionId=evaluacionId,Accion=accion,Registro=registro,TipoId=tipoId};
  try{await Cargar();}catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  catch(Exception ex){logger.LogError(ex,"Cargar calificaciones");ModelState.AddModelError("","No se pudo cargar la clase. Revisa la conexión y Notas.sql.");return Page();}
  if(registro is not null)
  {
   var row=Filas("Estudiantes").FirstOrDefault(r=>r["Registro"].ToString()==registro);
   if(row is null)return NotFound();
   Input.VersionEvaluacion=Evaluacion?.Field<string>("Version");
   Input.Nota=row.Field<decimal?>("Nota");Input.Resultado=row.Field<string?>("Resultado");Input.Observacion=row.Field<string?>("Observacion");Input.Version=row.Field<string?>("Version");
  }
  return Page();
 }
 public async Task<IActionResult> OnPostAsync(bool siguiente=false)
 {
  if(Input.Accion=="Tipo" && !User.IsInRole("Administrador"))return Forbid();
  if(ModelState.IsValid)
  try
  {
   int id=await service.GuardarAsync(Input);
   Mensaje=Input.Accion=="Publicar"?"Resultados publicados y bloqueados para edición.":"Cambio guardado.";
   if(Input.Accion=="Evaluacion")return RedirectToPage(new{asignacionId=Input.AsignacionId,evaluacionId=id,accion="Nota"});
   if(Input.Accion=="Tipo")return RedirectToPage(new{asignacionId=Input.AsignacionId,tipoId=id});
   string? proximo=null;
   if(Input.Accion=="Nota" && siguiente)
   {
    // La nota ya se guardó. Un fallo de lectura no debe presentarse como fallo de escritura.
    try{await Cargar();proximo=Filas("Estudiantes").FirstOrDefault(r=>r["Registro"].ToString()!=Input.Registro && r["Nota"] is DBNull && r["Resultado"] is DBNull)?["Registro"].ToString();}
    catch(Exception ex){logger.LogWarning(ex,"Nota guardada; no se pudo buscar el siguiente pendiente");}
   }
   return RedirectToPage(new{asignacionId=Input.AsignacionId,evaluacionId=Input.EvaluacionId,registro=proximo,accion=Input.Accion=="Nota"?"Nota":"Publicar"});
  }
  catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=52400 and <=52409){ModelState.AddModelError("",ex.Message);}
  catch(SqlException ex) when(ex.Number is 2601 or 2627){ModelState.AddModelError("","Ese nombre o resultado ya existe.");}
  catch(Exception ex){logger.LogError("Error de notas: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  try{await Cargar();}catch(SqlException ex) when(ex.Number==52401){return Forbid();}
  catch(Exception ex){logger.LogError(ex,"Recargar calificaciones");ModelState.AddModelError("","No se pudo recargar la clase. Conserva tus datos y revisa la conexión.");}
  return Page();
 }
}
