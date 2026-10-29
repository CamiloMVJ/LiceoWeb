using System;
using System.Collections.Generic;

namespace LiceoWeb.Pages.Mensualidades
{
    public class CobrosMensualidadModel
    {
        public string MensajeError { get; set; }
        public string MensajeExito { get; set; }
        public string ReciboGenerado { get; set; }
        public List<Estudiante> ListaEstudiantes { get; set; }
        public string RegistroSeleccionado { get; set; }
        public string NombreEstudianteActual { get; set; }
        public decimal SaldoFavorActual { get; set; }
        public string ModalidadActual { get; set; }
        public string GradoActual { get; set; }
        public string Busqueda { get; set; }
    }
}

// Definición de Estudiante si no existe
public class Estudiante
{
    public string Registro { get; set; }
    public string NombreEstudiante { get; set; }
    public string Grado { get; set; }
    public string Modalidad { get; set; }
}