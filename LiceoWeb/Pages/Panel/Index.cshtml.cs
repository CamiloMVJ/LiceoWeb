using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Panel;

[Authorize(Policy = "OperarSistema")]
public class IndexModel : PageModel
{
    public void OnGet()
    {
    }
}