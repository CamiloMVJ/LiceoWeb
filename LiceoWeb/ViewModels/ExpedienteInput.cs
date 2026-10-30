using System.ComponentModel.DataAnnotations;

namespace LiceoWeb.ViewModels;

public sealed class FamiliarInput
{
    [StringLength(200)] public string? Nombre { get; set; }
    [StringLength(300)] public string? Direccion { get; set; }
    [StringLength(200)] public string? CentroTrabajo { get; set; }
    [StringLength(30)] public string? Telefono { get; set; }
    [StringLength(50)] public string? Parentesco { get; set; }
}

public sealed class ExpedienteInput : IValidatableObject
{
    [StringLength(10)] public string? Registro { get; set; }
    public string? Version { get; set; }
    [Required, StringLength(100)] public string NombreEstudiante { get; set; } = "";
    [Required, RegularExpression("Preescolar|Primaria|Secundaria")] public string Modalidad { get; set; } = "";
    [Required, StringLength(50)] public string Grado { get; set; } = "";
    [Required, DataType(DataType.Date)] public DateOnly? FechaNacimiento { get; set; }
    [Required, RegularExpression("M|F")] public string Sexo { get; set; } = "";
    [Required, StringLength(200)] public string Direccion { get; set; } = "";
    [StringLength(50)] public string? Identificacion { get; set; }
    [RegularExpression("A\\+|A-|B\\+|B-|AB\\+|AB-|O\\+|O-")] public string? TipoSangre { get; set; }
    [StringLength(1000)] public string? Alergias { get; set; }
    [StringLength(1000)] public string? Padecimientos { get; set; }
    [StringLength(1000)] public string? IndicacionesEmergencia { get; set; }
    [Required, RegularExpression("Nuevo|Traslado")] public string TipoIngreso { get; set; } = "Nuevo";
    [StringLength(100)] public string? CodigoTraslado { get; set; }
    [StringLength(200)] public string? CentroProcedencia { get; set; }
    public FamiliarInput Padre { get; set; } = new();
    public FamiliarInput Madre { get; set; } = new();
    public FamiliarInput Otro { get; set; } = new();
    [Required, RegularExpression("Padre|Madre|Otro")] public string Tutor { get; set; } = "Madre";
    [Required, StringLength(500)] public string Motivo { get; set; } = "Registro inicial";
    [StringLength(200)] public string? DocumentoTutela { get; set; }
    public bool PartidaRecibida { get; set; }
    public bool IdentificacionTutorRecibida { get; set; }
    public bool BoletinRecibido { get; set; }
    public bool TrasladoRecibido { get; set; }
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        var hoy = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTimeOffset.UtcNow, "Central America Standard Time").DateTime);
        if (FechaNacimiento is { } fecha && (fecha > hoy || fecha < hoy.AddYears(-100)))
            yield return new("Revisa la fecha de nacimiento.", [nameof(FechaNacimiento)]);
        if (TipoIngreso == "Traslado" && (string.IsNullOrWhiteSpace(CodigoTraslado) || string.IsNullOrWhiteSpace(CentroProcedencia)))
            yield return new("Indica el código y centro de procedencia del traslado.", [nameof(CodigoTraslado)]);
        var tutor = Tutor == "Padre" ? Padre : Tutor == "Madre" ? Madre : Otro;
        if (string.IsNullOrWhiteSpace(tutor.Nombre) || string.IsNullOrWhiteSpace(tutor.Telefono))
            yield return new("El tutor legal requiere nombre y teléfono.", [nameof(Tutor)]);
        if (Tutor == "Otro" && string.IsNullOrWhiteSpace(Otro.Parentesco))
            yield return new("Indica el parentesco del tutor.", [nameof(Otro)]);
    }
}
