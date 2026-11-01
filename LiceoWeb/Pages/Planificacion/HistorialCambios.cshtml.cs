using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Planificacion;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class HistorialCambiosModel(CambioPlanificacionRepository repository,UsuarioActual usuario,ILogger<HistorialCambiosModel> logger):PageModel
{
 [BindProperty(SupportsGet=true),Range(1,1000000)] public int Pagina {get;set;}=1;
 [TempData] public string? Mensaje {get;set;}
 public DataSet Datos {get;private set;}=new();
 public bool Cargado=>Datos.Tables.Contains("Historial");
 public long Total=>Cargado?(long)Datos.Tables["Resumen"]!.Rows[0]["Total"]:0;
 public async Task<IActionResult> OnGetAsync()
 {
  if(!ModelState.IsValid)return Page();
  try { Datos=await repository.HistorialAsync(usuario.ObtenerId(),Pagina); }
  catch(SqlException ex) when(ex.Number==54301){return Forbid();}
  catch(SqlException ex) when(ex.Number==54302){ModelState.AddModelError("",ex.Message);}
  catch(Exception ex){logger.LogError("Historial de cambios: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo consultar. Revisa conexión, migración 019 y Planificacion_CambiosHistorial.sql.");}
  return Page();
 }
}
