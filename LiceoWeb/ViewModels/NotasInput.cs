using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class NotasInput : IValidatableObject
{
 public string Accion {get;set;}="Evaluacion";
 public int AsignacionId {get;set;}
 public int EvaluacionId {get;set;}
 public int TipoId {get;set;}
 [StringLength(100)] public string? Nombre {get;set;}
 public DateOnly? Fecha {get;set;}
 public string Modo {get;set;}="Cuantitativa";
 public decimal Maximo {get;set;}=100;
 public decimal Peso {get;set;}
 [StringLength(2000)] public string? Opciones {get;set;}
 [StringLength(10)] public string? Registro {get;set;}
 public decimal? Nota {get;set;}
 [StringLength(100)] public string? Resultado {get;set;}
 [StringLength(500)] public string? Observacion {get;set;}
 [RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string? Version {get;set;}
 [StringLength(500)] public string? Motivo {get;set;}
 public string[] Valores()=> (Opciones??"").Split('\n',StringSplitOptions.TrimEntries|StringSplitOptions.RemoveEmptyEntries);
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Accion is not ("Tipo" or "Evaluacion" or "Nota" or "Publicar"))yield return new("Operación inválida.");
  if(Accion!="Tipo" && AsignacionId<=0)yield return new("Selecciona una asignación.");
  if(Accion is "Tipo" or "Evaluacion" && string.IsNullOrWhiteSpace(Nombre))yield return new("Escribe el nombre.");
  if(Accion=="Evaluacion")
  {
   if(TipoId<=0 || Fecha is null)yield return new("Selecciona tipo y fecha de evaluación.");
   if(Modo is not ("Cuantitativa" or "Cualitativa"))yield return new("Modalidad de evaluación inválida.");
   if(Modo=="Cuantitativa" && (Maximo<=0 || Maximo>99999.99m || Peso<=0 || Peso>100 || decimal.Round(Maximo,2)!=Maximo || decimal.Round(Peso,2)!=Peso))yield return new("Máximo y peso deben ser positivos, con hasta dos decimales; peso máximo 100 %.");
   if(Modo=="Cualitativa" && (Valores().Length<2 || Valores().Length>20 || Valores().Any(x=>x.Length>100) || Valores().Distinct(StringComparer.OrdinalIgnoreCase).Count()!=Valores().Length))yield return new("Define entre 2 y 20 resultados diferentes, uno por línea, de hasta 100 caracteres.");
  }
  if(Accion=="Nota")
  {
   if(!string.IsNullOrEmpty(Version) && string.IsNullOrWhiteSpace(Motivo))yield return new("Indica el motivo de la modificación.");
   if(EvaluacionId<=0 || string.IsNullOrWhiteSpace(Registro))yield return new("Selecciona evaluación y estudiante.");
   if(Nota is <0 or >99999.99m || (Nota.HasValue && decimal.Round(Nota.Value,2)!=Nota.Value))yield return new("Nota inválida: usa un valor positivo o cero con hasta dos decimales.");
   if(Nota.HasValue && !string.IsNullOrWhiteSpace(Resultado))yield return new("No combines nota numérica con resultado cualitativo.");
  }
 }
}
