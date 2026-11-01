using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
var count=0;
void Check(string name,DateTime desde,DateTime hasta,int pagina,bool expected)
{
 var x=new ReporteModel.FiltroInput{Desde=desde,Hasta=hasta,Pagina=pagina};
 var valid=Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
 if(valid!=expected)throw new Exception(name);Console.WriteLine("PASS "+name);count++;
}
var d=new DateTime(2026,1,1);
Check("Un día",d,d,1,true);
Check("366 días incluidos",d,d.AddDays(365),1,true);
Check("Rango demasiado largo",d,d.AddDays(366),1,false);
Check("Invertido",d,d.AddDays(-1),1,false);
Check("Página cero",d,d,0,false);
Check("Página excesiva",d,d,1000001,false);
Check("Año fuera de rango",new(1999,1,1),new(1999,1,2),1,false);
Check("Evitar desborde de fecha final",new(9999,1,1),new(9999,1,2),1,false);
Console.WriteLine($"{count} pruebas aprobadas.");
