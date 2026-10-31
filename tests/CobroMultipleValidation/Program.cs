using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
var count = 0;
CuentaModel.CobroInput Input() => new() { Registro="E_0000001",Operacion=Guid.NewGuid(),Pagador="Prueba",Recibido=100,Aplicaciones=[new(){CargoId=1,Importe=70},new(){CargoId=2,Importe=30}] };
void Check(string name, Action<CuentaModel.CobroInput> change, bool valid)
{
 var input=Input();change(input);var errors=new List<ValidationResult>();
 var result=Validator.TryValidateObject(input,new ValidationContext(input),errors,true);
 if(result!=valid)throw new Exception(name+": "+string.Join("; ",errors.Select(e=>e.ErrorMessage)));
 Console.WriteLine("PASS "+name);count++;
}
Check("Multiconcepto efectivo",_=>{},true);
Check("Vuelto",x=>x.Recibido=150,true);
Check("Abono parcial",x=>{x.Aplicaciones[0].Importe=10;x.Recibido=40;},true);
Check("Saldo y efectivo",x=>{x.SaldoAplicado=30;x.Recibido=70;},true);
Check("Solo saldo",x=>{x.Metodo="Saldo";x.SaldoAplicado=100;x.Recibido=0;},true);
Check("Transferencia exacta",x=>{x.Metodo="Transferencia";x.Referencia="REF";},true);
Check("Transferencia sin referencia",x=>x.Metodo="Transferencia",false);
Check("Transferencia con vuelto",x=>{x.Metodo="Transferencia";x.Referencia="REF";x.Recibido=101;},false);
Check("Saldo con efectivo",x=>x.Metodo="Saldo",false);
Check("Fondos insuficientes",x=>x.Recibido=99,false);
Check("Saldo excede deuda",x=>x.SaldoAplicado=101,false);
Check("Cargo repetido",x=>x.Aplicaciones[1].CargoId=1,false);
Check("Aplicación negativa",x=>x.Aplicaciones[0].Importe=-1,false);
Check("Más de dos decimales",x=>x.Aplicaciones[0].Importe=1.001m,false);
Check("Cero cargos",x=>x.Aplicaciones.Clear(),false);
Check("Sin operación",x=>x.Operacion=Guid.Empty,false);
Check("Desborde controlado",x=>{x.Recibido=decimal.MaxValue;x.SaldoAplicado=decimal.MaxValue;},false);
Check("Importes en cero omitidos",x=>x.Aplicaciones.Add(new(){CargoId=3,Importe=0}),true);
Check("Máximo 50",x=>x.Aplicaciones=Enumerable.Range(1,51).Select(i=>new CuentaModel.AplicacionInput{CargoId=i,Importe=1}).ToList(),false);
Console.WriteLine($"{count} pruebas aprobadas.");
