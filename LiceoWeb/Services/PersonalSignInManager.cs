using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
namespace LiceoWeb.Services;

// Mantiene la validación estándar de Identity y añade la baja administrativa.
// No se usa LockoutEnd: un restablecimiento de contraseña no debe reactivar cuentas.
public sealed class PersonalSignInManager(
    UserManager<IdentityUser> users, IHttpContextAccessor context,
    IUserClaimsPrincipalFactory<IdentityUser> claims, IOptions<IdentityOptions> options,
    ILogger<SignInManager<IdentityUser>> logger, IAuthenticationSchemeProvider schemes,
    IUserConfirmation<IdentityUser> confirmation, IEstadoCuentaPersonal estado)
    : SignInManager<IdentityUser>(users, context, claims, options, logger, schemes, confirmation)
{
    public override async Task<bool> CanSignInAsync(IdentityUser user) =>
        await base.CanSignInAsync(user) && await estado.EstaActivaAsync(user.Id);

    // La sobrecarga central también se usa al validar cookies de segundo factor.
    public override async Task<bool> ValidateSecurityStampAsync(IdentityUser? user, string? securityStamp) =>
        user is not null && await base.ValidateSecurityStampAsync(user, securityStamp)
        && await estado.EstaActivaAsync(user.Id);
}
