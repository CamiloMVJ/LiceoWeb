using LiceoWeb.Pages.Mensualidades;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;

var count=0;
void Check(bool ok,string name){if(!ok)throw new Exception(name);Console.WriteLine("PASS "+name);count++;}
var configuration=new ConfigurationBuilder().Build();
var page=new CobrosMensualidadModel(configuration);
await page.OnGetAsync(null);
Check(page.ListaEstudiantes.Count==0 && page.MensualidadesPendientes.Count==0,"Entrada sin selección no consulta SQL");
Check(await page.OnPostAsync() is Microsoft.AspNetCore.Mvc.RazorPages.PageResult && !string.IsNullOrEmpty(page.MensajeError),"Pago sin estudiante rechazado sin acceder a SQL");
Check(page.ReciboGenerado is null && page.MensajeExito is null,"Rechazo no anuncia recibo ni éxito");
var filters=new GestionMensualidadesModel();
await filters.OnGetAsync(null,null,null,null);
Check(filters.FiltroNombre=="" && filters.FiltroModalidad=="Todos" && filters.FiltroEstado=="Todos","Filtros ausentes conservan valores iniciales");
await filters.OnGetAsync("Ana",2027,"Matutino","Pendiente");
Check(filters.FiltroNombre=="Ana" && filters.FiltroAnio==2027 && filters.FiltroModalidad=="Matutino" && filters.FiltroEstado=="Pendiente","Filtros enviados se conservan");
var services=new ServiceCollection();services.AddLogging();services.AddControllersWithViews();
using var provider=services.BuildServiceProvider();var metadata=provider.GetRequiredService<IModelMetadataProvider>();
foreach(var name in new[]{nameof(page.Busqueda),nameof(page.RegistroSeleccionado),nameof(page.ReferenciaTransaccion)})
 Check(!metadata.GetMetadataForProperty(typeof(CobrosMensualidadModel),name).IsRequired,"MVC no exige el campo opcional "+name);
Console.WriteLine($"{count} pruebas aprobadas; sin SQL Server.");
