using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class ArancelInput:IValidatableObject
{
 public string Accion {get;set;}="Arancel";
 public int Id {get;set;}
 [StringLength(30)] public string? Codigo {get;set;}
 [StringLength(150)] public string? Nombre {get;set;}
 public int ArancelId {get;set;}
 public int ModalidadId {get;set;}
 public int AnioId {get;set;}
 public decimal? Importe {get;set;}
 public bool Activo {get;set;}=true;
 [StringLength(30)] public string? Origen {get;set;}
 [StringLength(500)] public string? Motivo {get;set;}
 [RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string? Version {get;set;}
 public static readonly string[] Origenes=["Matriculas","Mensualidades","Mantenimientos","EvBoTaS","Promociones"];
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(Accion is not ("Arancel" or "Tarifa" or "Mapeo" or "Preparar"))yield return new("Operación inválida.");
  if(Id<0)yield return new("Identificador inválido.");
  if(string.IsNullOrWhiteSpace(Motivo))yield return new("Indica el motivo de la operación.");
  if(Accion=="Arancel" && (string.IsNullOrWhiteSpace(Codigo)||string.IsNullOrWhiteSpace(Nombre)))yield return new("Código y nombre son obligatorios.");
  if(Accion=="Tarifa")
  {
   if(ArancelId<=0||ModalidadId<=0||AnioId<=0)yield return new("Selecciona arancel, modalidad y año.");
   if(Importe is null or <0 or >9999999999999999.99m || (Importe.HasValue && decimal.Round(Importe.Value,2)!=Importe))yield return new("Importe no negativo, con hasta dos decimales.");
  }
  if(Accion is "Arancel" or "Tarifa" && Id>0 && string.IsNullOrWhiteSpace(Version))yield return new("Recarga el registro antes de editar.");
  if(Accion=="Mapeo" && (ArancelId<=0 || !Origenes.Contains(Origen)))yield return new("Selecciona un origen permitido y un arancel.");
 }
}
