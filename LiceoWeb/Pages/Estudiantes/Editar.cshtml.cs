using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LiceoWeb.Pages.Estudiantes;
[Authorize(Policy="SoloAdministrador")]
public class EditarModel : PageModel
{
 public IActionResult OnGet(string? registro) => RedirectToPage("Expediente", new { registro });
}
