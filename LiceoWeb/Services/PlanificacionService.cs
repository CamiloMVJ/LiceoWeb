using System.ComponentModel.DataAnnotations;
using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Services;
public sealed class PlanificacionService(PlanificacionRepository repository,UsuarioActual usuario)
{
 public Task<int> GuardarCatalogoAsync(CatalogoInput input){Validator.ValidateObject(input,new ValidationContext(input),true);return repository.GuardarAsync("dbo.CatalogoAcademico_Guardar",input,usuario.ObtenerId());}
 public Task<int> GuardarPlanAsync(PlanificacionInput input){Validator.ValidateObject(input,new ValidationContext(input),true);if(input.ValidarContexto().FirstOrDefault() is { } error)throw new ValidationException(error,null,input);return repository.GuardarAsync("dbo.Planificacion_Guardar",input,usuario.ObtenerId());}
}
