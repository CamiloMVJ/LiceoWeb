using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class ConciliacionModel(ConciliacionRepository repository,UsuarioActual usuario,ILogger<ConciliacionModel> logger):PageModel
{
 [BindProperty] public ConciliacionInput Input {get;set;}=new();
 [BindProperty(SupportsGet=true)] public int Pagina {get;set;}=1;
 [BindProperty(SupportsGet=true)] public string? Registro {get;set;}
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<DataRow> Filas(string tabla)=>Datos.Tables.Contains(tabla)?Datos.Tables[tabla]!.AsEnumerable():[];
 public DataRow? Seleccion=>Filas("Seleccion").FirstOrDefault();
 public IEnumerable<SelectListItem> Tarifas=>Filas("Tarifas").Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString()));
 private Task CargarAsync()=>CargarInternoAsync();
 private async Task CargarInternoAsync(){Datos=await repository.ConsultarAsync(usuario.ObtenerId(),Pagina,Registro,Input.Origen,Input.OrigenId);}
 private bool FiltrosValidos()=>Pagina>=1 && Pagina<=100000 && (Registro?.Length??0)<=10;
 public async Task<IActionResult> OnGetAsync(string origen="",int origenId=0)
 {
  if(!FiltrosValidos() || origen.Length>30 || origenId<0)return BadRequest();
  Input.Origen=origen;Input.OrigenId=origenId;await CargarAsync();
  if(origenId>0 && Seleccion is null)return NotFound();
  if(Seleccion is not null)Input.RevisionAnterior=(long)Seleccion["RevisionAnterior"];
  return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(!FiltrosValidos())return BadRequest();
  if(ModelState.IsValid)
  try{await repository.GuardarAsync(Input,usuario.ObtenerId());Mensaje="Revisión registrada. No se generaron cargos ni pagos.";return RedirectToPage(new{origen=Input.Origen,origenId=Input.OrigenId,Pagina,Registro});}
  catch(SqlException ex) when(ex.Number==53001){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=53000 and <=53005){ModelState.AddModelError("",ex.Message);}
  catch(Exception ex){logger.LogError("Error de conciliación: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  await CargarAsync();return Page();
 }
}
