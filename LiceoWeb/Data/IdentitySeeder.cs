using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace LiceoWeb.Data;

public static class IdentitySeeder
{
    private static readonly string[] RolesPermitidos =
    [
        "Administrador",
        "Profesor",
        "Cajero"
    ];

    public static async Task CrearCuentasAsync(
        IServiceProvider services,
        IConfiguration configuration)
    {
        var cuentas = configuration
            .GetSection("PersonalInicial:Cuentas")
            .Get<CuentaInicial[]>()
            ?? [];

        if (cuentas.Length == 0)
        {
            throw new InvalidOperationException(
                "No hay cuentas en PersonalInicial:Cuentas.");
        }

        var correos = new HashSet<string>(
            StringComparer.OrdinalIgnoreCase);

        foreach (var cuenta in cuentas)
        {
            cuenta.Correo = cuenta.Correo.Trim();
            cuenta.Rol = cuenta.Rol.Trim();

            if (string.IsNullOrWhiteSpace(cuenta.Correo)
                || string.IsNullOrWhiteSpace(cuenta.Contrasenia))
            {
                throw new InvalidOperationException(
                    "Cada cuenta necesita correo y contraseña.");
            }

            if (!RolesPermitidos.Contains(cuenta.Rol))
            {
                throw new InvalidOperationException(
                    $"Rol no permitido: {cuenta.Rol}.");
            }

            if (!correos.Add(cuenta.Correo))
            {
                throw new InvalidOperationException(
                    "Hay correos repetidos en la configuración.");
            }
        }

        var db = services
            .GetRequiredService<ApplicationDbContext>();

        var usuarios = services
            .GetRequiredService<UserManager<IdentityUser>>();

        var roles = services
            .GetRequiredService<RoleManager<IdentityRole>>();

        await using var transaccion =
            await db.Database.BeginTransactionAsync();

        try
        {
            foreach (var nombreRol in RolesPermitidos)
            {
                if (!await roles.RoleExistsAsync(nombreRol))
                {
                    Verificar(
                        await roles.CreateAsync(
                            new IdentityRole(nombreRol)),
                        $"crear el rol {nombreRol}");
                }
            }

            foreach (var cuenta in cuentas)
            {
                var usuario =
                    await usuarios.FindByEmailAsync(cuenta.Correo);

                if (usuario is not null)
                {
                    // No modificar cuentas existentes automáticamente.
                    var tieneRol =
                        await usuarios.IsInRoleAsync(
                            usuario, cuenta.Rol);

                    if (!usuario.EmailConfirmed || !tieneRol)
                    {
                        throw new InvalidOperationException(
                            $"La cuenta {cuenta.Correo} ya existe, "
                            + "pero necesita revisión de confirmación "
                            + "o de rol. No se modificó automáticamente.");
                    }

                    continue;
                }

                usuario = new IdentityUser
                {
                    UserName = cuenta.Correo,
                    Email = cuenta.Correo,
                    EmailConfirmed = true
                };

                Verificar(
                    await usuarios.CreateAsync(
                        usuario, cuenta.Contrasenia),
                    $"crear la cuenta {cuenta.Correo}");

                Verificar(
                    await usuarios.AddToRoleAsync(
                        usuario, cuenta.Rol),
                    $"asignar el rol de {cuenta.Correo}");
            }

            await transaccion.CommitAsync();
        }
        catch
        {
            await transaccion.RollbackAsync();
            throw;
        }
    }

    private static void Verificar(
        IdentityResult resultado,
        string operacion)
    {
        if (resultado.Succeeded)
        {
            return;
        }

        var errores = string.Join(
            "; ",
            resultado.Errors.Select(error => error.Description));

        throw new InvalidOperationException(
            $"No se pudo {operacion}: {errores}");
    }

    public sealed class CuentaInicial
    {
        public string Correo { get; set; } = "";

        public string Contrasenia { get; set; } = "";

        public string Rol { get; set; } = "";
    }
}