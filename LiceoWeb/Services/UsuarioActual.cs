using Microsoft.AspNetCore.Identity;

namespace LiceoWeb.Services

{
    public sealed class UsuarioActual
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly UserManager<IdentityUser> _usuarios;

        public UsuarioActual(
            IHttpContextAccessor httpContextAccessor,
            UserManager<IdentityUser> usuarios)
        {
            _httpContextAccessor = httpContextAccessor;
            _usuarios = usuarios;
        }

        public string ObtenerId()
        {
            var usuario = _httpContextAccessor.HttpContext?.User;

            if (usuario?.Identity?.IsAuthenticated != true)
            {
                throw new UnauthorizedAccessException(
                    "La operación requiere una sesión autenticada.");
            }

            return _usuarios.GetUserId(usuario)
                ?? throw new UnauthorizedAccessException(
                    "La sesión no contiene un identificador de usuario.");
        }
    }
}
