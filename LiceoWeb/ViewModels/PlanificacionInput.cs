using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;
public sealed class CatalogoInput : IValidatableObject
{
 [Required] public string Tipo {get;set;}="Anios";
 public int Id {get;set;}
 public bool SoloEstado {get;set;}
 [StringLength(100)] public string? Nombre {get;set;}
 [StringLength(30)] public string? Codigo {get;set;}
 [StringLength(200)] public string? Ubicacion {get;set;}
 public int? Anio {get;set;}
 public int? AnioId {get;set;}
 public int? Capacidad {get;set;}
 [DataType(DataType.Date)] public DateOnly? Inicio {get;set;}
 [DataType(DataType.Date)] public DateOnly? Fin {get;set;}
 public bool Activo {get;set;}=true;
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  if(!new[]{"Anios","Periodos","Modalidades","Turnos","Aulas","Asignaturas"}.Contains(Tipo)) yield return new("Catálogo inválido.");
  if(Id<0)yield return new("Identificador inválido.");
  if(SoloEstado){if(Id<=0 || Tipo=="Periodos")yield return new("Cambio de estado inválido.");yield break;}
  if(Tipo=="Anios" && Anio is not (>=1900 and <=9999))yield return new("Año inválido.");
  if(Tipo!="Anios" && string.IsNullOrWhiteSpace(Nombre))yield return new("Indica un nombre.");
  if(Tipo is "Periodos" or "Modalidades" or "Turnos" or "Aulas" && Nombre?.Length>80)yield return new("El nombre admite hasta 80 caracteres.");
  if(Tipo=="Periodos" && (AnioId is not >0 || Inicio is null || Fin is null || Fin<Inicio))yield return new("Revisa año y fechas del período.");
  if(Tipo=="Aulas" && (Capacidad is not >0 || string.IsNullOrWhiteSpace(Ubicacion)))yield return new("Indica capacidad y ubicación del aula.");
  if(Tipo=="Asignaturas" && string.IsNullOrWhiteSpace(Codigo))yield return new("Indica el código de asignatura.");
 }
}
public sealed class PlanificacionInput : IValidatableObject
{
 [Required] public string Accion {get;set;}="Pensum";
 public int AnioId {get;set;}
 public int ModalidadId {get;set;}
 [StringLength(50)] public string? Nivel {get;set;}
 public int PensumId {get;set;}
 public int AsignaturaId {get;set;}
 public int PeriodoId {get;set;}
 public int TurnoId {get;set;}
 public int AulaId {get;set;}
 [StringLength(30)] public string? Seccion {get;set;}
 public int GrupoId {get;set;}
 [StringLength(450)] public string? DocenteId {get;set;}
 public int AsignacionId {get;set;}
 public int Dia {get;set;}
 [DataType(DataType.Time)] public TimeOnly? Inicio {get;set;}
 [DataType(DataType.Time)] public TimeOnly? Fin {get;set;}
 [StringLength(10)] public string? Registro {get;set;}
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  bool valido=Accion switch {
   "Pensum"=>AnioId>0 && ModalidadId>0 && !string.IsNullOrWhiteSpace(Nivel),
   "Materia"=>PensumId>0 && AsignaturaId>0,
   "Grupo"=>PensumId>0 && PeriodoId>0 && TurnoId>0 && AulaId>0 && !string.IsNullOrWhiteSpace(Seccion),
   "Docente"=>GrupoId>0 && AsignaturaId>0 && !string.IsNullOrWhiteSpace(DocenteId),
   "Horario"=>AsignacionId>0 && Dia>=1 && Dia<=7 && Inicio is not null && Fin is not null && Fin>Inicio,
   "Estudiante"=>GrupoId>0 && !string.IsNullOrWhiteSpace(Registro),
   _=>false
  };
  if(!valido)yield return new("Completa los datos de la operación seleccionada.");
 }
}
