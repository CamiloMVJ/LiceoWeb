using LiceoWeb.Filters;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Routing;
var count=0;
async Task Check(string name,string path,string method,EstadoLibro state,bool expectedNext,int? expectedStatus=null,bool redirect=false,string? area=null)
{
 var http=new DefaultHttpContext();http.Request.Method=method;
 var routes=new RouteData();if(area is not null)routes.Values["area"]=area;
 var action=new ActionContext(http,routes,new PageActionDescriptor{ViewEnginePath=path});
 var filters=new List<IFilterMetadata>();var context=new ResourceExecutingContext(action,filters,new List<IValueProviderFactory>());
 var fake=new FakeState(state);var invoked=false;
 await new LibroAnteriorFilter(fake).OnResourceExecutionAsync(context,()=>{invoked=true;return Task.FromResult(new ResourceExecutedContext(action,filters));});
 if(invoked!=expectedNext)throw new Exception(name+": handler incorrecto");
 if(redirect && context.Result is not RedirectToPageResult{PageName:"/Finanzas/LibroAnterior"})throw new Exception(name+": falta redirección");
 var status=context.Result switch{ObjectResult o=>o.StatusCode,ContentResult c=>c.StatusCode,_=>null};
 if(expectedStatus!=status)throw new Exception(name+": estado incorrecto");
 if(expectedNext && !LibroAnteriorFilter.EsRutaAnterior(path) && fake.Calls!=0)throw new Exception("Consultó DB para una ruta nueva");
 Console.WriteLine("PASS "+name);count++;
}
await Check("Esquema sin actualizar bloquea GET antiguo","/Cobros/Index","GET",EstadoLibro.Anterior,false,503);
await Check("Esquema sin actualizar bloquea POST antiguo","/Mensualidades/Index","POST",EstadoLibro.Anterior,false,503);
await Check("Nuevo redirige GET","/Cobros/Index","GET",EstadoLibro.Nuevo,false,redirect:true);
await Check("Nuevo bloquea POST","/Cobros/Index","POST",EstadoLibro.Nuevo,false,409);
await Check("Nuevo bloquea otra mutación","/Precios/Editar_PrecioMatricula","DELETE",EstadoLibro.Nuevo,false,409);
await Check("HEAD redirige","/Matriculas/Registrar","HEAD",EstadoLibro.Nuevo,false,redirect:true);
await Check("DB caída bloquea POST","/Mensualidades/Index","POST",EstadoLibro.NoDisponible,false,503);
await Check("DB caída bloquea GET","/Recibos/Index","GET",EstadoLibro.NoDisponible,false,503);
await Check("Finanzas nuevas sin filtro","/Finanzas/Cuenta","POST",EstadoLibro.Nuevo,true);
await Check("Expediente sin filtro","/Estudiantes/Expediente","POST",EstadoLibro.Nuevo,true);
await Check("No confundir prefijo","/CobrosNuevos/Index","GET",EstadoLibro.Nuevo,true);
await Check("Área ajena no afectada","/Cobros/Index","GET",EstadoLibro.Nuevo,true,area:"Identity");
await Check("Reportes anteriores redirigen","/Reportes/Index","GET",EstadoLibro.Nuevo,false,redirect:true);
Console.WriteLine($"{count} pruebas aprobadas.");
sealed class FakeState(EstadoLibro state):IEstadoLibroFinanciero
{
 public int Calls{get;private set;}
 public Task<EstadoLibro> ObtenerAsync(){Calls++;return Task.FromResult(state);}
}
