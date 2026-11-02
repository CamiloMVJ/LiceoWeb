using System.ComponentModel.DataAnnotations;
namespace LiceoWeb.ViewModels;

public sealed class PersonalInput : IValidatableObject
{
    public static readonly string[] Roles = ["Administrador", "Profesor", "Cajero"];
    [Required, StringLength(450)] public string CuentaId { get; set; } = "";
    [Required, StringLength(128)] public string Version { get; set; } = "";
    [Required] public string Rol { get; set; } = "";
    public bool Activa { get; set; }
    public Guid Operacion { get; set; } = Guid.NewGuid();
    [Required, StringLength(500, MinimumLength = 10)] public string Motivo { get; set; } = "";
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (!Roles.Contains(Rol)) yield return new("Rol no permitido.", [nameof(Rol)]);
        if (Operacion == Guid.Empty) yield return new("Identificador de operación requerido.", [nameof(Operacion)]);
        if ((Motivo ?? "").Trim().Length < 10) yield return new("Explique el motivo en al menos 10 caracteres.", [nameof(Motivo)]);
    }
}
