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
public class ReciboModel(SqlConnectionFactory factory, UsuarioActual usuario) : PageModel
{
    public DataSet Datos { get; } = new();
    public async Task<IActionResult> OnGetAsync(long id)
    {
        if (id <= 0) return NotFound();
        try
        {
            await using var c = factory.Create(); await c.OpenAsync();
            await using var cmd = new SqlCommand("dbo.ReciboMultiple_Consultar", c) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.Add("@UsuarioId", SqlDbType.NVarChar, 450).Value = usuario.ObtenerId();
            cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
            await using var reader = await cmd.ExecuteReaderAsync();
            foreach (var name in new[] { "Recibo", "Detalle" }) { var t = new DataTable(name); t.Load(reader); Datos.Tables.Add(t); }
            return Page();
        }
        catch (SqlException ex) when (ex.Number == 53504) { return NotFound(); }
        catch (SqlException ex) when (ex.Number == 53501) { return Forbid(); }
    }
}
