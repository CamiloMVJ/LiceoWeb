using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Estudiantes;

public class RegistrarModel : PageModel
{
    [BindProperty] public EstudianteFormulario Alumno { get; set; } = new();

    public void OnGet() { }
    public IActionResult OnPost()
    {
        if (!ModelState.IsValid) return Page();
        // TODO: verificar código único y guardar mediante el servicio o DbContext del proyecto.
        ModelState.AddModelError(string.Empty, "Vista de demostración: todavía no se conectó el guardado a SQL Server.");
        return Page();
    }
}
