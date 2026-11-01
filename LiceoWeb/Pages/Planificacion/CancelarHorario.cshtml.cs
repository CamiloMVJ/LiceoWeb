using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Planificacion;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class CancelarHorarioModel(HorarioRepository repository,UsuarioActual usuario,ILogger<CancelarHorarioModel> logger):PageModel
{
 [BindProperty] public CancelarHorarioInput Input {get;set;}=new();
 public DataRow? Horario {get;private set;}
 public bool PuedeCancelar=>Horario is not null && !(bool)Horario["Cancelado"] && !(bool)Horario["Cerrado"];
 public async Task<IActionResult> OnGetAsync(int id)
 {
  var error=await CargarAsync(id);if(error is not null)return error;
  Input=new(){HorarioId=id,Version=(string)Horario!["Version"],Operacion=Guid.NewGuid()};return Page();
 }
 public async Task<IActionResult> OnPostAsync(int id)
 {
  if(id!=Input.HorarioId)return BadRequest();
  if(ModelState.IsValid)
  {
   try { await repository.CancelarAsync(usuario.ObtenerId(),Input);TempData["Mensaje"]="Horario cancelado. El registro original se conserva en el historial.";return RedirectToPage("HistorialHorarios"); }
   catch(SqlException ex) when(ex.Number==54201){return Forbid();}
   catch(SqlException ex) when(ex.Number is >=54202 and <=54208){ModelState.AddModelError("",ex.Message);}
   catch(Exception ex){logger.LogError("Cancelación de horario: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo cancelar. Revisa la conexión y los scripts de horarios.");}
  }
  return await CargarAsync(id) ?? Page();
 }
 private async Task<IActionResult?> CargarAsync(int id)
 {
  if(id<=0)return NotFound();
  try { Horario=await repository.ConsultarAsync(usuario.ObtenerId(),id);if(Horario is null)return NotFound(); }
  catch(SqlException ex) when(ex.Number==54201){return Forbid();}
  catch(Exception ex){logger.LogError("Consulta de horario: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo consultar. Revisa conexión, migración 018 y Horario_Consultar.sql.");return Page();}
  return null;
 }
}
