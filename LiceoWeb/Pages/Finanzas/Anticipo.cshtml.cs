using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;

namespace LiceoWeb.Pages.Finanzas;

[Authorize(Policy = "GestionFinanciera")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class AnticipoModel(SqlConnectionFactory factory, UsuarioActual usuario, ILogger<AnticipoModel> logger) : PageModel
{
    public sealed class AnticipoInput : IValidatableObject
    {
        [Required, StringLength(10)] public string Registro { get; set; } = "";
        public Guid Operacion { get; set; }
        [Required, StringLength(200)] public string Pagador { get; set; } = "";
        [Required, RegularExpression("^(Efectivo|Transferencia)$")] public string Metodo { get; set; } = "Efectivo";
        [StringLength(100)] public string? Referencia { get; set; }
        public decimal Importe { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext context)
        {
            if (Operacion == Guid.Empty) yield return new("Vuelve a abrir el formulario para iniciar el anticipo.");
            if (Importe <= 0 || Importe > 9999999999999999.99m || decimal.Round(Importe, 2) != Importe)
                yield return new("Indica un importe positivo con hasta dos decimales.", [nameof(Importe)]);
            if (Metodo == "Transferencia" && string.IsNullOrWhiteSpace(Referencia))
                yield return new("Indica la referencia de la transferencia.", [nameof(Referencia)]);
        }
    }

    [BindProperty] public AnticipoInput Input { get; set; } = new();
    public string? Estudiante { get; private set; }
    public decimal Saldo { get; private set; }
    public bool Habilitado { get; private set; }

    public async Task<IActionResult> OnGetAsync(string? registro)
    {
        if (string.IsNullOrWhiteSpace(registro) || registro.Length > 10) return BadRequest();
        Input.Registro = registro.Trim();
        Input.Operacion = Guid.NewGuid();
        await CargarAsync();
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (ModelState.IsValid)
        {
            try
            {
                await using var c = factory.Create(); await c.OpenAsync();
                await using var cmd = new SqlCommand("dbo.Anticipo_Registrar", c) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
                cmd.Parameters.Add("@Operacion", SqlDbType.UniqueIdentifier).Value = Input.Operacion;
                cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro;
                cmd.Parameters.Add("@Pagador", SqlDbType.NVarChar, 200).Value = Input.Pagador.Trim();
                cmd.Parameters.Add("@Metodo", SqlDbType.NVarChar, 20).Value = Input.Metodo;
                cmd.Parameters.Add("@Referencia", SqlDbType.NVarChar, 100).Value = (object?)Input.Referencia?.Trim() ?? DBNull.Value;
                var importe = cmd.Parameters.Add("@Importe", SqlDbType.Decimal);
                importe.Precision = 28; importe.Scale = 8; importe.Value = Input.Importe;
                var id = (long)(await cmd.ExecuteScalarAsync())!;
                return RedirectToPage("Recibo", new { id });
            }
            catch (SqlException ex) when (ex.Number == 53501) { return Forbid(); }
            catch (SqlException ex) when (ex.Number is >= 54700 and <= 54703) { ModelState.AddModelError("", ex.Message); }
            catch (Exception ex)
            {
                logger.LogError("Anticipo no confirmado: {Tipo}", ex.GetType().Name);
                ModelState.AddModelError("", "No se pudo confirmar el anticipo. Consulta los recibos y, si reintentas, usa este mismo formulario para conservar la operación.");
            }
        }
        if (Input.Registro is { Length: > 0 and <= 10 }) await CargarAsync();
        return Page();
    }

    private async Task CargarAsync()
    {
        try
        {
            await using var c = factory.Create(); await c.OpenAsync();
            await using var cmd = new SqlCommand("""
                SELECT E.NombreEstudiante, ISNULL(S.Disponible,0),
                       CONVERT(bit,CASE WHEN E.Estado='Activo' AND EXISTS
                       (SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THEN 1 ELSE 0 END)
                FROM dbo.Estudiantes E LEFT JOIN dbo.SaldoFinanciero S ON S.Registro=E.Registro
                WHERE E.Registro=@Registro;
                """, c);
            cmd.Parameters.Add("@Registro", SqlDbType.NVarChar, 10).Value = Input.Registro;
            await using var r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) { ModelState.AddModelError("", "Estudiante inexistente."); return; }
            Estudiante = r.GetString(0); Saldo = r.GetDecimal(1); Habilitado = r.GetBoolean(2);
            if (!Habilitado) ModelState.AddModelError("", "El anticipo requiere un estudiante activo y el corte financiero aplicado.");
        }
        catch (Exception ex)
        {
            logger.LogError("Consulta de anticipo fallida: {Tipo}", ex.GetType().Name);
            ModelState.AddModelError("", "No se pudo consultar la cuenta del estudiante.");
        }
    }
}
