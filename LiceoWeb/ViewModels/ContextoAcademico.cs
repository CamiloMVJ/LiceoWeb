using System.Data;
namespace LiceoWeb.ViewModels;

// Contexto de navegación; no sustituye permisos ni validaciones transaccionales SQL.
public sealed class ContextoAcademico(DataSet datos, int anio, int pensum, int grupo)
{
    public int Anio { get; private set; } = anio;
    public int Pensum { get; private set; } = pensum;
    public int Grupo { get; private set; } = grupo;
    public IEnumerable<DataRow> Filas(string tabla) => datos.Tables.Contains(tabla) ? datos.Tables[tabla]!.AsEnumerable() : [];
    public static bool Disponible(DataRow r) => (!r.Table.Columns.Contains("Activo") || r.Field<bool>("Activo")) && (!r.Table.Columns.Contains("Disponible") || r.Field<bool>("Disponible"));
    public IEnumerable<DataRow> Activos(string tabla) => Filas(tabla).Where(Disponible);
    public void Normalizar()
    {
        if (!Activos("Anios").Any(r => r.Field<int>("Id") == Anio)) Anio = 0;
        if (!Opciones("Pensums").Any(r => r.Field<int>("Id") == Pensum)) Pensum = 0;
        if (!Opciones("Grupos").Any(r => r.Field<int>("Id") == Grupo)) Grupo = 0;
    }
    public IEnumerable<DataRow> Opciones(string tabla) => Activos(tabla).Where(r => tabla switch
    {
        "Pensums" or "Periodos" => Anio > 0 && r.Field<int>("AnioId") == Anio,
        "Grupos" => Pensum > 0 && r.Field<int>("PensumId") == Pensum,
        "Asignaciones" => Grupo > 0 && r.Field<int>("GrupoId") == Grupo,
        _ => true
    });
    public IEnumerable<DataRow> Materias => Filas("Materias").Where(r => Pensum > 0 && r.Field<int>("PensumId") == Pensum);
    public IEnumerable<DataRow> Asignaciones => Filas("Asignaciones").Where(r => Grupo > 0 && r.Field<int>("GrupoId") == Grupo);
    public IEnumerable<DataRow> Estudiantes => Filas("EstudiantesGrupo").Where(r => Grupo > 0 && r.Field<int>("GrupoId") == Grupo);
    public IEnumerable<DataRow> Horarios => Filas("Horario").Where(r => Asignaciones.Any(a => a.Field<int>("Id") == r.Field<int>("AsignacionId")));
    public IEnumerable<DataRow> MateriasDisponibles(string accion) => Activos("Asignaturas").Where(r => accion == "Docente"
        ? Materias.Any(m => m.Field<int>("AsignaturaId") == r.Field<int>("Id")) && !Asignaciones.Any(a => a.Field<int>("AsignaturaId") == r.Field<int>("Id"))
        : !Materias.Any(m => m.Field<int>("AsignaturaId") == r.Field<int>("Id")));
    public string Etiqueta(string tabla, int id) => Filas(tabla).FirstOrDefault(r => r.Field<int>("Id") == id)?["Etiqueta"].ToString() ?? "Sin seleccionar";
}
