using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LiceoWeb.Pages.Estudiantes;
[Authorize(Policy="GestionFinanciera")]
public class IndexModel(ExpedienteRepository repository, ILogger<IndexModel> logger) : PageModel
{
 [BindProperty(SupportsGet=true)] public string? Busqueda {get;set;}
 [BindProperty(SupportsGet=true)] public string? Modalidad {get;set;}
 [BindProperty(SupportsGet=true)] public string? Estado {get;set;}
 public IReadOnlyList<EstudianteListadoViewModel> Estudiantes {get;private set;}=[];
 public bool ConsultaRealizada {get;private set;}
 public string? Error {get;private set;}
 public async Task OnGetAsync()
 {
  if(Busqueda?.Length>100 || Modalidad is not (null or "" or "Preescolar" or "Primaria" or "Secundaria") || Estado is not (null or "" or "Activo" or "Inactivo"))
  { Error="Filtros inválidos."; return; }
  try { Estudiantes=await repository.ListarAsync(Busqueda,Modalidad,Estado); ConsultaRealizada=true; }
  catch(Exception ex) { logger.LogError("Fallo en consulta de estudiantes: {Tipo}",ex.GetType().Name); Error="No se pudo consultar el listado. Verifique la conexión con la base de datos."; }
 }
}
