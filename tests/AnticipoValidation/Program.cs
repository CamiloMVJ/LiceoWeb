using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
void Probar(string nombre, Action<AnticipoModel.AnticipoInput> cambiar, bool esperado)
{
    var i=new AnticipoModel.AnticipoInput { Registro="E_0000001", Operacion=Guid.NewGuid(), Pagador="Prueba", Metodo="Efectivo", Importe=350.25m };
    cambiar(i);
    if(Validator.TryValidateObject(i,new ValidationContext(i),[],true)!=esperado)throw new Exception(nombre);
    Console.WriteLine("PASS "+nombre);
}
Probar("Anticipo en efectivo",_=>{},true);
Probar("Transferencia con referencia",x=>{x.Metodo="Transferencia";x.Referencia="TR-100";},true);
Probar("Transferencia sin referencia",x=>x.Metodo="Transferencia",false);
Probar("Saldo no puede crear saldo nuevo",x=>x.Metodo="Saldo",false);
Probar("Monto cero",x=>x.Importe=0,false);
Probar("Monto negativo",x=>x.Importe=-1,false);
Probar("Más de dos decimales",x=>x.Importe=1.001m,false);
Probar("Operación ausente",x=>x.Operacion=Guid.Empty,false);
