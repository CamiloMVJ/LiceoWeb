using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Notas;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class CierreModel(CierreAcademicoRepository repository,UsuarioActual usuario,ILogger<CierreModel> logger):PageModel
{
 [BindProperty] public CierreAcademicoInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<DataRow> Filas(string tabla)=>Datos.Tables.Contains(tabla)?Datos.Tables[tabla]!.AsEnumerable():[];
 public DataRow? Periodo=>Filas("Periodos").FirstOrDefault(r=>(int)r["Id"]==Input.PeriodoId);
 private async Task Cargar()=>Datos=await repository.ConsultarAsync(usuario.ObtenerId(),Input.PeriodoId);
 public async Task<IActionResult> OnGetAsync(int periodoId=0,string? accion=null,int asignacionId=0)
 {
  Input.PeriodoId=periodoId;Input.AsignacionId=asignacionId;
  await Cargar();if(periodoId!=0 && Periodo is null)return NotFound();
  if(Periodo is not null)
  {
   Input.Accion=accion??((bool)Periodo["Cerrado"]?"ReabrirPeriodo":"CerrarPeriodo");
   if(Input.Accion is not ("ReabrirAsignacion" or "CerrarPeriodo" or "ReabrirPeriodo"))return BadRequest();
   if(Input.Accion=="ReabrirAsignacion")
   {
    var a=Filas("Asignaciones").FirstOrDefault(r=>(int)r["Id"]==asignacionId && (bool)r["Publicado"]);
    if(a is null)return NotFound();Input.Version=a["Version"].ToString()!;
   }else Input.Version=Periodo["Version"].ToString()!;
  }
  return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(ModelState.IsValid)try{await repository.GuardarAsync(Input,usuario.ObtenerId());Mensaje="Operación registrada con motivo e historial.";return RedirectToPage(new{periodoId=Input.PeriodoId});}
  catch(SqlException ex) when(ex.Number==52601){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=52600 and <=52605){ModelState.AddModelError("",ex.Message);}
  catch(Exception ex){logger.LogError("Error de cierre académico: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  await Cargar();return Page();
 }
}
