using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Data;

namespace LiceoWeb.Pages.Mensualidades
{
    [Authorize]
    public class CobrosMensualidadModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public CobrosMensualidadModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty(SupportsGet = true)]
        public string Busqueda { get; set; }

        [BindProperty(SupportsGet = true)]
        public string RegistroSeleccionado { get; set; }

        [BindProperty]
        public int AnioLimite { get; set; } = DateTime.Now.Year;

        [BindProperty]
        public int MesLimite { get; set; } = DateTime.Now.Month;

        [BindProperty]
        public int MontoRecibido { get; set; }

        [BindProperty]
        public string MetodoPago { get; set; } = "Efectivo";

        [BindProperty]
        public string ReferenciaTransaccion { get; set; }

        [BindProperty]
        public bool IntegrarSaldo { get; set; } = true;

        [BindProperty]
        public string Descripcion { get; set; } = "Pago de mensualidades escolares";

        // Datos para la vista
        public List<EstudianteBusquedaDto> ListaEstudiantes { get; set; } = new();
        public List<MensualidadPendienteDto> MensualidadesPendientes { get; set; } = new();
        public string NombreEstudianteActual { get; set; }
        public string ModalidadActual { get; set; }
        public string GradoActual { get; set; }
        public int SaldoFavorActual { get; set; }

        public string MensajeError { get; set; }
        public string MensajeExito { get; set; }
        public string ReciboGenerado { get; set; }

        public async Task OnGetAsync(string registro)
        {
            if (!string.IsNullOrEmpty(registro))
            {
                RegistroSeleccionado = registro;
                await CargarDatosEstudiante(registro);
            }
            else if (!string.IsNullOrEmpty(Busqueda))
            {
                await BuscarEstudiantes(Busqueda);
            }
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (string.IsNullOrEmpty(RegistroSeleccionado))
            {
                MensajeError = "Debe seleccionar un estudiante antes de procesar el pago.";
                return Page();
            }

            string connString = _configuration.GetConnectionString("DefaultConnection");

            try
            {
                using var conn = new SqlConnection(connString);
                using var cmd = new SqlCommand("Pagar_Mensualidad", conn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Registro", RegistroSeleccionado);
                cmd.Parameters.AddWithValue("@Monto", MontoRecibido);
                cmd.Parameters.AddWithValue("@Descripcion", Descripcion);
                cmd.Parameters.AddWithValue("@IntegrarSaldo", IntegrarSaldo ? 1 : 0);
                cmd.Parameters.AddWithValue("@Metodo_Pago", MetodoPago);
                cmd.Parameters.AddWithValue("@Referencia", string.IsNullOrEmpty(ReferenciaTransaccion) ? (object)DBNull.Value : ReferenciaTransaccion);
                cmd.Parameters.AddWithValue("@Anio_Limite", AnioLimite);
                cmd.Parameters.AddWithValue("@Numero_Mes_Limite", MesLimite);

                await conn.OpenAsync();
                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    ReciboGenerado = reader["IdRecibo"]?.ToString() ?? reader["IdComprobante"]?.ToString();
                    int cambio = reader["Cambio"] != DBNull.Value ? Convert.ToInt32(reader["Cambio"]) : 0;

                    MensajeExito = $"¡Pago procesado con éxito! Cambio a devolver: C$ {cambio:N2}.";
                }

                // Recargar datos actuales del alumno tras el pago
                await CargarDatosEstudiante(RegistroSeleccionado);
            }
            catch (Exception ex)
            {
                MensajeError = $"Error al procesar el pago: {ex.Message}";
                await CargarDatosEstudiante(RegistroSeleccionado);
            }

            return Page();
        }

        private async Task BuscarEstudiantes(string texto)
        {
            string connString = _configuration.GetConnectionString("DefaultConnection");
            using var conn = new SqlConnection(connString);
            using var cmd = new SqlCommand("Buscar_Estudiantes_Mensualidad", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@TextoBusqueda", texto);

            await conn.OpenAsync();
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                ListaEstudiantes.Add(new EstudianteBusquedaDto
                {
                    Registro = reader["Registro"].ToString(),
                    NombreEstudiante = reader["NombreEstudiante"].ToString(),
                    Grado = reader["Grado"].ToString()
                });
            }
        }

        private async Task CargarDatosEstudiante(string registro)
        {
            string connString = _configuration.GetConnectionString("DefaultConnection");
            using var conn = new SqlConnection(connString);
            using var cmd = new SqlCommand("Ver_Estado_Mensualidad_Cuenta", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@TextoBusqueda", registro);

            await conn.OpenAsync();
            using var reader = await cmd.ExecuteReaderAsync();

            bool datosCargados = false;
            while (await reader.ReadAsync())
            {
                if (!datosCargados)
                {
                    NombreEstudianteActual = reader["NombreEstudiante"].ToString();
                    ModalidadActual = reader["Modalidad"].ToString();
                    GradoActual = reader["Grado"].ToString();
                    SaldoFavorActual = reader["SaldoFavor"] != DBNull.Value ? Convert.ToInt32(reader["SaldoFavor"]) : 0;
                    datosCargados = true;
                }

                MensualidadesPendientes.Add(new MensualidadPendienteDto
                {
                    Anio = Convert.ToInt32(reader["Anio"]),
                    Mes = reader["Mes"].ToString(),
                    Costo_Mensualidad = Convert.ToInt32(reader["Costo_Mensualidad"]),
                    Estado = reader["Estado"].ToString()
                });
            }
        }
    }

    public class EstudianteBusquedaDto
    {
        public string Registro { get; set; }
        public string NombreEstudiante { get; set; }
        public string Grado { get; set; }
    }

    public class MensualidadPendienteDto
    {
        public int Anio { get; set; }
        public string Mes { get; set; }
        public int Costo_Mensualidad { get; set; }
        public string Estado { get; set; }
    }
}
