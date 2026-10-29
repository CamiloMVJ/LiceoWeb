using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Cobros
{
    [Authorize(Policy = "OperarSistema")]
    public class Index1Model : PageModel
    {
        public void OnGet()
        {
        }
    }
}
