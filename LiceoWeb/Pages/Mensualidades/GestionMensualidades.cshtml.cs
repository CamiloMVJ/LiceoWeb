using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LiceoWeb.Pages.Mensualidades
{
    [Authorize]
    public class GestionMensualidadesModel : PageModel
    {
        // Filtros de búsqueda para la vista
        public string FiltroNombre { get; set; } = "";
        public int FiltroAnio { get; set; } = DateTime.Now.Year;
        public string FiltroModalidad { get; set; } = "Todos";
        public string FiltroEstado { get; set; } = "Todos";

        // Listas vacías en modo diseño (no darán errores de SQL)
        public List<MensualidadFiltroDto> ListaMensualidades { get; set; } = new();
        public List<MoraDto> ListaMora { get; set; } = new();
        public List<SaldoDto> ListaSaldos { get; set; } = new();

        public async Task OnGetAsync(string filtroNombre, int? filtroAnio, string filtroModalidad, string filtroEstado)
        {
            // Asignar los valores de los filtros si el usuario busca algo
            if (!string.IsNullOrEmpty(filtroNombre)) FiltroNombre = filtroNombre;
            if (filtroAnio.HasValue) FiltroAnio = filtroAnio.Value;
            if (!string.IsNullOrEmpty(filtroModalidad)) FiltroModalidad = filtroModalidad;
            if (!string.IsNullOrEmpty(filtroEstado)) FiltroEstado = filtroEstado;

            // Simulamos que cargó rápido sin llamar a la base de datos por ahora
            await Task.CompletedTask;
        }
    }

    // --- Clases auxiliares para que la tabla no marque error en el HTML ---

    public class MensualidadFiltroDto
    {
        public string Registro { get; set; }
        public string NombreEstudiante { get; set; }
        public string Grado { get; set; }
        public string Modalidad { get; set; }
        public int Anio { get; set; }
        public string Mes { get; set; }
        public int Monto { get; set; }
        public string Estado { get; set; }
    }

    public class MoraDto
    {
        public string Registro { get; set; }
        public string NombreEstudiante { get; set; }
        public string Modalidad { get; set; }
        public string Mes { get; set; }
        public int Anio { get; set; }
        public int Costo_Mensualidad { get; set; }
    }

    public class SaldoDto
    {
        public string Registro { get; set; }
        public string Estudiante { get; set; }
        public string Modalidad { get; set; }
        public string Grado { get; set; }
        public int SaldoAFavor { get; set; }
    }
}