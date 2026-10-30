using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;

namespace LiceoWeb.Pages.Estudiantes;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class ExpedienteModel(ExpedienteRepository repository, ExpedienteService service, ILogger<ExpedienteModel> logger) : PageModel
{
    [BindProperty] public ExpedienteInput Input { get; set; } = new();
    public DataTable Historial { get; private set; } = new();
    [TempData] public string? Mensaje { get; set; }
    public int? Edad => Input.FechaNacimiento is { } fecha ? CalcularEdad(fecha) : null;
    private static int CalcularEdad(DateOnly fecha)
    {
        var hoy=DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTimeOffset.UtcNow,"Central America Standard Time").DateTime);
        var edad=hoy.Year-fecha.Year; return fecha.AddYears(edad)>hoy ? edad-1 : edad;
    }
    public async Task<IActionResult> OnGetAsync(string? registro)
    {
        if(string.IsNullOrWhiteSpace(registro)) return Page();
        if(registro.Length>10) return BadRequest();
        var input=await repository.ObtenerAsync(registro);
        if(input is null) return NotFound();
        Input=input; Input.Motivo="";
        Historial=await repository.TutelasAsync(registro);
        return Page();
    }
    public async Task<IActionResult> OnPostAsync()
    {
        if(!ModelState.IsValid) return Page();
        try
        {
            var registro=await service.GuardarAsync(Input);
            Mensaje="Expediente guardado correctamente.";
            return RedirectToPage(new {registro});
        }
        catch(SqlException ex) when(ex.Number is >=52110 and <=52116)
        {
            ModelState.AddModelError("",ex.Message);
        }
        catch(Exception ex)
        {
            // No registrar el formulario ni texto médico en logs.
            logger.LogError("Error de persistencia de expediente. Tipo: {Tipo}",ex.GetType().Name);
            ModelState.AddModelError("","No se pudo guardar. Verifique la instalación de los scripts y contacte al administrador.");
        }
        return Page();
    }
}
