using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
var count=0;
void Check(string name,Action<CargosModel.CargoInput> edit,bool expected)
{
 var x=new CargosModel.CargoInput{Registro="E_0000001",TarifaId=1,VersionTarifa="0x0000000000000001",Operacion=Guid.NewGuid()};edit(x);
 var errors=new List<ValidationResult>();var valid=Validator.TryValidateObject(x,new ValidationContext(x),errors,true);
 if(valid!=expected)throw new Exception(name+": "+string.Join("; ",errors.Select(e=>e.ErrorMessage)));
 Console.WriteLine("PASS "+name);count++;
}
Check("Anual",_=>{},true);
Check("Mensual enero",x=>x.Mes=1,true);
Check("Mensual diciembre",x=>x.Mes=12,true);
Check("Evento",x=>x.Evento="EXCURSION_01",true);
Check("Sin operación",x=>x.Operacion=Guid.Empty,false);
Check("Mes fuera de rango",x=>x.Mes=13,false);
Check("Mes cero",x=>x.Mes=0,false);
Check("Mes y evento",x=>{x.Mes=1;x.Evento="EXAMEN";},false);
Check("Evento con espacios",x=>x.Evento="EXAMEN EXTRA",false);
Check("Evento demasiado largo",x=>x.Evento=new string('A',31),false);
Check("Versión inválida",x=>x.VersionTarifa="0x00",false);
Check("Sin tarifa",x=>x.TarifaId=0,false);
Check("Sin estudiante",x=>x.Registro="",false);
Console.WriteLine($"{count} pruebas aprobadas.");
