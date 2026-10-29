using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Estudiantes;

[Authorize(Policy = "SoloAdministrador")]
public class IndexModel : PageModel
{
    [BindProperty(SupportsGet = true)]
    public string? Busqueda { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Modalidad { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Estado { get; set; }

    public IReadOnlyList<EstudianteListadoViewModel> Estudiantes
    { get; private set; } = [];

    public bool ConsultaRealizada { get; private set; }

    public void OnGet()
    {
        // Pendiente: consultar mediante el servicio de estudiantes.
        // No se agregan datos ficticios.
        // ConsultaRealizada permanece false hasta conectar la consulta.
    }
}