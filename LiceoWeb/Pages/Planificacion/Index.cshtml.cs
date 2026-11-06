using System.Data;
using LiceoWeb.Repositories;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Planificacion;

[Authorize(Policy = "SoloAdministrador")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class IndexModel(PlanificacionRepository repository, PlanificacionService service, UsuarioActual usuario, ILogger<IndexModel> logger) : PageModel
{
    public static readonly string[] Acciones = ["Base", "Pensum", "Materia", "Grupo", "Docente", "Horario", "Estudiante", "Listo"];
    public static string Titulo(string accion) => accion switch { "Base" => "Preparar año", "Pensum" => "Plan de estudios", "Materia" => "Materias del plan", "Grupo" => "Crear grupos", "Docente" => "Asignar docentes", "Horario" => "Organizar horarios", "Estudiante" => "Inscribir estudiantes", _ => "Ir a calificaciones" };
    // Se valida únicamente el formulario enviado, no el catálogo y el plan simultáneamente.
    [BindProperty, ValidateNever] public PlanificacionInput Input { get; set; } = new();
    [BindProperty, ValidateNever] public CatalogoInput Catalogo { get; set; } = new();
    [BindProperty(SupportsGet = true)] public int Anio { get; set; }
    [BindProperty(SupportsGet = true)] public int Pensum { get; set; }
    [BindProperty(SupportsGet = true)] public int Grupo { get; set; }
    public ContextoAcademico Contexto { get; private set; } = new(new(), 0, 0, 0);
    public bool Cargado { get; private set; }
    public bool MostrarCatalogo { get; private set; }
    [TempData] public string? Mensaje { get; set; }
    public string Siguiente => Acciones[Math.Min(Array.IndexOf(Acciones, Input.Accion) + 1, Acciones.Length - 1)];
    public string Enlace(string accion, string? catalogo = null, int id = 0) => Url.Page("/Planificacion/Index", new { accion, anio = Anio, pensum = Pensum, grupo = Grupo, catalogo, id })!;
    public IEnumerable<SelectListItem> Opciones(string tabla) => (tabla == "Asignaturas" ? Contexto.MateriasDisponibles(Input.Accion) : Contexto.Opciones(tabla)).Select(r => new SelectListItem(r["Etiqueta"].ToString(), r["Id"].ToString()));
    public string? Pendiente => Input.Accion switch
    {
        "Base" => null,
        _ when Anio == 0 => "Selecciona un año activo o créalo en Preparar año.",
        "Pensum" when !Contexto.Activos("Modalidades").Any() => "Agrega una modalidad antes de crear el plan.",
        "Pensum" => null,
        _ when Pensum == 0 => "Selecciona un plan de estudios o créalo en el paso 2.",
        "Materia" when Contexto.Filas("Grupos").Any(r => r.Field<int>("PensumId") == Pensum) => "Este plan ya tiene grupos y conserva sus materias históricas. Para un plan diferente crea otro antes de abrir sus grupos.",
        "Materia" when !Contexto.MateriasDisponibles("Materia").Any() => "No quedan asignaturas activas por agregar. Crea otra aquí si hace falta o continúa con los grupos.",
        "Materia" => null,
        "Grupo" when !Contexto.Materias.Any() => "Agrega las materias del plan antes de crear sus grupos.",
        "Grupo" when !Contexto.Opciones("Periodos").Any() => "Crea un período abierto para este año.",
        "Grupo" when !Contexto.Activos("Turnos").Any() || !Contexto.Activos("Aulas").Any() => "Agrega un turno y un aula activos para crear el grupo.",
        "Grupo" => null,
        _ when Grupo == 0 => "Selecciona un grupo o créalo en el paso 4.",
        "Docente" when !Contexto.Activos("Docentes").Any() => "Crea una cuenta activa con rol Profesor en Cuentas del personal.",
        "Docente" when !Contexto.MateriasDisponibles("Docente").Any() => "Las materias disponibles ya tienen docente. Puedes revisar sus asignaciones o continuar con los horarios.",
        "Horario" when !Contexto.Opciones("Asignaciones").Any() => "Asigna docentes a las materias antes de organizar sus horarios.",
        _ => null
    };
    private async Task CargarAsync()
    {
        try
        {
            var datos = await repository.ConsultarAsync(usuario.ObtenerId());
            if (datos.Tables["Materias"]?.Columns.Contains("AsignaturaId") != true || datos.Tables["Asignaciones"]?.Columns.Contains("Activo") != true)
                throw new InvalidDataException("Planificacion_Consultar necesita actualizarse desde Planificacion.sql.");
            Contexto = new(datos, Anio, Pensum, Grupo); Contexto.Normalizar();
            Anio = Contexto.Anio; Pensum = Contexto.Pensum; Grupo = Contexto.Grupo;
            Cargado = true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Consultar espacio académico");
            ModelState.AddModelError("", "No se pudo cargar la planificación. Revisa la conexión y actualiza Planificacion.sql antes de usar este flujo.");
        }
    }
    public async Task<IActionResult> OnGetAsync(string accion = "Base", string? catalogo = null, int id = 0)
    {
        if (!Acciones.Contains(accion) || Anio < 0 || Pensum < 0 || Grupo < 0 || id < 0 || (catalogo is not null && !CatalogosModel.Tipos.Contains(catalogo))) return BadRequest();
        Input.Accion = accion; MostrarCatalogo = catalogo is not null || accion == "Base";
        Catalogo.Tipo = catalogo ?? "Anios"; Catalogo.AnioId = Anio > 0 ? Anio : null;
        await CargarAsync();
        if (!Cargado) return Page();
        Input.AnioId = Anio; Input.PensumId = Pensum; Input.GrupoId = Grupo;
        if (id > 0)
        {
            var r = Contexto.Filas(Catalogo.Tipo).FirstOrDefault(r => r.Field<int>("Id") == id);
            if (r is null) return NotFound();
            Catalogo.Id = id;
            if (r.Table.Columns.Contains("Nombre")) Catalogo.Nombre = r.Field<string>("Nombre");
            if (r.Table.Columns.Contains("Activo")) Catalogo.Activo = r.Field<bool>("Activo");
            if (Catalogo.Tipo == "Anios") Catalogo.Anio = r.Field<int>("Anio");
            if (Catalogo.Tipo == "Periodos") { Catalogo.AnioId = r.Field<int>("AnioId"); Catalogo.Inicio = DateOnly.FromDateTime(r.Field<DateTime>("Inicio")); Catalogo.Fin = DateOnly.FromDateTime(r.Field<DateTime>("Fin")); }
            if (Catalogo.Tipo == "Aulas") { Catalogo.Ubicacion = r.Field<string>("Ubicacion"); Catalogo.Capacidad = r.Field<int>("Capacidad"); }
            if (Catalogo.Tipo == "Asignaturas") Catalogo.Codigo = r.Field<string>("Codigo");
        }
        return Page();
    }
    public async Task<IActionResult> OnPostAsync(bool continuar = false)
    {
        if (!Acciones.Contains(Input.Accion) || Input.Accion is "Base" or "Listo") return BadRequest();
        await CargarAsync();
        if (!Cargado) return Page();
        Input.AnioId = Anio; Input.PensumId = Pensum; Input.GrupoId = Grupo;
        if (Input.Accion == "Pensum")
        {
            var modalidad = GradosEscolares.ModalidadDe(Input.Nivel);
            Input.ModalidadId = Contexto.Activos("Modalidades").FirstOrDefault(r => string.Equals(r.Field<string>("Nombre"), modalidad, StringComparison.OrdinalIgnoreCase))?.Field<int>("Id") ?? 0;
            if (Input.ModalidadId == 0) ModelState.AddModelError("", "El grado requiere una modalidad activa con su nombre correspondiente (Preescolar, Primaria o Secundaria). Agrégala desde este paso.");
        }
        if (Pendiente is not null) ModelState.AddModelError("", Pendiente);
        if (Input.Accion == "Horario" && !Contexto.Opciones("Asignaciones").Any(r => r.Field<int>("Id") == Input.AsignacionId)) ModelState.AddModelError("", "Selecciona una clase activa del grupo actual.");
        TryValidateModel(Input, nameof(Input));
        if (ModelState.IsValid)
        {
            try
            {
                int id = await service.GuardarPlanAsync(Input);
                // Identificador devuelto por la misma transacción: no buscar por MAX(Id).
                if (Input.Accion == "Pensum") { Anio = Input.AnioId; Pensum = id; Grupo = 0; }
                if (Input.Accion == "Grupo") Grupo = id;
                Mensaje = "Guardado. Puedes seguir trabajando en este contexto.";
                return Redirect(Enlace(continuar ? Siguiente : Input.Accion));
            }
            catch (SqlException ex) when (ex.Number is >= 52300 and <= 52316) { ModelState.AddModelError("", ex.Message); }
            catch (SqlException ex) when (ex.Number is 2601 or 2627) { ModelState.AddModelError("", "Ese registro ya existe. No se duplicó."); }
            catch (Exception ex) { logger.LogError(ex, "Guardar planificación"); ModelState.AddModelError("", "No se pudo guardar. Revisa la conexión y la versión de Planificacion.sql."); }
        }
        await CargarAsync(); return Page();
    }
    public async Task<IActionResult> OnPostCatalogoAsync()
    {
        if (!Acciones.Contains(Input.Accion) || !CatalogosModel.Tipos.Contains(Catalogo.Tipo)) return BadRequest();
        MostrarCatalogo = true;
        TryValidateModel(Catalogo, nameof(Catalogo));
        if (ModelState.IsValid)
        {
            try
            {
                int id = await service.GuardarCatalogoAsync(Catalogo);
                if (Catalogo.Tipo == "Anios" && Catalogo.Activo && !Catalogo.SoloEstado) { Anio = id; Pensum = 0; Grupo = 0; }
                Mensaje = "Dato guardado. Continúa con el paso en el que estabas.";
                return Redirect(Enlace(Input.Accion, Input.Accion == "Base" ? Catalogo.Tipo : null));
            }
            catch (SqlException ex) when (ex.Number is >= 52300 and <= 52316) { ModelState.AddModelError("", ex.Message); }
            catch (SqlException ex) when (ex.Number is 2601 or 2627) { ModelState.AddModelError("", "Ya existe un registro con esos datos."); }
            catch (Exception ex) { logger.LogError(ex, "Guardar catálogo integrado"); ModelState.AddModelError("", "No se pudo guardar el catálogo. Revisa la conexión y Planificacion.sql."); }
        }
        await CargarAsync(); return Page();
    }
}
