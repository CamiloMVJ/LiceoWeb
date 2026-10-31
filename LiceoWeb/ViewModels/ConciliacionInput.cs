using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class ConciliacionInput : IValidatableObject
{
 [Required,StringLength(30)] public string Origen {get;set;}="";
 [Range(1,int.MaxValue)] public int OrigenId {get;set;}
 public int TarifaId {get;set;}
 public string? Decision {get;set;}="";
 [Required,StringLength(500)] public string Motivo {get;set;}="";
 [Range(typeof(long),"0","9223372036854775807")] public long RevisionAnterior {get;set;}
 public bool Recapturar {get;set;}
 [Range(1,int.MaxValue)] public int GeneracionEsperada {get;set;}
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(!new[]{"Matriculas","Mensualidades","Mantenimientos","EvBoTaS","Promociones"}.Contains(Origen))yield return new("Origen inválido.");
  if(!Recapturar && TarifaId<=0)yield return new("Selecciona una tarifa.");
  if(!Recapturar && Decision is not ("Deuda" or "SinDeuda" or "Rechazada"))yield return new("Selecciona una decisión.");
  if(string.IsNullOrWhiteSpace(Motivo))yield return new("Explica el motivo de la revisión.");
 }
}
