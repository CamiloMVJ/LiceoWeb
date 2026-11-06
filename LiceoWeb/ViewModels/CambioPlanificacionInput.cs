using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class CambioPlanificacionInput : IValidatableObject
{
 [Required,RegularExpression("^(Docente|Estudiante)$")] public string Tipo {get;set;}="Docente";
 [Range(1,int.MaxValue)] public int OrigenId {get;set;}
 [StringLength(10),RegularExpression(@"^E_[0-9]{7}$")] public string? Registro {get;set;}
 [StringLength(450)] public string? DocenteId {get;set;}
 public int? GrupoDestino {get;set;}
 [Required(ErrorMessage="Falta la versión del registro. Vuelve a abrir el formulario."),RegularExpression(@"^0x[0-9A-Fa-f]{16}$", ErrorMessage="La versión del registro no es válida. Vuelve a abrir el formulario.")] public string Version {get;set;}="";
 public Guid Operacion {get;set;}
 [Required,StringLength(500,MinimumLength=10)] public string Motivo {get;set;}="";
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Operacion==Guid.Empty)yield return new("Falta identificar la operación. Recarga la página.",[nameof(Operacion)]);
  if(string.IsNullOrWhiteSpace(Motivo)||Motivo.Trim().Length<10)yield return new("Explica el motivo con al menos 10 caracteres.",[nameof(Motivo)]);
  if(Tipo=="Docente" && (string.IsNullOrWhiteSpace(DocenteId)||Registro is not null||GrupoDestino is not null))yield return new("Selecciona el docente de destino y no envíes datos de traslado.",[nameof(DocenteId)]);
  if(Tipo=="Estudiante" && (string.IsNullOrWhiteSpace(Registro)||GrupoDestino is null or <=0||DocenteId is not null))yield return new("Selecciona el grupo de destino y un estudiante válido.",[nameof(GrupoDestino)]);
  if(Tipo=="Estudiante" && GrupoDestino==OrigenId)yield return new("Selecciona un grupo diferente al de origen.",[nameof(GrupoDestino)]);
 }
}
