using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class EditarEvaluacionInput : IValidatableObject
{
 [Range(1,int.MaxValue)] public int Id {get;set;}
 [Range(1,int.MaxValue)] public int TipoId {get;set;}
 [Required,StringLength(100)] public string Nombre {get;set;}="";
 [Required] public DateOnly? Fecha {get;set;}
 [Required,RegularExpression("^(Cuantitativa|Cualitativa)$")] public string Modo {get;set;}="Cuantitativa";
 public decimal Maximo {get;set;}=100;
 public decimal Peso {get;set;}
 [StringLength(2000)] public string? Opciones {get;set;}
 [Required,RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string Version {get;set;}="";
 public Guid Operacion {get;set;}
 [Required,StringLength(500,MinimumLength=10)] public string Motivo {get;set;}="";
 public string[] Valores()=>(Opciones??"").Split('\n',StringSplitOptions.TrimEntries|StringSplitOptions.RemoveEmptyEntries);
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Operacion==Guid.Empty)yield return new("Recarga la página para identificar la operación.");
  if(string.IsNullOrWhiteSpace(Motivo)||Motivo.Trim().Length<10)yield return new("Explica el motivo con al menos 10 caracteres.");
  var definition=new NotasInput{AsignacionId=1,TipoId=TipoId,Nombre=Nombre,Fecha=Fecha,Modo=Modo,Maximo=Maximo,Peso=Peso,Opciones=Opciones};
  foreach(var result in definition.Validate(new ValidationContext(definition)))yield return result;
 }
}
