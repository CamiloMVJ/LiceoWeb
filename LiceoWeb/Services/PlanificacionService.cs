using System.ComponentModel.DataAnnotations;
using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Services;
public sealed class PlanificacionService(PlanificacionRepository repository,UsuarioActual usuario)
{
 public Task GuardarCatalogoAsync(CatalogoInput input){Validator.ValidateObject(input,new ValidationContext(input),true);return repository.GuardarAsync("dbo.CatalogoAcademico_Guardar",input,usuario.ObtenerId());}
 public Task GuardarPlanAsync(PlanificacionInput input){Validator.ValidateObject(input,new ValidationContext(input),true);return repository.GuardarAsync("dbo.Planificacion_Guardar",input,usuario.ObtenerId());}
}
