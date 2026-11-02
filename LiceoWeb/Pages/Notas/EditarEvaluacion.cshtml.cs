using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Text.Json;
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
public class EditarEvaluacionModel(EvaluacionRepository repository,UsuarioActual usuario,ILogger<EditarEvaluacionModel> logger):PageModel
{
 [BindProperty] public EditarEvaluacionInput Input {get;set;}=new();
 [BindProperty(SupportsGet=true),Range(1,1000000)] public int Pagina {get;set;}=1;
 [TempData] public string? Mensaje {get;set;}
 public DataSet Datos {get;private set;}=new();
 public DataRow? Evaluacion=>Datos.Tables.Contains("Evaluacion")&&Datos.Tables["Evaluacion"]!.Rows.Count>0?Datos.Tables["Evaluacion"]!.Rows[0]:null;
 public bool Bloqueada=>Evaluacion is null||(bool)Evaluacion["Bloqueada"];
 public long Total=>Datos.Tables.Contains("Resumen")?(long)Datos.Tables["Resumen"]!.Rows[0]["Total"]:0;
 public IEnumerable<SelectListItem> Tipos=>Datos.Tables.Contains("Tipos")?Datos.Tables["Tipos"]!.AsEnumerable().Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString())):[];
 public async Task<IActionResult> OnGetAsync(int id)
 {
  if(id<=0||Pagina is <1 or >1000000)return BadRequest();
  var error=await CargarAsync(id);if(error is not null)return error;
  if(Evaluacion is not { } e)return NotFound();
  Input=new(){Id=id,TipoId=(int)e["TipoId"],Nombre=(string)e["Nombre"],Fecha=DateOnly.FromDateTime((DateTime)e["Fecha"]),Modo=(string)e["Modo"],Maximo=(decimal)e["Maximo"],Peso=(decimal)e["Peso"],Version=(string)e["Version"],Operacion=Guid.NewGuid(),Opciones=string.Join("\n",Datos.Tables["Opciones"]!.AsEnumerable().Select(r=>(string)r["Valor"]))};return Page();
 }
 public async Task<IActionResult> OnPostAsync(int id)
 {
  if(id!=Input.Id||id<=0||Pagina is <1 or >1000000)return BadRequest();
  if(ModelState.IsValid)
  {
   try{await repository.GuardarAsync(usuario.ObtenerId(),Input);Mensaje="Definición actualizada; se conservó la versión anterior en el historial.";return RedirectToPage(new{id});}
   catch(SqlException ex) when(ex.Number==54401){return Forbid();}
   catch(SqlException ex) when(ex.Number is >=54402 and <=54408){ModelState.AddModelError("",ex.Message);}
   catch(Exception ex){logger.LogError("Edición de evaluación: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa conexión y scripts de evaluación.");}
  }
  return await CargarAsync(id)??Page();
 }
 private async Task<IActionResult?> CargarAsync(int id)
 {
  try{Datos=await repository.ConsultarAsync(usuario.ObtenerId(),id,Pagina);}
  catch(SqlException ex) when(ex.Number==54401){return Forbid();}
  catch(Exception ex){logger.LogError("Consulta de evaluación: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo consultar. Revisa migración 020 y Evaluacion_ConsultarEdicion.sql.");return Page();}
  return null;
 }
 public static string Describir(string json)
 {
  using var doc=JsonDocument.Parse(json);var e=doc.RootElement;
  var text=$"{e.GetProperty("Nombre").GetString()} · {e.GetProperty("Tipo").GetString()} · {e.GetProperty("Fecha").GetString()} · {e.GetProperty("Modo").GetString()}";
  return e.GetProperty("Modo").GetString()=="Cuantitativa"
   ?text+$" · máximo {e.GetProperty("Maximo")} · peso {e.GetProperty("Peso")}%"
   :text+" · escala: "+string.Join(", ",e.GetProperty("Valores").EnumerateArray().Select(v=>v.GetProperty("Valor").GetString()));
 }
}
