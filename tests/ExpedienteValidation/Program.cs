using System;
using System.Linq;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
static class Program
{
 static ExpedienteInput Valido()=>new(){NombreEstudiante="Prueba",Modalidad="Primaria",Grado="1er Grado",FechaNacimiento=new DateOnly(2018,1,1),Sexo="F",Direccion="Prueba",Tutor="Madre",Madre=new(){Nombre="Responsable",Telefono="88888888"}};
 static bool Valida(ExpedienteInput input){var errors=new List<ValidationResult>();return Validator.TryValidateObject(input,new ValidationContext(input),errors,true);}
 static void Check(bool valid,string label){if(!valid)throw new Exception(label);Console.WriteLine("OK: "+label);}
 static void Main(){
  Check(Valida(Valido()),"Registro válido sin padre conocido");
  var i=Valido();i.TipoIngreso="Traslado";Check(!Valida(i),"Traslado sin código rechazado");
  i.CodigoTraslado="REF";i.CentroProcedencia="Centro";Check(Valida(i),"Traslado completo");
  i=Valido();i.Tutor="Otro";i.Otro=new(){Nombre="Abuela",Telefono="12345678"};Check(!Valida(i),"Tercero sin parentesco rechazado");
  i.Otro.Parentesco="Abuela";Check(Valida(i),"Tutor tercero válido");
  i=Valido();i.FechaNacimiento=new DateOnly(2099,1,1);Check(!Valida(i),"Nacimiento futuro rechazado");
  i=Valido();i.TipoSangre="XYZ";Check(!Valida(i),"Tipo de sangre inválido rechazado");
  i=Valido();i.Motivo=" ";Check(!Valida(i),"Motivo vacío rechazado");
 }
}
