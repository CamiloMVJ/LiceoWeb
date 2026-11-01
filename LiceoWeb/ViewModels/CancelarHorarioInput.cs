using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class CancelarHorarioInput : IValidatableObject
{
 [Range(1,int.MaxValue)] public int HorarioId {get;set;}
 [Required,RegularExpression(@"^0x[0-9A-Fa-f]{16}$")] public string Version {get;set;}="";
 public Guid Operacion {get;set;}
 [Required,StringLength(500,MinimumLength=10)] public string Motivo {get;set;}="";
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Operacion==Guid.Empty) yield return new("Falta identificar la operación. Recarga la página.",[nameof(Operacion)]);
  if(string.IsNullOrWhiteSpace(Motivo) || Motivo.Trim().Length<10)
   yield return new("Explica el motivo con al menos 10 caracteres.",[nameof(Motivo)]);
 }
}
