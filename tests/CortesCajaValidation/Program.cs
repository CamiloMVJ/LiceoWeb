using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
using Microsoft.AspNetCore.Authorization;
void Probar(string nombre,Action<CortesModel.CorteInput> cambio,bool esperado)
{
 var i=new CortesModel.CorteInput{Accion="CerrarAbrir",CorteId=1,Contado=350,Fondo=100,Motivo="Cierre de caja de prueba"};
 cambio(i);
 bool valido=Validator.TryValidateObject(i,new ValidationContext(i),[],true);
 if(valido!=esperado)throw new Exception(nombre);
 Console.WriteLine("PASS "+nombre);
}
Probar("Cerrar y abrir",_=>{},true);
Probar("Abrir con fondo cero",x=>{x.Accion="Abrir";x.CorteId=0;x.Contado=null;x.Fondo=0;},true);
Probar("Cierre sin corte",x=>x.CorteId=0,false);
Probar("Conteo obligatorio",x=>x.Contado=null,false);
Probar("Conteo negativo",x=>x.Contado=-1,false);
Probar("Dos decimales máximo",x=>x.Contado=1.001m,false);
Probar("Fondo negativo",x=>x.Fondo=-1,false);
Probar("Cerrar sin fondo nuevo",x=>{x.Accion="Cerrar";x.Fondo=0;},true);
Probar("No descartar fondo al cerrar",x=>x.Accion="Cerrar",false);
Probar("Motivo requerido",x=>x.Motivo="",false);
Probar("Identificador para reintentos",x=>x.Operacion=Guid.Empty,false);
var auth=(AuthorizeAttribute)typeof(CortesModel).GetCustomAttributes(typeof(AuthorizeAttribute),true).Single();
if(auth.Policy!="SoloAdministrador")throw new Exception("El acceso a cortes debe ser administrativo");
Console.WriteLine("PASS política SoloAdministrador para todas las acciones de caja");

if(typeof(CortesModel).GetMethod("OnPostTransicionAsync") is not null)throw new Exception("La transición de escritorio debe estar retirada");
Console.WriteLine("PASS transición de escritorio retirada");
