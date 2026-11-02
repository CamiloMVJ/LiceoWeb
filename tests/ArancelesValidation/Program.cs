using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
static bool Valida(ArancelInput x)=>Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
static void Check(bool ok,string name){if(!ok)throw new Exception(name);Console.WriteLine("OK: "+name);}
static ArancelInput Tarifa()=>new(){Accion="Tarifa",ArancelId=1,ModalidadId=1,AnioId=1,Importe=150.25m,Motivo="Tarifa acordada"};
Check(Valida(Tarifa()),"Importe con centavos válido");
var t=Tarifa();t.Importe=0;Check(Valida(t),"Tarifa cero permitida");
t.Importe=-1;Check(!Valida(t),"Negativo rechazado");
t.Importe=0.001m;Check(!Valida(t),"No redondear silenciosamente");
t.Importe=null;Check(!Valida(t),"Importe requerido");
t=Tarifa();t.AnioId=0;Check(!Valida(t),"Año requerido");
t=Tarifa();t.Id=1;Check(!Valida(t),"Edición exige versión");
t.Version="0x0000000000000001";Check(Valida(t),"Edición con versión");
t.Version="0x12";Check(!Valida(t),"Versión incompleta rechazada");
t=Tarifa();t.Motivo=" ";Check(!Valida(t),"Motivo requerido");
Check(!Valida(new(){Codigo="BUS",Nombre=" ",Motivo="Alta"}),"Nombre requerido");
Check(Valida(new(){Codigo="BUS",Nombre="Transporte",Motivo="Alta"}),"Arancel configurable");
Check(Valida(new(){Accion="Mapeo",Origen="Mensualidades",ArancelId=1,Motivo="Vinculación"}),"Origen permitido");
Check(!Valida(new(){Accion="Mapeo",Origen="Pagos",ArancelId=1,Motivo="Vinculación"}),"No confundir pagos con obligaciones");
Check(Valida(new(){Accion="Preparar",Motivo="Revisión"}),"Preparación válida");
Check(!Valida(new(){Accion="Cobrar",Motivo="Intento"}),"Cobro no expuesto por catálogo");

// SQL rowversion debe viajar como 0x + 16 dígitos, nunca como System.Byte[].
var bytes=new byte[]{0x00,0x00,0x00,0x00,0x00,0x00,0xAF,0x01};
var token=LiceoWeb.Data.RowVersionToken.DesdeSql(bytes);
Check(token=="0x000000000000AF01","Rowversion binaria preserva ceros y los 8 bytes");
Check(LiceoWeb.Data.RowVersionToken.DesdeSql("0x000000000000af01")=="0x000000000000af01","Versión hexadecimal existente conservada");
Check(LiceoWeb.Data.RowVersionToken.DesdeSql(new byte[8])=="0x0000000000000000","Versión binaria cero no se pierde");
t=Tarifa();t.Id=1;t.Version=token;Check(Valida(t),"Tarifa editable con versión procedente de SQL binario");
Check(Valida(new(){Id=1,Codigo="LAB",Nombre="Laboratorio",Activo=false,Motivo="Desactivar arancel",Version=token}),"Inactivar arancel con versión procedente de SQL binario");
foreach(var invalid in new object[]{new byte[7],new byte[9],DBNull.Value,"System.Byte[]","0x12","0x000000000000000G","0x0000000000000001\n"})
{
 bool rejected=false;try{LiceoWeb.Data.RowVersionToken.DesdeSql(invalid);}catch(System.IO.InvalidDataException){rejected=true;}
 Check(rejected,"No fabricar versión ante datos SQL inválidos: "+invalid.GetType().Name);
}
