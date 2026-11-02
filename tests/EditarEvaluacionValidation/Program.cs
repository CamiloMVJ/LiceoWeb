using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
var count=0;
void Check(string name,Action<EditarEvaluacionInput> change,bool expected)
{
 var x=new EditarEvaluacionInput{Id=1,TipoId=1,Nombre="Examen",Fecha=new(2027,3,1),Modo="Cuantitativa",Maximo=30,Peso=30,Version="0x0000000000000001",Operacion=Guid.NewGuid(),Motivo="Corregir definición de examen"};change(x);
 var valid=Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
 if(valid!=expected)throw new Exception(name);Console.WriteLine("PASS "+name);count++;
}
Check("Definición válida",x=>{},true);
Check("Id inválido",x=>x.Id=0,false);
Check("Tipo ausente",x=>x.TipoId=0,false);
Check("Nombre vacío",x=>x.Nombre=" ",false);
Check("Nombre largo",x=>x.Nombre=new string('a',101),false);
Check("Fecha ausente",x=>x.Fecha=null,false);
Check("Versión ausente",x=>x.Version="",false);
Check("Versión incompleta",x=>x.Version="0x01",false);
Check("Operación vacía",x=>x.Operacion=Guid.Empty,false);
Check("Motivo espacios",x=>x.Motivo=new string(' ',20),false);
Check("Motivo demasiado largo",x=>x.Motivo=new string('a',501),false);
Check("Peso excedido",x=>x.Peso=101,false);
Check("Peso con exceso de precisión",x=>x.Peso=30.001m,false);
Check("Máximo cero",x=>x.Maximo=0,false);
Check("Máximo fuera del tipo SQL",x=>x.Maximo=100000,false);
Check("Modalidad inválida",x=>x.Modo="Otra",false);
Check("Escala válida",x=>{x.Modo="Cualitativa";x.Opciones="Logrado\nEn proceso";},true);
Check("Escala duplicada",x=>{x.Modo="Cualitativa";x.Opciones="Logrado\nlogrado";},false);
Check("Escala insuficiente",x=>{x.Modo="Cualitativa";x.Opciones="Logrado";},false);
Console.WriteLine($"{count} pruebas aprobadas.");
