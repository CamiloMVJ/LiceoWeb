using LiceoWeb.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.RazorPages;
namespace LiceoWeb.Filters;
// Se ejecuta tras autorización y antes de model binding/handlers; incluye URLs y POST directos.
public sealed class LibroAnteriorFilter(IEstadoLibroFinanciero estado) : IAsyncResourceFilter
{
    private static readonly string[] Carpetas = ["/Cobros", "/Mensualidades", "/Matriculas", "/Precios", "/Arreglos", "/Recibos", "/Reportes"];
    public static bool EsRutaAnterior(string pagina) => Carpetas.Any(p => pagina.Equals(p, StringComparison.OrdinalIgnoreCase) || pagina.StartsWith(p + "/", StringComparison.OrdinalIgnoreCase));
    public async Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)
    {
        if (context.ActionDescriptor is not PageActionDescriptor page || !string.IsNullOrEmpty(context.RouteData.Values["area"]?.ToString()) || !EsRutaAnterior(page.ViewEnginePath))
        { await next(); return; }
        var libro = await estado.ObtenerAsync();
        context.HttpContext.Response.Headers.CacheControl = "no-store";
        if (libro != EstadoLibro.Nuevo)
        {
            context.Result = new ContentResult { StatusCode = 503, ContentType = "text/plain; charset=utf-8", Content = "Actualiza la base con la migración 025 para usar las operaciones financieras actuales. No se ejecutó la operación antigua." }; return;
        }
        if (HttpMethods.IsGet(context.HttpContext.Request.Method) || HttpMethods.IsHead(context.HttpContext.Request.Method))
            context.Result = new RedirectToPageResult("/Finanzas/LibroAnterior");
        else
            context.Result = new ObjectResult(new ProblemDetails { Status = 409, Title = "El libro financiero anterior está cerrado", Detail = "No se ejecutó esta operación. Abre /Finanzas/Cuenta para consultar y cobrar, o /Finanzas/Cargos para generar cargos como Administrador." }) { StatusCode = 409 };
    }
}
