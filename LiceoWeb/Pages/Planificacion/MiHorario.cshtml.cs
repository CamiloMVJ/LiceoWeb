using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LiceoWeb.Pages.Planificacion;
[Authorize(Policy="GestionAcademica")]
public class MiHorarioModel(PlanificacionRepository repository,UsuarioActual usuario):PageModel
{
 public DataTable Horario {get;private set;}=new();
 public async Task OnGetAsync(){var datos=await repository.ConsultarAsync(usuario.ObtenerId(),true);Horario=datos.Tables["Horario"]!;}
}
