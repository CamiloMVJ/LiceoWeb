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
 public int GrupoId {get;set;}
 [StringLength(450)] public string? DocenteId {get;set;}
 public int AsignacionId {get;set;}
 public int HorarioId {get;set;}
 [RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string? VersionHorario {get;set;}
 [StringLength(500)] public string? MotivoHorario {get;set;}
 public int Dia {get;set;}
 [DataType(DataType.Time)] public TimeOnly? Inicio {get;set;}
 [DataType(DataType.Time)] public TimeOnly? Fin {get;set;}
 [StringLength(10)] public string? Registro {get;set;}
 // El contexto lo resuelve el servidor después de que MVC recibe el formulario.
 public IEnumerable<ValidationResult> ValidarContexto()
 {
  if(Accion=="Pensum" && AnioId<=0)
   yield return new("Selecciona un año lectivo activo arriba.", [nameof(AnioId)]);
  if(Accion is "Materia" or "Grupo" && PensumId<=0)
   yield return new("Selecciona el plan de estudios arriba.", [nameof(PensumId)]);
  if(Accion is "Docente" or "Estudiante" && GrupoId<=0)
   yield return new("Selecciona el grupo arriba.", [nameof(GrupoId)]);
 }
 public IEnumerable<ValidationResult> Validate(ValidationContext context)
 {
  ValidationResult Falta(string campo,string mensaje) => new(mensaje,[campo]);
  switch(Accion)
  {
   case "Pensum":
    if(ModalidadId<=0)yield return Falta(nameof(ModalidadId),"Selecciona una modalidad.");
    if(string.IsNullOrWhiteSpace(Nivel))yield return Falta(nameof(Nivel),"Selecciona un grado o nivel.");
    break;
   case "Materia":
   case "Grupo":
    if(Accion=="Materia" && AsignaturaId<=0)yield return Falta(nameof(AsignaturaId),"Selecciona una asignatura.");
    if(Accion=="Grupo")
    {
     if(PeriodoId<=0)yield return Falta(nameof(PeriodoId),"Selecciona un período.");
     if(TurnoId<=0)yield return Falta(nameof(TurnoId),"Selecciona un turno.");
     if(AulaId<=0)yield return Falta(nameof(AulaId),"Selecciona un aula.");
    }
    break;
   case "Docente":
   case "Estudiante":
    if(Accion=="Docente")
    {
     if(AsignaturaId<=0)yield return Falta(nameof(AsignaturaId),"Selecciona una asignatura.");
     if(string.IsNullOrWhiteSpace(DocenteId))yield return Falta(nameof(DocenteId),"Selecciona un docente.");
    }
    else if(string.IsNullOrWhiteSpace(Registro))yield return Falta(nameof(Registro),"Selecciona un estudiante.");
    break;
   case "Horario":
    if(HorarioId<0 || (HorarioId>0 && string.IsNullOrEmpty(VersionHorario)))
     yield return Falta(nameof(HorarioId),"Recarga el bloque antes de reprogramarlo.");
    if(HorarioId>0 && (MotivoHorario?.Trim().Length ?? 0)<10)
     yield return Falta(nameof(MotivoHorario),"Indica un motivo de al menos 10 caracteres.");
    if(AsignacionId<=0)yield return Falta(nameof(AsignacionId),"Selecciona una clase.");
    if(Dia is <1 or >7)yield return Falta(nameof(Dia),"Selecciona un día.");
    if(Inicio is null)yield return Falta(nameof(Inicio),"Indica la hora de inicio.");
    if(Fin is null || (Inicio is not null && Fin<=Inicio))yield return Falta(nameof(Fin),"Indica una hora de fin posterior al inicio.");
    break;
   default: yield return Falta(nameof(Accion),"Operación académica inválida."); break;
  }
 }
}
