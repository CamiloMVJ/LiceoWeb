using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Text.Json;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy = "GestionFinanciera")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class CuentaModel(SqlConnectionFactory factory, UsuarioActual usuario, ILogger<CuentaModel> logger) : PageModel
{
    public sealed class AplicacionInput
    {
        public long CargoId { get; set; }
        public decimal Importe { get; set; }
    }
    public sealed class CobroInput : IValidatableObject
    {
        [Required, StringLength(10)] public string Registro { get; set; } = "";
        public Guid Operacion { get; set; }
        [Required, StringLength(200)] public string Pagador { get; set; } = "";
        [Required, RegularExpression("^(Efectivo|Transferencia|Saldo)$")] public string Metodo { get; set; } = "Efectivo";
        [StringLength(100)] public string? Referencia { get; set; }
        public decimal Recibido { get; set; }
        public decimal SaldoAplicado { get; set; }
        public List<AplicacionInput> Aplicaciones { get; set; } = [];
        public IEnumerable<ValidationResult> Validate(ValidationContext context)
        {
            if (Operacion == Guid.Empty) yield return new("Falta el identificador de operación. Abra de nuevo el estado de cuenta.");
            if (Recibido < 0 || SaldoAplicado < 0 || Recibido > 9999999999999999.99m || SaldoAplicado > 9999999999999999.99m || decimal.Round(Recibido, 2) != Recibido || decimal.Round(SaldoAplicado, 2) != SaldoAplicado)
                { yield return new("Dinero y saldo deben ser positivos o cero, con hasta dos decimales."); yield break; }
            var items = Aplicaciones.Where(x => x.Importe != 0).ToList();
            if (items.Count is < 1 or > 50 || items.Any(x => x.CargoId <= 0 || x.Importe <= 0 || x.Importe > 9999999999999999.99m || decimal.Round(x.Importe, 2) != x.Importe) || items.Select(x => x.CargoId).Distinct().Count() != items.Count)
            { yield return new("Seleccione entre 1 y 50 cargos distintos e importes positivos de hasta dos decimales."); yield break; }
            var total = items.Sum(x => x.Importe);
            if (total > 9999999999999999.99m || SaldoAplicado > total || Recibido + SaldoAplicado < total) yield return new("Dinero y saldo deben cubrir los cargos seleccionados; el saldo aplicado no puede superar el total.");
            if (Metodo == "Transferencia" && (string.IsNullOrWhiteSpace(Referencia) || Recibido <= 0 || Recibido + SaldoAplicado != total)) yield return new("La transferencia requiere referencia, dinero recibido y un importe exacto, sin vuelto.");
            if (Metodo == "Saldo" && Recibido != 0) yield return new("Para pagar solo con saldo, el dinero recibido debe ser cero.");
            if (Metodo == "Efectivo" && Recibido <= 0) yield return new("Indique el efectivo recibido.");
        }
    }
    [BindProperty] public CobroInput Input { get; set; } = new();
    public DataSet Datos { get; private set; } = new();
    public bool Cargado => Datos.Tables.Contains("Resumen");
    public bool Migrado => Cargado && (bool)Datos.Tables["Resumen"]!.Rows[0]["Migrado"];
    public decimal Deuda => Cargado ? Datos.Tables["Cargos"]!.AsEnumerable().Sum(r => r.Field<decimal>("Pendiente")) : 0;
    public int CargoPagina { get; private set; } = 1;
    public bool MasCargos { get; private set; }
    private async Task CargarAsync()
    {
        await using var c = factory.Create(); await c.OpenAsync();
        await using var cmd = new SqlCommand("dbo.CuentaEstudiante_Consultar", c) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
        cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro;
        await using var reader = await cmd.ExecuteReaderAsync();
        foreach (var n in new[] { "Resumen", "Cargos", "Recibos", "Historicos" }) { var t = new DataTable(n); t.Load(reader); Datos.Tables.Add(t); }
    }
    public async Task<IActionResult> OnGetAsync(string? registro, int cargoPagina = 1)
    {
        if (string.IsNullOrWhiteSpace(registro)) return Page();
        if (registro.Length > 10 || cargoPagina < 1 || cargoPagina > 10000) return BadRequest();
        Input.Registro = registro.Trim(); Input.Operacion = Guid.NewGuid(); CargoPagina = cargoPagina;
        if (!await IntentarCargarAsync()) return Page();
        var pendientes = Datos.Tables["Cargos"]!.AsEnumerable().Where(r => r.Field<decimal>("Pendiente") > 0).ToList();
        Input.Aplicaciones = pendientes.Skip((cargoPagina - 1) * 50).Take(50).Select(r => new AplicacionInput { CargoId = r.Field<long>("Id") }).ToList();
        MasCargos = pendientes.Count > cargoPagina * 50;
        return Page();
    }
    public async Task<IActionResult> OnPostAsync()
    {
        if (ModelState.IsValid)
        {
            try
            {
                await using var c = factory.Create(); await c.OpenAsync();
                await using var cmd = new SqlCommand("dbo.CobroMultiple_Registrar", c) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
                cmd.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = Input.Operacion;
                cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro;
                cmd.Parameters.Add("@Pagador", SqlDbType.NVarChar, 200).Value = Input.Pagador.Trim();
                cmd.Parameters.Add("@Metodo", SqlDbType.NVarChar, 20).Value = Input.Metodo;
                cmd.Parameters.Add("@Referencia", SqlDbType.NVarChar, 100).Value = (object?)Input.Referencia?.Trim() ?? DBNull.Value;
                foreach (var (nombre, valor) in new[] { ("@Recibido", Input.Recibido), ("@SaldoAplicado", Input.SaldoAplicado) })
                { var p = cmd.Parameters.Add(nombre, SqlDbType.Decimal); p.Precision = 28; p.Scale = 8; p.Value = valor; }
                cmd.Parameters.Add("@Aplicaciones", SqlDbType.NVarChar, -1).Value = JsonSerializer.Serialize(Input.Aplicaciones.Where(x => x.Importe > 0).OrderBy(x => x.CargoId));
                var id = (long)(await cmd.ExecuteScalarAsync())!;
                return RedirectToPage("Recibo", new { id });
            }
            catch (SqlException ex) when (ex.Number == 53501) { return Forbid(); }
            catch (SqlException ex) when (ex.Number is >= 53500 and <= 53504) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex)
            {
                logger.LogError("Cobro no confirmado: {Tipo}", ex.GetType().Name);
                ModelState.AddModelError("", "No se pudo confirmar el resultado. Consulte los recibos; si reintenta, use este mismo formulario para conservar la operación.");
            }
        }
        // Conservar importes e identificador incluso después de timeout: nunca crear otra operación aquí.
        if (!string.IsNullOrWhiteSpace(Input.Registro) && Input.Registro.Length <= 10) await IntentarCargarAsync();
        return Page();
    }
    private async Task<bool> IntentarCargarAsync()
    {
        try { await CargarAsync(); return true; }
        catch (SqlException ex) when (ex.Number is >= 53500 and <= 53504) { ModelState.AddModelError("", ex.Message); }
        catch (Exception ex) { logger.LogError("Consulta financiera fallida: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo consultar. Compruebe conexión e instalación de 013 y CobroMultiple.sql."); }
        return false;
    }
}
