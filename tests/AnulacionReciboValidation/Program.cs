using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
var count=0;
void Check(string name,Action<AnularReciboModel.AnulacionInput> edit,bool expected)
{
 var x=new AnularReciboModel.AnulacionInput{ReciboId=1,Operacion=Guid.NewGuid(),Motivo="Pago equivocado",Receptor="Pagador",ReferenciaDevolucion="DEV-001",Confirmado=true};edit(x);
 var errors=new List<ValidationResult>();var valid=Validator.TryValidateObject(x,new ValidationContext(x),errors,true);
 if(valid!=expected)throw new Exception(name+": "+string.Join("; ",errors.Select(e=>e.ErrorMessage)));
 Console.WriteLine("PASS "+name);count++;
}
Check("Solicitud completa",_=>{},true);
Check("Sin confirmar",x=>x.Confirmado=false,false);
Check("Sin operación",x=>x.Operacion=Guid.Empty,false);
Check("Sin recibo",x=>x.ReciboId=0,false);
Check("Sin motivo",x=>x.Motivo="   ",false);
Check("Sin receptor",x=>x.Receptor="",false);
Check("Sin referencia",x=>x.ReferenciaDevolucion="",false);
Check("Motivo largo",x=>x.Motivo=new string('A',501),false);
Check("Receptor largo",x=>x.Receptor=new string('A',201),false);
Check("Referencia larga",x=>x.ReferenciaDevolucion=new string('A',101),false);
Console.WriteLine($"{count} pruebas aprobadas.");
