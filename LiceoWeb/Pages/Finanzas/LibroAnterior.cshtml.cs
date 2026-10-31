using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy="GestionFinanciera")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class LibroAnteriorModel : PageModel { public void OnGet() {} }
