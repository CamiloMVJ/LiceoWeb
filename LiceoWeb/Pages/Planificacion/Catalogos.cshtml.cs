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
public class CatalogosModel(PlanificacionRepository repository,PlanificacionService service,UsuarioActual usuario,ILogger<CatalogosModel> logger):PageModel
{
 public static readonly string[] Tipos=["Anios","Periodos","Modalidades","Turnos","Aulas","Asignaturas"];
 [BindProperty] public CatalogoInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 [TempData] public string? Mensaje {get;set;}
 public IEnumerable<SelectListItem> Anios=>Datos.Tables.Contains("Anios")?Datos.Tables["Anios"]!.AsEnumerable().Select(r=>new SelectListItem(r["Etiqueta"].ToString(),r["Id"].ToString())):[];
 private async Task CargarAsync(){Datos=await repository.ConsultarAsync(usuario.ObtenerId());}
 public async Task<IActionResult> OnGetAsync(string tipo="Anios",int id=0)
 {
  if(!Tipos.Contains(tipo)||id<0)return BadRequest();
  Input.Tipo=tipo;await CargarAsync();
  if(id==0)return Page();
  var row=Datos.Tables[tipo]!.AsEnumerable().FirstOrDefault(r=>(int)r["Id"]==id);if(row is null)return NotFound();
  Input.Id=id;
  if(row.Table.Columns.Contains("Nombre"))Input.Nombre=(string)row["Nombre"];
  if(row.Table.Columns.Contains("Activo"))Input.Activo=(bool)row["Activo"];
  if(tipo=="Anios")Input.Anio=(int)row["Anio"];
  if(tipo=="Periodos"){Input.AnioId=(int)row["AnioId"];Input.Inicio=DateOnly.FromDateTime((DateTime)row["Inicio"]);Input.Fin=DateOnly.FromDateTime((DateTime)row["Fin"]);}
  if(tipo=="Aulas"){Input.Ubicacion=(string)row["Ubicacion"];Input.Capacidad=(int)row["Capacidad"];}
  if(tipo=="Asignaturas")Input.Codigo=(string)row["Codigo"];
  return Page();
 }
 public async Task<IActionResult> OnPostAsync()
 {
  if(!Tipos.Contains(Input.Tipo))return BadRequest();
  if(ModelState.IsValid)try{await service.GuardarCatalogoAsync(Input);Mensaje="Catálogo actualizado.";return RedirectToPage(new{tipo=Input.Tipo});}
  catch(SqlException ex) when(ex.Number is >=52300 and <=52316){ModelState.AddModelError("",ex.Message);}
  catch(SqlException ex) when(ex.Number is 2601 or 2627){ModelState.AddModelError("","Ya existe un registro con esos datos.");}
  catch(Exception ex){logger.LogError("Fallo de catálogo: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo guardar el catálogo. Revisa los scripts instalados.");}
  await CargarAsync();return Page();
 }
}
