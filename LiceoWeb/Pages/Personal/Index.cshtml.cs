using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Personal;

[Authorize(Policy = "SoloAdministrador")]
public class IndexModel(UserManager<IdentityUser> users, RoleManager<IdentityRole> roles,
    ApplicationDbContext db, ILogger<IndexModel> logger) : PageModel
{
    public static readonly string[] Roles = ["Administrador", "Profesor", "Cajero"];
    [BindProperty] public CuentaInput Input { get; set; } = new();
    [TempData] public string? Mensaje { get; set; }
    public void OnGet() { }
    public async Task<IActionResult> OnPostAsync()
    {
        if (!Roles.Contains(Input.Rol)) ModelState.AddModelError("Input.Rol", "Rol no permitido.");
        if (!ModelState.IsValid) return Page();
        await using var transaction = await db.Database.BeginTransactionAsync();
        try
        {
            if (!await roles.RoleExistsAsync(Input.Rol))
            {
                var roleResult = await roles.CreateAsync(new IdentityRole(Input.Rol));
                if (!roleResult.Succeeded) throw new InvalidOperationException("No se pudo crear el rol.");
            }
            var user = new IdentityUser { UserName = Input.Correo.Trim(), Email = Input.Correo.Trim(), EmailConfirmed = true };
            var result = await users.CreateAsync(user, Input.Contrasenia);
            if (!result.Succeeded)
            {
                foreach (var error in result.Errors) ModelState.AddModelError("", error.Description);
                await transaction.RollbackAsync();
                Input.Contrasenia = "";
                ModelState.Remove("Input.Contrasenia");
                return Page();
            }
            var assigned = await users.AddToRoleAsync(user, Input.Rol);
            if (!assigned.Succeeded) throw new InvalidOperationException("No se pudo asignar el rol.");
            var actorId = users.GetUserId(User) ?? throw new InvalidOperationException("Sesión inválida.");
            var operationId = Guid.NewGuid();
            await db.Database.ExecuteSqlInterpolatedAsync($"EXEC dbo.Registrar_Auditoria @UsuarioId={actorId}, @Accion=N'CrearCuentaPersonal', @Entidad=N'AspNetUsers', @RegistroId={user.Id}, @IdOperacion={operationId}");
            await transaction.CommitAsync();
            logger.LogInformation("Administrador {Actor} creó la cuenta interna {Cuenta} con rol {Rol}", users.GetUserId(User), user.Id, Input.Rol);
            Mensaje = "Cuenta creada. Entregue las credenciales al empleado por un canal privado.";
            return RedirectToPage();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            logger.LogError(ex, "Error al provisionar cuenta interna");
            ModelState.AddModelError("", "No se pudo crear la cuenta. Consulte al administrador técnico.");
            Input.Contrasenia = "";
            ModelState.Remove("Input.Contrasenia");
            return Page();
        }
    }
    public sealed class CuentaInput
    {
        [Required, EmailAddress, StringLength(256)] public string Correo { get; set; } = "";
        [Required, DataType(DataType.Password), StringLength(128, MinimumLength = 8)] public string Contrasenia { get; set; } = "";
        [Required] public string Rol { get; set; } = "Profesor";
    }
}
