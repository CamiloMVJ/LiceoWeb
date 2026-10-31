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
public class ArancelesModel(ArancelRepository repository,UsuarioActual usuario,ILogger<ArancelesModel> logger):PageModel
{
 public static readonly string[] Acciones=["Arancel","Tarifa","Mapeo","Preparar"];
 [BindProperty] public ArancelInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<DataRow> Filas(string tabla)=>Datos.Tables.Contains(tabla)?Datos.Tables[tabla]!.AsEnumerable():[];
 public IEnumerable<SelectListItem> Opciones(string tabla)=>Filas(tabla).Select(r=>new SelectListItem((tabla=="Aranceles"?r["Nombre"]:r["Etiqueta"]).ToString()+((bool)r["Activo"]?"":" (inactivo)"),r["Id"].ToString()));
 private async Task Cargar()=>Datos=await repository.ConsultarAsync(usuario.ObtenerId());
 public async Task<IActionResult> OnGetAsync(string accion="Arancel",int id=0)
 {
  if(!Acciones.Contains(accion)||id<0)return BadRequest();Input.Accion=accion;Input.Id=id;await Cargar();
  if(id>0)
  {
   if(accion is not ("Arancel" or "Tarifa"))return BadRequest();
   var r=Filas(accion=="Arancel"?"Aranceles":"Tarifas").FirstOrDefault(r=>(int)r["Id"]==id);if(r is null)return NotFound();
   Input.Activo=(bool)r["Activo"];Input.Version=r["Version"].ToString();
   if(accion=="Arancel"){Input.Codigo=(string)r["Codigo"];Input.Nombre=(string)r["Nombre"];}
   else{Input.ArancelId=(int)r["ArancelId"];Input.ModalidadId=(int)r["ModalidadId"];Input.AnioId=(int)r["AnioId"];Input.Importe=(decimal)r["Importe"];}
  }
  return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(!Acciones.Contains(Input.Accion))return BadRequest();
  if(ModelState.IsValid)try{await repository.GuardarAsync(Input,usuario.ObtenerId());Mensaje=Input.Accion=="Preparar"?"Captura completada. Los registros anteriores no se duplicaron; revisa las fuentes cambiadas.":"Operación guardada con auditoría.";return RedirectToPage(new{accion=Input.Accion});}
  catch(SqlException ex) when(ex.Number==52801){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=52800 and <=52804){ModelState.AddModelError("",ex.Message);}
  catch(SqlException ex) when(ex.Number is 2601 or 2627){ModelState.AddModelError("","Ya existe ese código o combinación de arancel, modalidad y año.");}
  catch(Exception ex){logger.LogError("Error de catálogo financiero: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar. Revisa la instalación del módulo.");}
  await Cargar();return Page();
 }
}
