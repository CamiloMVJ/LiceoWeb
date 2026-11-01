using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy = "SoloAdministrador")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class CargosModel(SqlConnectionFactory factory, UsuarioActual usuario, ILogger<CargosModel> logger) : PageModel
{
    public sealed class CargoInput : IValidatableObject
    {
        [Required, StringLength(10)] public string Registro { get; set; } = "";
        [Range(1, int.MaxValue)] public int TarifaId { get; set; }
        [Required, RegularExpression("^0x[0-9A-Fa-f]{16}$")] public string VersionTarifa { get; set; } = "";
        public Guid Operacion { get; set; }
        public bool GenerarRango { get; set; }
        [Range(1,12)] public int? MesFinal { get; set; }
        [Range(1,28)] public int? DiaVencimiento { get; set; }
        [Range(1, 12)] public int? Mes { get; set; }
        [StringLength(30), RegularExpression("^[A-Za-z0-9_-]+$")] public string? Evento { get; set; }
        [DataType(DataType.Date)] public DateTime? Vencimiento { get; set; }
        public IEnumerable<ValidationResult> Validate(ValidationContext context)
        {
            if (GenerarRango && (Mes is null || MesFinal is null || MesFinal < Mes || DiaVencimiento is null || Vencimiento is not null || !string.IsNullOrEmpty(Evento))) yield return new("Para el lote indica mes inicial/final y día 1–28, sin evento ni fecha individual.");
            if (Operacion == Guid.Empty) yield return new("Falta la operación. Abra de nuevo el formulario.");
            if (Mes.HasValue && !string.IsNullOrEmpty(Evento)) yield return new("Un cargo no puede indicar mes y evento a la vez.");
        }
    }
    [BindProperty] public CargoInput Input { get; set; } = new();
    public DataSet Datos { get; private set; } = new();
    public bool Cargado => Datos.Tables.Contains("Tarifas");
    public bool Migrado => Cargado && (bool)Datos.Tables["Control"]!.Rows[0]["Migrado"];
    public DataRow? Tarifa => Cargado ? Datos.Tables["Tarifas"]!.AsEnumerable().FirstOrDefault(r => r.Field<int>("Id") == Input.TarifaId) : null;
    [TempData] public string? Mensaje { get; set; }
    private SqlCommand Comando(SqlConnection c, string nombre)
    {
        var cmd = new SqlCommand(nombre, c) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId(); return cmd;
    }
    private async Task CargarAsync()
    {
        try
        {
            await using var c = factory.Create(); await c.OpenAsync(); await using var cmd = Comando(c, "dbo.Cargos_Pantalla");
            cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro.Length <= 10 ? Input.Registro : "";
            await using var reader = await cmd.ExecuteReaderAsync(); var ds = new DataSet();
            foreach (var n in new[] { "Control", "Aranceles", "Estudiante", "Tarifas" }) { var t = new DataTable(n); t.Load(reader); ds.Tables.Add(t); }
            Datos = ds;
        }
        catch (Exception ex) { logger.LogError("Consulta de cargos: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo consultar. Revisa conexión, migración 014 y GeneracionCargos.sql."); }
    }
    public async Task<IActionResult> OnGetAsync(string? registro, int tarifaId = 0)
    {
        if (registro?.Length > 10 || tarifaId < 0) return BadRequest();
        Input.Registro = registro?.Trim() ?? ""; Input.TarifaId = tarifaId; Input.Operacion = Guid.NewGuid();
        await CargarAsync();
        if (Tarifa is { } t) Input.VersionTarifa = (string)t["VersionTarifa"];
        return Page();
    }
    public async Task<IActionResult> OnPostAsync()
    {
        if (ModelState.IsValid)
        {
            try
            {
                await using var c = factory.Create(); await c.OpenAsync(); await using var cmd = Comando(c, Input.GenerarRango ? "dbo.Mensualidades_GenerarLote" : "dbo.Cargos_Generar");
                cmd.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = Input.Operacion;
                cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro;
                cmd.Parameters.Add("@TarifaId", SqlDbType.Int).Value = Input.TarifaId;
                cmd.Parameters.Add("@VersionTarifa", SqlDbType.Binary, 8).Value = Convert.FromHexString(Input.VersionTarifa[2..]);
                cmd.Parameters.Add(Input.GenerarRango ? "@MesInicial" : "@Mes", SqlDbType.Int).Value = (object?)Input.Mes ?? DBNull.Value;
                if(Input.GenerarRango) {
                    cmd.Parameters.Add("@MesFinal", SqlDbType.Int).Value = Input.MesFinal!;
                    cmd.Parameters.Add("@DiaVencimiento", SqlDbType.Int).Value = Input.DiaVencimiento!;
                } else {
                cmd.Parameters.Add("@Evento", SqlDbType.NVarChar, 30).Value = (object?)Input.Evento ?? DBNull.Value;
                cmd.Parameters.Add("@Vencimiento", SqlDbType.Date).Value = (object?)Input.Vencimiento?.Date ?? DBNull.Value;
                }
                var id = Convert.ToInt64(await cmd.ExecuteScalarAsync());
                Mensaje = Input.GenerarRango ? $"{id} mensualidades generadas. Consulta el estado de cuenta." : $"Cargo {id} registrado. Ya puede cobrarse en el estado de cuenta.";
                return RedirectToPage(new { registro = Input.Registro });
            }
            catch (SqlException ex) when (ex.Number == 53601) { return Forbid(); }
            catch (SqlException ex) when (ex.Number is >= 53600 and <= 53603 or >= 53900 and <= 53903) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex) { logger.LogError("Generación de cargo no confirmada: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo confirmar el resultado. Consulta la cuenta y conserva este formulario para reintentar con la misma operación."); }
        }
        await CargarAsync(); return Page();
    }
    public async Task<IActionResult> OnPostConfigurarAsync(int arancelId, string? periodicidad)
    {
        // Este formulario no envía CargoInput. Valida sus propios dos campos.
        ModelState.Clear();
        if (arancelId <= 0 || periodicidad is not ("Anual" or "Mensual" or "Eventual")) ModelState.AddModelError("", "Selecciona arancel y periodicidad válidos.");
        if (ModelState.IsValid)
        {
            try
            {
                await using var c = factory.Create(); await c.OpenAsync(); await using var cmd = Comando(c, "dbo.Cargos_Configurar");
                cmd.Parameters.Add("@ArancelId", SqlDbType.Int).Value = arancelId;
                cmd.Parameters.Add("@Periodicidad", SqlDbType.NVarChar, 10).Value = periodicidad!;
                await cmd.ExecuteNonQueryAsync(); Mensaje = "Periodicidad registrada."; return RedirectToPage();
            }
            catch (SqlException ex) when (ex.Number == 53601) { return Forbid(); }
            catch (SqlException ex) when (ex.Number is >= 53600 and <= 53603 or >= 53900 and <= 53903) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex) { logger.LogError("Configuración de cargo: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo guardar la configuración. Vuelve a consultar antes de reintentar."); }
        }
        await CargarAsync(); return Page();
    }
}
