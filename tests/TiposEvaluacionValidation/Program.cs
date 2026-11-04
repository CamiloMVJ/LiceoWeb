using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;

static TipoEvaluacionInput Valido() => new()
{
    Id = 1, Nombre = "Examen", Activo = true,
    Version = "0x0000000000000001", Operacion = Guid.NewGuid(),
    Motivo = "Ajuste del catálogo académico"
};
static bool Validar(TipoEvaluacionInput input) =>
    Validator.TryValidateObject(input, new ValidationContext(input), new List<ValidationResult>(), true);

var casos = new (string Nombre, Action<TipoEvaluacionInput> Cambiar, bool Esperado)[]
{
    ("Entrada válida", _ => { }, true),
    ("Inactivación válida", x => x.Activo = false, true),
    ("Id requerido", x => x.Id = 0, false),
    ("Nombre vacío", x => x.Nombre = "", false),
    ("Nombre en blanco", x => x.Nombre = "   ", false),
    ("Nombre largo", x => x.Nombre = new string('a', 101), false),
    ("Versión ausente", x => x.Version = "", false),
    ("Versión corta", x => x.Version = "0x01", false),
    ("Versión no hexadecimal", x => x.Version = "0x000000000000000Z", false),
    ("Versión con salto final", x => x.Version += "\n", false),
    ("Operación vacía", x => x.Operacion = Guid.Empty, false),
    ("Motivo corto", x => x.Motivo = "Cambio", false),
    ("Motivo con espacios", x => x.Motivo = "          a", false),
    ("Motivo largo", x => x.Motivo = new string('a', 501), false),
    ("Hexadecimal en mayúsculas", x => x.Version = "0xABCDEF0123456789", true)
};
foreach (var caso in casos)
{
    var input = Valido(); caso.Cambiar(input);
    if (Validar(input) != caso.Esperado) throw new Exception(caso.Nombre);
    Console.WriteLine("OK: " + caso.Nombre);
}
Console.WriteLine($"{casos.Length} pruebas aprobadas.");
