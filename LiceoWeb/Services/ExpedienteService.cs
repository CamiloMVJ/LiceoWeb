using System.ComponentModel.DataAnnotations;
using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Services;
public sealed class ExpedienteService(ExpedienteRepository repository, UsuarioActual usuario)
{
    public async Task<string> GuardarAsync(ExpedienteInput input)
    {
        Validator.ValidateObject(input,new ValidationContext(input),true);
        foreach(var familiar in new[]{input.Padre,input.Madre,input.Otro})
            Validator.ValidateObject(familiar,new ValidationContext(familiar),true);
        return await repository.GuardarAsync(input,usuario.ObtenerId());
    }
}
