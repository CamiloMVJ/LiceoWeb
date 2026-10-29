namespace LiceoWeb.ViewModels;

public sealed class EstudianteListadoViewModel
{
    public string Registro { get; set; } = "";

    public string NombreEstudiante { get; set; } = "";

    public string Modalidad { get; set; } = "";

    public string Grado { get; set; } = "";

    public bool Activo { get; set; }
}