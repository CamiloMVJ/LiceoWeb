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
public class AnularReciboModel(SqlConnectionFactory factory, UsuarioActual usuario, ILogger<AnularReciboModel> logger) : PageModel
{
    public sealed class AnulacionInput : IValidatableObject
    {
        [Range(typeof(long), "1", "9223372036854775807")] public long ReciboId { get; set; }
        public Guid Operacion { get; set; }
        [Required, StringLength(500)] public string Motivo { get; set; } = "";
        [Required, StringLength(100)] public string ReferenciaDevolucion { get; set; } = "";
        [Required, StringLength(200)] public string Receptor { get; set; } = "";
        public bool Confirmado { get; set; }
        public IEnumerable<ValidationResult> Validate(ValidationContext context)
        {
            if (Operacion == Guid.Empty) yield return new("Falta la operación. Abre nuevamente el formulario.");
            if (!Confirmado) yield return new("Confirma la devolución documentada y el ajuste correspondiente.");
        }
    }
    [BindProperty] public AnulacionInput Input { get; set; } = new();
    public DataSet Datos { get; private set; } = new();
    public bool Cargado => Datos.Tables.Contains("Anulacion");
    public bool PuedeAnular => Cargado && !Anulado && (Datos.Tables["Recibo"]!.Rows[0] is var r) &&
        (!r.Table.Columns.Contains("Anticipo") || (decimal)r["Anticipo"] == 0 ||
         (r.Table.Columns.Contains("SaldoDisponibleActual") && (decimal)r["SaldoDisponibleActual"] >= (decimal)r["Anticipo"]));
    public bool Anulado => Cargado && Datos.Tables["Anulacion"]!.Rows.Count > 0;
    private async Task CargarAsync()
    {
        await using var c = factory.Create(); await c.OpenAsync();
        await using var cmd = new SqlCommand("dbo.ReciboMultiple_Consultar", c) { CommandType = CommandType.StoredProcedure };
        cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
        cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = Input.ReciboId;
        await using var reader = await cmd.ExecuteReaderAsync(); var ds = new DataSet();
        foreach (var n in new[] { "Recibo", "Detalle", "Anulacion" }) { var t = new DataTable(n); t.Load(reader); ds.Tables.Add(t); }
        Datos = ds;
    }
    public async Task<IActionResult> OnGetAsync(long id)
    {
        if (id <= 0) return NotFound(); Input.ReciboId = id; Input.Operacion = Guid.NewGuid();
        try { await CargarAsync(); }
        catch (SqlException ex) when (ex.Number == 53504) { return NotFound(); }
        catch (Exception ex) { logger.LogError("Consulta de anulación: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo consultar el recibo. Revisa la conexión y la instalación de 015."); }
        return Page();
    }
    public async Task<IActionResult> OnPostAsync(long id)
    {
        if (id != Input.ReciboId) return BadRequest();
        if (ModelState.IsValid)
        {
            try
            {
                await using var c = factory.Create(); await c.OpenAsync();
                await using var cmd = new SqlCommand("dbo.ReciboMultiple_Anular", c) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
                cmd.Parameters.Add("@ReciboId", SqlDbType.BigInt).Value = Input.ReciboId;
                cmd.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = Input.Operacion;
                cmd.Parameters.Add("@Motivo", SqlDbType.NVarChar, 500).Value = Input.Motivo.Trim();
                cmd.Parameters.Add("@ReferenciaDevolucion", SqlDbType.NVarChar, 100).Value = Input.ReferenciaDevolucion.Trim();
                cmd.Parameters.Add("@Receptor", SqlDbType.NVarChar, 200).Value = Input.Receptor.Trim();
                cmd.Parameters.Add("@Confirmado", SqlDbType.Bit).Value = Input.Confirmado;
                await cmd.ExecuteScalarAsync(); return RedirectToPage("Recibo", new { id = Input.ReciboId });
            }
            catch (SqlException ex) when (ex.Number == 53701) { return Forbid(); }
            catch (SqlException ex) when (ex.Number == 53704) { return NotFound(); }
            catch (SqlException ex) when (ex.Number is >= 53700 and <= 53703) { ModelState.AddModelError("", ex.Message); }
            catch (SqlException ex) when (ex.Number is 54802 or 54803) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex) { logger.LogError("Anulación no confirmada: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo confirmar el resultado. Consulta el recibo y reintenta con este mismo formulario. No repitas la devolución del dinero."); }
        }
        try { await CargarAsync(); }
        catch (Exception ex) { logger.LogError("Recarga de anulación: {Tipo}", ex.GetType().Name); ModelState.AddModelError("", "No se pudo recargar el recibo. Conserva los datos de esta operación."); }
        return Page();
    }
}
