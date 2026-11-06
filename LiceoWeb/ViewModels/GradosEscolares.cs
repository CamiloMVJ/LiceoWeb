namespace LiceoWeb.ViewModels;

public static class GradosEscolares
{
    public static IReadOnlyList<(string Nombre, string Modalidad)> Opciones { get; } =
        Array.AsReadOnly<(string, string)>(
        [
            ("I Nivel", "Preescolar"), ("II Nivel", "Preescolar"), ("III Nivel", "Preescolar"),
            ("1er Grado", "Primaria"), ("2do Grado", "Primaria"), ("3er Grado", "Primaria"),
            ("4to Grado", "Primaria"), ("5to Grado", "Primaria"), ("6to Grado", "Primaria"),
            ("7mo Grado", "Secundaria"), ("8vo Grado", "Secundaria"), ("9no Grado", "Secundaria"),
            ("10mo Grado", "Secundaria"), ("11mo Grado", "Secundaria")
        ]);

    public static string? ModalidadDe(string? grado) =>
        Opciones.FirstOrDefault(opcion => opcion.Nombre == grado).Modalidad;
}
