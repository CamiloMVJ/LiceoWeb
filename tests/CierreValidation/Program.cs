using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
static bool Valida(object x)=>Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
static void Check(bool ok,string nombre){if(!ok)throw new Exception(nombre);Console.WriteLine("OK: "+nombre);}
static CierreAcademicoInput Cierre()=>new(){PeriodoId=1,Version="0x0000000000000001",Motivo="Revisión administrativa completada"};
Check(Valida(Cierre()),"Cierre válido");
var c=Cierre();c.PeriodoId=0;Check(!Valida(c),"Período requerido");
c=Cierre();c.Motivo=" ";Check(!Valida(c),"Motivo en blanco rechazado");
c=Cierre();c.Motivo=new string('x',501);Check(!Valida(c),"Motivo largo rechazado");
c=Cierre();c.Version="";Check(!Valida(c),"Versión requerida");
c=Cierre();c.Version="0x01";Check(!Valida(c),"Versión corta rechazada");
c=Cierre();c.Accion="ReabrirAsignacion";Check(!Valida(c),"Asignación requerida para reapertura");
c.AsignacionId=1;Check(Valida(c),"Reapertura de asignación válida");
c=Cierre();c.Accion="ReabrirPeriodo";Check(Valida(c),"Reapertura de período válida");
c=Cierre();c.Accion="Borrar";Check(!Valida(c),"Acción desconocida rechazada");
var n=new NotasInput{Accion="Nota",AsignacionId=1,EvaluacionId=1,Registro="E1",Version="0x0000000000000001",Nota=0};
Check(!Valida(n),"Corrección exige motivo");n.Motivo="Rectificación";Check(Valida(n),"Corrección con motivo y cero válida");
