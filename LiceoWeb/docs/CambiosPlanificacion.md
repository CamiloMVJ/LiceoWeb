# Cambios de docente y traslados de estudiantes (019)

## Desde la interfaz
Solo Administrador puede abrir las páginas, confirmar los cambios y consultar el historial. En Planificación, la tabla Asignaciones ofrece **Cambiar docente** y EstudiantesGrupo ofrece **Trasladar**. El enlace abre la confirmación; no modifica datos. Seleccionar destino, indicar motivo de 10 a 500 caracteres y confirmar. La pantalla de historial muestra datos anteriores/nuevos, motivo, fecha local de Nicaragua y responsable, en páginas de 50 cambios.

### Cambiar docente
Se conserva la asignación, sus evaluaciones, horarios y calificaciones. El profesor nuevo obtiene acceso a esa asignación por las comprobaciones existentes de Notas/Mi horario; el anterior deja de tener acceso por su rol Profesor. Un usuario que además sea Administrador conserva su acceso administrativo. La autoría original de las calificaciones y su historial no se modifica.

El período debe estar abierto y la asignatura no puede tener publicaciones, incluso si posteriormente se reabrieron. La cuenta nueva debe tener rol Profesor y no estar bloqueada por Identity. Se validan todos sus horarios vigentes contra las clases del nuevo docente, considerando día, horas y fechas de los períodos. Los horarios cancelados no bloquean. Las confirmaciones de cancelación abiertas antes de cambiar docente quedan desactualizadas para exigir revisión.

### Trasladar estudiante
Solo entre grupos distintos del **mismo pensum y período**, con cupo y catálogos activos. El expediente debe estar activo y coincidir con modalidad/nivel; se exige la matrícula anual compatible (académica después del corte, histórica antes del corte). Cambia la pertenencia actual del estudiante y conserva el grupo de origen en la instantánea histórica. No crea matrícula adicional, deuda ni recibos.

No se permite trasladar si cualquiera de los dos grupos tiene publicaciones o si el estudiante tiene registros de calificación o historial de calificaciones en origen/destino. Esto incluye registros pendientes con nota nula: no se eliminan ni se reinterpretan. Otros estudiantes pueden tener notas no publicadas; el alumno trasladado quedará pendiente en las evaluaciones del nuevo grupo. No implementa equivalencias de notas, cambio de nivel/modalidad/año, ni traslado durante un período cerrado. Esos casos requieren definir y aprobar el tratamiento académico; esta entrega no mueve notas automáticamente.

## Archivos y ejecución manual
Detener la aplicación y respaldar la base de desarrollo. Descargar la rama revision-profesor-2026-10-29. Mantener instaladas las etapas anteriores hasta 018 y Planificacion.sql de esa etapa. En SSMS, seleccionar LiceoWeb_Dev y ejecutar:

1. `database/migrations/019_CambiosPlanificacion.sql`, una sola vez. Agrega versiones a AsignacionDocente/GrupoEstudiante y tabla CambioPlanificacion. Una instalación previa o parcial detiene el script.
2. `database/procedures/Planificacion_Cambiar.sql`: valida permisos, destino, cupo/notas/publicaciones/cruces; guarda el cambio, las instantáneas y la auditoría en una transacción.
3. `database/procedures/Planificacion_CambioConsultar.sql`: obtiene el origen y opciones de destino para la confirmación.
4. `database/procedures/Planificacion_CambiosHistorial.sql`: historial paginado.
5. Compilar e iniciar la aplicación. Cada procedimiento tiene archivo propio, con CREATE OR ALTER; no necesita SQLCMD ni instalador automático.

No se modifica el esquema financiero ni hace falta ejecutar nuevamente migraciones anteriores. El procedimiento de cambio consulta la matrícula existente para validar el traslado.

## Código
- CambioPlanificacionInput: valida los datos y separa los campos válidos para docente/estudiante.
- CambioPlanificacionRepository: parámetros SQL tipados y lectura de resultados.
- Planificacion/Cambiar: confirmación por POST, antifalsificación y manejo de errores.
- Planificacion/HistorialCambios: listado protegido, sin caché.
- Parciales _Asignaciones/_EstudiantesGrupo: enlaces desde las filas reales de Planificación.

El servidor vuelve a comprobar las reglas al confirmar; la lista de destinos no garantiza que continúe disponible. El control de versión rechaza formularios desactualizados. El GUID y el hash de la solicitud evitan duplicados en reintentos; otro contenido con el mismo GUID se rechaza. Los cambios usan Liceo.Planificacion, igual que notas, inscripción, cancelación y cierre; el traslado toma primero el bloqueo financiero para respetar el orden de matrícula/corte. No se ofrece una función de deshacer; otro cambio válido requiere nueva confirmación y deja otro evento.

## Verificación
- `dotnet run --project tests/CambioPlanificacionValidation`: 19 pruebas de entradas.
- `dotnet run --project tests/CancelarHorarioValidation`: 12 pruebas de regresión.
- `database/verification/019_VerificarCambiosPlanificacion.sql`: 13 escenarios con rollback. Requiere una copia de desarrollo con corte aplicado, Administrador y dos Profesores habilitados, el primero sin rol Administrador. No crea cuentas ni aplica el corte. Comprueba cambio/reintento, autoría de notas, invalidación de versiones de horario, cruce, cierre/publicaciones, versión antigua, traslado sin duplicar matrícula/cargo, cupo lleno, notas existentes, distinto período, permisos y operación reutilizada. Los contadores pueden avanzar; ejecutar sin actividad concurrente.
- Pendiente en SQL Server: dos traslados hacia el último cupo; cambio docente concurrente con nota/publicación/horario; reintento tras pérdida de respuesta; fallo de auditoría; profesor anterior enviando un formulario que dejó abierto; rutas/POST como Cajero; traslado previo al corte; visualización autenticada del historial y teclado/móvil.

La aplicación/Razor compila sin errores, con 40 advertencias previas. SQL revisado sintácticamente con ScriptDom. Las rutas nuevas redirigen al login sin sesión. Las pruebas SQL, cifras y concurrencia real no se han ejecutado en este entorno.

Siguientes pendientes: edición de definiciones de evaluación; desactivación/cambio de roles de personal protegiendo al último administrador; pruebas integradas con usuarios reales. Los traslados con notas/publicaciones requieren una política académica específica y siguen fuera del flujo implementado.
