using System.Data;
using System.Security.Claims;
using System.Text.Json;
using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Personal;

[Authorize(Policy = "SoloAdministrador")]
[ResponseCache(Location = ResponseCacheLocation.None, NoStore = true)]
public sealed class AdministrarModel(PersonalRepository repository, ILogger<AdministrarModel> logger) : PageModel
{
    [BindProperty(SupportsGet = true)] public string? Id { get; set; }
    [BindProperty(SupportsGet = true)] public string? Busqueda { get; set; }
    [BindProperty(SupportsGet = true)] public int Pagina { get; set; } = 1;
    [BindProperty] public PersonalInput Input { get; set; } = new();
    [TempData] public string? Mensaje { get; set; }
    public DataSet Datos { get; private set; } = new();
    public string Actor => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    public long Total => Convert.ToInt64(Datos.Tables["Resumen"]!.Rows[0]["Total"]);
    public DataRow? Cuenta => Datos.Tables["Cuenta"]!.Rows.Cast<DataRow>().FirstOrDefault();
    public bool Editable => Cuenta is not null && Id != Actor && PersonalInput.Roles.Contains(Cuenta["Roles"].ToString());
    public async Task<IActionResult> OnGetAsync()
    {
        if (!ParametrosValidos()) return BadRequest();
        await CargarAsync();
        if (Id is not null && Cuenta is null) return NotFound();
        if (Cuenta is not null) Input = new() { CuentaId = Id!, Version = Cuenta["Version"].ToString()!, Rol = Cuenta["Roles"].ToString()!, Activa = Convert.ToBoolean(Cuenta["Activa"]) };
        return Page();
    }
    public async Task<IActionResult> OnPostAsync()
    {
        if (!ParametrosValidos() || Id is null || Id != Input.CuentaId) return BadRequest();
        if (Id == Actor) return Forbid();
        if (ModelState.IsValid)
        {
            try
            {
                await repository.GuardarAsync(Actor, Input);
                Mensaje = "Cuenta actualizada. Sus sesiones anteriores dejarán de ser válidas en la siguiente solicitud.";
                return RedirectToPage(new { Id });
            }
            catch (SqlException ex) when (ex.Number == 54501) { return Forbid(); }
            catch (SqlException ex) when (ex.Number >= 54502 && ex.Number <= 54511) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex)
            {
                logger.LogError(ex, "No se pudo administrar una cuenta del personal");
                ModelState.AddModelError("", "No se pudo confirmar el cambio. Puede reintentar con los mismos datos; si persiste, contacte al administrador técnico.");
            }
        }
        await CargarAsync();
        if (Cuenta is null) return NotFound();
        return Page();
    }
    private bool ParametrosValidos() => Pagina is >= 1 and <= 100000 && (Busqueda?.Length ?? 0) <= 100 && (Id?.Length ?? 0) <= 450;
    private async Task CargarAsync() => Datos = await repository.ConsultarAsync(Actor, Id, Pagina, Busqueda ?? "");
    public static string Estado(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        return $"{root.GetProperty("Rol").GetString()} · {(root.GetProperty("Activa").GetBoolean() ? "Activa" : "Desactivada")}";
    }
}
