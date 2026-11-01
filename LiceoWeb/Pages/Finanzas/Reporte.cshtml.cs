using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;
[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class ReporteModel(SqlConnectionFactory factory,UsuarioActual usuario,ILogger<ReporteModel> logger):PageModel
{
    public sealed class FiltroInput:IValidatableObject
    {
        [DataType(DataType.Date)] public DateTime Desde {get;set;}=new(DateTime.UtcNow.AddHours(-6).Year,DateTime.UtcNow.AddHours(-6).Month,1);
        [DataType(DataType.Date)] public DateTime Hasta {get;set;}=DateTime.UtcNow.AddHours(-6).Date;
        [Range(1,1000000)] public int Pagina {get;set;}=1;
        public IEnumerable<ValidationResult> Validate(ValidationContext context)
        {
            if(Desde.Year<2000 || Hasta.Year>9998 || Hasta.Date<Desde.Date || (Hasta.Date-Desde.Date).TotalDays>365)
                yield return new("Indica fechas desde el año 2000, hasta 9998, en orden y con un máximo de 366 días incluidos.");
        }
    }
    [BindProperty(SupportsGet=true)] public FiltroInput Filtro {get;set;}=new();
    public DataSet Datos {get;private set;}=new();
    public bool Cargado=>Datos.Tables.Contains("Movimientos");
    public long Total=>Cargado?(long)Datos.Tables["Resumen"]!.Rows[0]["Movimientos"]:0;
    public async Task<IActionResult> OnGetAsync() => await CargarAsync(false) ?? Page();
    public async Task<IActionResult> OnGetExportarAsync()
    {
        var error = await CargarAsync(true);
        if (error is not null) return error;
        return File(ReporteFinancieroCsv.Crear(Datos.Tables["Movimientos"]!),
            "text/csv; charset=utf-8", $"cobros-devoluciones-{Filtro.Desde:yyyy-MM-dd}-{Filtro.Hasta:yyyy-MM-dd}.csv");
    }
    private async Task<IActionResult?> CargarAsync(bool exportar)
    {
        if(!ModelState.IsValid)return Page();
        try
        {
            await using var c=factory.Create();await c.OpenAsync();
            await using var cmd=new SqlCommand("dbo.ReporteFinanciero_Consultar",c){CommandType=CommandType.StoredProcedure};
            cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();
            cmd.Parameters.Add("@Desde",SqlDbType.Date).Value=Filtro.Desde.Date;
            cmd.Parameters.Add("@Hasta",SqlDbType.Date).Value=Filtro.Hasta.Date;
            cmd.Parameters.Add("@Pagina",SqlDbType.Int).Value=Filtro.Pagina;
            cmd.Parameters.Add("@Exportar",SqlDbType.Bit).Value=exportar;
            await using var reader=await cmd.ExecuteReaderAsync();var ds=new DataSet();
            foreach(var name in new[]{"Resumen","Metodos","Movimientos"}){var t=new DataTable(name);t.Load(reader);ds.Tables.Add(t);}Datos=ds;
            return null;
        }
        catch(SqlException ex) when(ex.Number==53601){return Forbid();}
        catch(SqlException ex) when(ex.Number is 54002 or 54003){ModelState.AddModelError("",ex.Message);}
        catch(Exception ex){logger.LogError("Reporte financiero: {Tipo}",ex.GetType().Name);ModelState.AddModelError("","No se pudo consultar. Revisa la conexión y la instalación de ReporteFinanciero_Consultar.sql.");}
        return Page();
    }
}
