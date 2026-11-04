using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;

namespace LiceoWeb.Pages.Notas;

[Authorize(Policy = "SoloAdministrador")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class TiposModel(NotasRepository repository, UsuarioActual usuario, ILogger<TiposModel> logger) : PageModel
{
    [BindProperty] public TipoEvaluacionInput Input { get; set; } = new();
    [TempData] public string? Mensaje { get; set; }
    public DataSet Datos { get; private set; } = new();
    public int Pagina { get; private set; } = 1;
    public bool Cargado { get; private set; }
    public IEnumerable<DataRow> Filas(string tabla) =>
        Datos.Tables.Contains(tabla) ? Datos.Tables[tabla]!.AsEnumerable() : [];
    public DataRow? Seleccionado => Filas("Tipos").FirstOrDefault(r => (int)r["Id"] == Input.Id);
    public long Total => Filas("Resumen").FirstOrDefault()?.Field<long>("Total") ?? 0;

    public async Task<IActionResult> OnGetAsync(int id = 0, int pagina = 1)
    {
        if (id < 0 || pagina is < 1 or > 1000000) return BadRequest();
        Pagina = pagina;
        Input.Id = id;
        var error = await CargarAsync();
        if (error is not null) return error;
        if (id > 0)
        {
            if (Seleccionado is not { } row) return NotFound();
            Input = new()
            {
                Id = id, Nombre = (string)row["Nombre"], Activo = (bool)row["Activo"],
                Version = (string)row["Version"], Operacion = Guid.NewGuid()
            };
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id)
    {
        if (id <= 0 || id != Input.Id) return BadRequest();
        if (ModelState.IsValid)
        {
            try
            {
                await repository.GuardarTipoAsync(usuario.ObtenerId(), Input);
                Mensaje = "Tipo actualizado. Se conservó el cambio en el historial.";
                return RedirectToPage(new { id });
            }
            catch (SqlException ex) when (ex.Number == 54601) { return Forbid(); }
            catch (SqlException ex) when (ex.Number is >= 54602 and <= 54607)
            { ModelState.AddModelError("", ex.Message); }
            catch (SqlException ex) when (ex.Number is 2601 or 2627)
            { ModelState.AddModelError("", "Ese nombre u operación ya existe. Recarga antes de reintentar."); }
            catch (Exception ex)
            {
                logger.LogError("Guardar tipo de evaluación: {Tipo}", ex.GetType().Name);
                ModelState.AddModelError("", "No se pudo guardar. Revisa conexión y scripts de tipos de evaluación.");
            }
        }
        // Conserva versión y operación enviadas: nunca sustituye un formulario obsoleto.
        return await CargarAsync() ?? Page();
    }

    private async Task<IActionResult?> CargarAsync()
    {
        try
        {
            Datos = await repository.ConsultarTiposAsync(usuario.ObtenerId(), Input.Id, Pagina);
            Cargado = true;
            return null;
        }
        catch (SqlException ex) when (ex.Number == 54601) { return Forbid(); }
        catch (Exception ex)
        {
            logger.LogError("Consultar tipos de evaluación: {Tipo}", ex.GetType().Name);
            ModelState.AddModelError("", "No se pudo cargar. Revisa la migración 022 y los dos procedimientos TipoEvaluacion.");
            return Page();
        }
    }
}
