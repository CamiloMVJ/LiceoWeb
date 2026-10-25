using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Areas.Identity.Pages.Account;

[AllowAnonymous]
public class RegisterModel : PageModel
{
    public IActionResult OnGet()
    {
        return NotFound();
    }

    public IActionResult OnPost()
    {
        return NotFound();
    }
}