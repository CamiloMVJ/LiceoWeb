using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
var total=0;
CancelarHorarioInput Nuevo()=>new(){HorarioId=1,Version="0x0000000000000001",Operacion=Guid.NewGuid(),Motivo="Cambio de distribución de clases"};
void Probar(string nombre,Action<CancelarHorarioInput> cambio,bool esperado)
{
 var input=Nuevo();cambio(input);
 var valido=Validator.TryValidateObject(input,new ValidationContext(input),new List<ValidationResult>(),true);
 if(valido!=esperado)throw new Exception(nombre);
 Console.WriteLine("PASS "+nombre);total++;
}
Probar("Cancelación completa",x=>{},true);
Probar("Horario inválido",x=>x.HorarioId=0,false);
Probar("Operación vacía",x=>x.Operacion=Guid.Empty,false);
Probar("Motivo vacío",x=>x.Motivo="",false);
Probar("Motivo solo espacios",x=>x.Motivo=new string(' ',15),false);
Probar("Motivo corto tras trim",x=>x.Motivo="    cambio    ",false);
Probar("Motivo mínimo",x=>x.Motivo="1234567890",true);
Probar("Motivo máximo",x=>x.Motivo=new string('a',500),true);
Probar("Motivo demasiado largo",x=>x.Motivo=new string('a',501),false);
Probar("Versión vacía",x=>x.Version="",false);
Probar("Versión truncada",x=>x.Version="0x01",false);
Probar("Versión no hexadecimal",x=>x.Version="0xZZ00000000000001",false);
Console.WriteLine($"{total} pruebas aprobadas.");
