using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;

public sealed class TipoEvaluacionInput : IValidatableObject
{
    [Range(1, int.MaxValue)] public int Id { get; set; }
    [Required, StringLength(100)] public string Nombre { get; set; } = "";
    public bool Activo { get; set; }
    [Required, RegularExpression(@"\A0x[0-9A-Fa-f]{16}\z",
        ErrorMessage = "Recarga el tipo para obtener una versión válida.")]
    public string Version { get; set; } = "";
    public Guid Operacion { get; set; }
    [Required, StringLength(500, MinimumLength = 10)]
    public string Motivo { get; set; } = "";

    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (Operacion == Guid.Empty) yield return new("Recarga el formulario antes de guardar.", [nameof(Operacion)]);
        if (string.IsNullOrWhiteSpace(Nombre)) yield return new("Escribe el nombre.", [nameof(Nombre)]);
        if ((Motivo?.Trim().Length ?? 0) < 10)
            yield return new("Indica un motivo de al menos 10 caracteres.", [nameof(Motivo)]);
    }
}
