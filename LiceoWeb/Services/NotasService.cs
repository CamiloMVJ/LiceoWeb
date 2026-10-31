using System.ComponentModel.DataAnnotations;
using LiceoWeb.Repositories;
using LiceoWeb.ViewModels;
namespace LiceoWeb.Services;
public sealed class NotasService(NotasRepository repository,UsuarioActual usuario)
{
 public Task GuardarAsync(NotasInput input)
 {Validator.ValidateObject(input,new ValidationContext(input),true);return repository.GuardarAsync(input,usuario.ObtenerId());}
}
