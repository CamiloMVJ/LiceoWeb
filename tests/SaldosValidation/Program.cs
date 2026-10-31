using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
static bool Valid(SaldosModel.RevisionInput x)=>Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
static void Check(bool x,string n){if(!x)throw new Exception(n);Console.WriteLine("OK: "+n);}
var x=new SaldosModel.RevisionInput{Registro="E_0000001",Huella="0x"+new string('A',64),Decision="Aprobado",Referencia="Libro de caja",Motivo="Revisión documental"};
Check(Valid(x),"Revisión válida");x.Huella="0x01";Check(!Valid(x),"Huella incompleta rechazada");x.Huella="0x"+new string('A',64);
x.Decision="Cobrar";Check(!Valid(x),"Acción ajena rechazada");x.Decision="Rechazado";Check(Valid(x),"Rechazo válido");
x.Referencia=" ";Check(!Valid(x),"Respaldo obligatorio");x.Referencia="Libro";
x.Motivo="";Check(!Valid(x),"Motivo obligatorio");x.Motivo="Revisión";
x.RevisionAnterior=-1;Check(!Valid(x),"Revisión negativa rechazada");
