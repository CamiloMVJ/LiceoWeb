using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class CierreAcademicoInput:IValidatableObject
{
 [Required] public string Accion {get;set;}="CerrarPeriodo";
 [Range(1,int.MaxValue)] public int PeriodoId {get;set;}
 public int AsignacionId {get;set;}
 [Required,RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string Version {get;set;}="";
 [Required,StringLength(500)] public string Motivo {get;set;}="";
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Accion is not ("CerrarPeriodo" or "ReabrirPeriodo" or "ReabrirAsignacion"))yield return new("Operación no permitida.");
  if(Accion=="ReabrirAsignacion" && AsignacionId<=0)yield return new("Selecciona una asignatura publicada.");
  if(string.IsNullOrWhiteSpace(Motivo))yield return new("Indica el motivo.");
 }
}
