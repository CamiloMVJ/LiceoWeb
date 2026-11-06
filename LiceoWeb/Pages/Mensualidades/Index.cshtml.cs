using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Data;

namespace LiceoWeb.Pages.Mensualidades
{
    [Authorize(Policy = "OperarSistema")]
    public class CobrosMensualidadModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public CobrosMensualidadModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty(SupportsGet = true)]
        public string? Busqueda { get; set; }

        [BindProperty(SupportsGet = true)]
        public string? RegistroSeleccionado { get; set; }

        [BindProperty]
        public int AnioLimite { get; set; } = DateTime.Now.Year;

        [BindProperty]
        public int MesLimite { get; set; } = DateTime.Now.Month;

        [BindProperty]
        public decimal MontoRecibido { get; set; }

        [BindProperty]
        public string MetodoPago { get; set; } = "Efectivo";

        [BindProperty]
        public string? ReferenciaTransaccion { get; set; }

        [BindProperty]
        public bool IntegrarSaldo { get; set; } = true;

        [BindProperty]
        public string Descripcion { get; set; } = "Pago de mensualidades escolares";

        [BindProperty]
        public Guid Operacion { get; set; }

        // Datos para la vista
        public List<EstudianteBusquedaDto> ListaEstudiantes { get; set; } = new();
        public List<MensualidadPendienteDto> MensualidadesPendientes { get; set; } = new();
        public string NombreEstudianteActual { get; set; } = "";
        public string ModalidadActual { get; set; } = "";
        public string GradoActual { get; set; } = "";
        public decimal SaldoFavorActual { get; set; }

        public string? MensajeError { get; set; }
        public string? MensajeExito { get; set; }
        public string? ReciboGenerado { get; set; }

        public async Task OnGetAsync(string? registro)
        {
            Operacion = Guid.NewGuid();
            try
            {
                if (!string.IsNullOrEmpty(registro) && registro.Length <= 10)
                {
                    RegistroSeleccionado = registro;
                    await CargarDatosEstudiante(registro);
                    if (string.IsNullOrEmpty(NombreEstudianteActual))
                    {
                        RegistroSeleccionado = null;
                        MensajeError = "No se encontró un estudiante activo con ese registro.";
                    }
                }
                else if (!string.IsNullOrEmpty(Busqueda) && Busqueda.Length <= 100)
                {
                    await BuscarEstudiantes(Busqueda);
                }
            }
            catch (SqlException ex)
            {
                RegistroSeleccionado = null;
                MensajeError = $"No se pudo consultar mensualidades (SQL {ex.Number}).";
            }
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (string.IsNullOrEmpty(RegistroSeleccionado))
            {
                MensajeError = "Debe seleccionar un estudiante antes de procesar el pago.";
                return Page();
            }

            if (!ModelState.IsValid || Operacion == Guid.Empty || RegistroSeleccionado.Length > 10
                || ReferenciaTransaccion?.Length > 100 || Descripcion.Length > 100
                || MontoRecibido is < 0 or > 9999999999999999.99m
                || decimal.Round(MontoRecibido, 2) != MontoRecibido)
            {
                MensajeError = "Revisa los datos del pago y usa hasta dos decimales.";
                return Page();
            }
            var usuarioId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (usuarioId is null) return Forbid();

            var connString = _configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Falta configurar la conexión DefaultConnection.");

            try
            {
                using var conn = new SqlConnection(connString);
                using var cmd = new SqlCommand("Pagar_Mensualidad", conn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.AddWithValue("@Registro", RegistroSeleccionado);
                var monto = cmd.Parameters.Add("@Monto", SqlDbType.Decimal);
                monto.Precision = 18; monto.Scale = 2; monto.Value = MontoRecibido;
                cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuarioId;
                cmd.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = Operacion;
                cmd.Parameters.AddWithValue("@Descripcion", Descripcion);
                cmd.Parameters.AddWithValue("@IntegrarSaldo", IntegrarSaldo ? 1 : 0);
                cmd.Parameters.AddWithValue("@Metodo_Pago", MetodoPago);
                cmd.Parameters.AddWithValue("@Referencia", string.IsNullOrEmpty(ReferenciaTransaccion) ? (object)DBNull.Value : ReferenciaTransaccion);
                cmd.Parameters.AddWithValue("@Anio_Limite", AnioLimite);
                cmd.Parameters.AddWithValue("@Numero_Mes_Limite", MesLimite);

                await conn.OpenAsync();
                await using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    ReciboGenerado = reader["IdRecibo"]?.ToString() ?? reader["IdComprobante"]?.ToString();
                    decimal cambio = reader["Cambio"] != DBNull.Value ? Convert.ToDecimal(reader["Cambio"]) : 0;

                    MensajeExito = $"¡Pago procesado con éxito! Cambio a devolver: C$ {cambio:N2}.";
                }

                await reader.DisposeAsync();
                // Recargar datos actuales del alumno tras el pago
                await CargarDatosEstudiante(RegistroSeleccionado);
            }
            catch (SqlException ex)
            {
                MensajeError = MensajeExito is not null
                    ? "El pago quedó registrado, pero no se pudo recargar la cuenta. No lo repitas."
                    : ex.Number is >=53920 and <=53923 ? ex.Message
                    : $"No se pudo confirmar el resultado del pago (SQL {ex.Number}). Consulta la cuenta antes de reintentar.";
            }

            return Page();
        }

        private async Task BuscarEstudiantes(string texto)
        {
            var connString = _configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Falta configurar la conexión DefaultConnection.");
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
                    Registro = reader["Registro"].ToString() ?? "",
                    NombreEstudiante = reader["NombreEstudiante"].ToString() ?? "",
                    Grado = reader["Grado"].ToString() ?? ""
                });
            }
        }

        private async Task CargarDatosEstudiante(string registro)
        {
            var connString = _configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Falta configurar la conexión DefaultConnection.");
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
                    NombreEstudianteActual = reader["NombreEstudiante"].ToString() ?? "";
                    ModalidadActual = reader["Modalidad"].ToString() ?? "";
                    GradoActual = reader["Grado"].ToString() ?? "";
                    SaldoFavorActual = reader["SaldoFavor"] != DBNull.Value ? Convert.ToDecimal(reader["SaldoFavor"]) : 0;
                    datosCargados = true;
                }

                if (reader["Anio"] is DBNull) continue;
                MensualidadesPendientes.Add(new MensualidadPendienteDto
                {
                    Anio = Convert.ToInt32(reader["Anio"]),
                    Mes = reader["Mes"].ToString() ?? "",
                    Costo_Mensualidad = Convert.ToDecimal(reader["Costo_Mensualidad"]),
                    Estado = reader["Estado"].ToString() ?? ""
                });
            }
        }
    }

    public class EstudianteBusquedaDto
    {
        public string Registro { get; set; } = "";
        public string NombreEstudiante { get; set; } = "";
        public string Grado { get; set; } = "";
    }

    public class MensualidadPendienteDto
    {
        public int Anio { get; set; }
        public string Mes { get; set; } = "";
        public decimal Costo_Mensualidad { get; set; }
        public string Estado { get; set; } = "";
    }
}
