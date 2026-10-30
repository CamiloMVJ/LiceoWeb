using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using LiceoWeb.ViewModels;
static class Program
{
 static bool Valida(object input)=>Validator.TryValidateObject(input,new ValidationContext(input),new List<ValidationResult>(),true);
 static void Check(bool valid,string label){if(!valid)throw new Exception(label);Console.WriteLine("OK: "+label);}
 static void Main(){
  Check(Valida(new CatalogoInput{Tipo="Anios",Anio=2027}),"Año válido");
  Check(!Valida(new CatalogoInput{Tipo="Anios",Anio=0}),"Año inválido");
  Check(!Valida(new CatalogoInput{Tipo="Aulas",Nombre="A",Ubicacion="PB",Capacidad=0}),"Capacidad inválida");
  Check(Valida(new CatalogoInput{Tipo="Aulas",Nombre="A",Ubicacion="PB",Capacidad=25}),"Aula válida");
  Check(!Valida(new CatalogoInput{Tipo="Periodos",Nombre="I",AnioId=1,Inicio=new(2027,5,1),Fin=new(2027,1,1)}),"Período invertido");
  Check(Valida(new CatalogoInput{Tipo="Aulas",Id=1,SoloEstado=true,Activo=false}),"Inactivación sin borrar");
  Check(!Valida(new CatalogoInput{Tipo="Periodos",Id=1,SoloEstado=true}),"Cierre de período no expuesto como inactivación");
  Check(!Valida(new PlanificacionInput{Accion="Horario",AsignacionId=1,Dia=1,Inicio=new(10,0),Fin=new(9,0)}),"Horario invertido");
  Check(!Valida(new PlanificacionInput{Accion="Horario",AsignacionId=1,Dia=8,Inicio=new(9,0),Fin=new(10,0)}),"Día inválido");
  Check(Valida(new PlanificacionInput{Accion="Horario",AsignacionId=1,Dia=1,Inicio=new(9,0),Fin=new(10,0)}),"Horario válido");
  Check(!Valida(new PlanificacionInput{Accion="Docente",GrupoId=1,AsignaturaId=1}),"Docente requerido");
  Check(!Valida(new PlanificacionInput{Accion="SQL"}),"Acción no permitida");
 }
}
