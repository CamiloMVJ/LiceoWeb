using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
var total=0;
CambioPlanificacionInput Nuevo()=>new(){Tipo="Docente",OrigenId=1,DocenteId="profesor",Version="0x0000000000000001",Operacion=Guid.NewGuid(),Motivo="Reorganización académica"};
void Probar(string nombre,Action<CambioPlanificacionInput> cambio,bool esperado)
{
 var input=Nuevo();cambio(input);var valido=Validator.TryValidateObject(input,new ValidationContext(input),new List<ValidationResult>(),true);
 if(valido!=esperado)throw new Exception(nombre);Console.WriteLine("PASS "+nombre);total++;
}
void Traslado(CambioPlanificacionInput x){x.Tipo="Estudiante";x.DocenteId=null;x.Registro="E_0000001";x.GrupoDestino=2;}
Probar("Docente válido",x=>{},true);
Probar("Versión binaria de SQL válida para cambiar docente", x=>x.Version=LiceoWeb.Data.RowVersionToken.DesdeSql(new byte[]{0,0,0,0,0,0,0,42}), true);
Probar("Traslado válido",Traslado,true);
Probar("Tipo inválido",x=>x.Tipo="SQL",false);
Probar("Origen inválido",x=>x.OrigenId=0,false);
Probar("Operación vacía",x=>x.Operacion=Guid.Empty,false);
Probar("Versión incompleta",x=>x.Version="0x01",false);
Probar("Versión no hexadecimal",x=>x.Version="0xGG00000000000001",false);
Probar("Motivo solo espacios",x=>x.Motivo=new string(' ',20),false);
Probar("Motivo corto tras trim",x=>x.Motivo="     cambio     ",false);
Probar("Motivo máximo",x=>x.Motivo=new string('a',500),true);
Probar("Motivo excesivo",x=>x.Motivo=new string('a',501),false);
Probar("Profesor sin destino",x=>x.DocenteId=null,false);
Probar("Profesor con datos de traslado",x=>x.GrupoDestino=2,false);
Probar("Profesor con registro",x=>x.Registro="E_0000001",false);
Probar("Traslado al mismo grupo",x=>{Traslado(x);x.GrupoDestino=1;},false);
Probar("Traslado sin destino",x=>{Traslado(x);x.GrupoDestino=null;},false);
Probar("Traslado sin registro",x=>{Traslado(x);x.Registro=null;},false);
Probar("Registro inválido",x=>{Traslado(x);x.Registro="incorrecto";},false);
Probar("Traslado con docente enviado",x=>{Traslado(x);x.DocenteId="profesor";},false);
Console.WriteLine($"{total} pruebas aprobadas.");
