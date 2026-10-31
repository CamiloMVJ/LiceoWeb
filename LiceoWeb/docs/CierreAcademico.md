# Cierre, reapertura e historial académico

## Instalar esta continuación
1. Actualizar la rama revision-profesor-2026-10-29 y respaldar la base de desarrollo.
2. Tener instaladas las migraciones hasta 006 y los procedimientos anteriores.
3. Ejecutar una sola vez `database/migrations/007_HistorialCierreAcademico.sql` en LiceoWeb_Dev.
4. Volver a ejecutar `database/procedures/Notas.sql`: esta versión necesita las tablas/columnas de 007.
5. Ejecutar `database/procedures/CierreAcademico.sql` completo en SSMS, incluidos los GO.
6. Compilar y ejecutar. El administrador verá **Cierre e historial académico**. El profesor continúa usando Calificaciones.

No volver a ejecutar 001 ni borrar notas, publicaciones o períodos.

## Uso normal
1. Cada profesor registra y publica los resultados de sus asignaturas.
2. Administración abre Cierre e historial académico y selecciona período.
3. Revisa publicaciones e historial; escribe el motivo y confirma Cerrar período.
4. El sistema exige grupos con alumnos y materias, docente para cada materia del pensum, publicación vigente para cada asignación, evaluaciones, pesos numéricos completos y resultados válidos para todos los estudiantes.
5. Un período cerrado bloquea captura y publicación de notas, nuevos grupos, docentes, estudiantes y horarios mediante los procedimientos existentes.

Un período con un grupo vacío no puede cerrarse. Su eliminación/archivo formal no está implementado: no crear grupos de demostración en la base real.

## Corregir resultados publicados
1. Solo administración autoriza reaperturas y debe escribir un motivo.
2. Si el período está cerrado, primero confirmar Reabrir período. Esto NO desbloquea todas las asignaturas.
3. En Publicaciones, seleccionar Autorizar corrección para la asignatura necesaria y confirmar el motivo.
4. Su publicación deja de estar vigente. Se conserva el evento y una instantánea de sus resultados previos; no se borra la fila de publicación.
5. El profesor asignado o administración abre Calificaciones, modifica la nota con un motivo y guarda. Se registra valor anterior/nuevo, observaciones anteriores/nuevas, cuenta y fecha UTC.
6. Publicar nuevamente la asignatura y, si corresponde, cerrar el período otra vez. El sistema repite las validaciones.

La reapertura NO habilita nuevas inscripciones en grupos que ya tuvieron alguna publicación: se conserva la composición evaluada. Cambios de estudiantes entre grupos necesitan otro flujo con historial.

## Concurrencia e historial
- Las acciones usan el mismo bloqueo transaccional Liceo.Planificacion de notas y planificación.
- Las notas, publicaciones y períodos usan rowversion. Una pantalla antigua recibe conflicto; recargar antes de intentar nuevamente. Un error revierte también sus registros de historial.
- HistorialCalificacion conserva altas/modificaciones realizadas por el procedimiento a partir de 007. No reconstruye valores anteriores a su instalación.
- EventoAcademico conserva publicaciones, reaperturas y cierres con motivo, cuenta e instantánea JSON de resultados. La pantalla lista los últimos 200 eventos y cambios del período; el resto permanece en la base. La consulta paginada y visualización/exportación de instantáneas quedan pendientes.
- Las publicaciones anteriores a 007 conservan su estado vigente. Su primera reapertura captura los resultados existentes; no inventa una instantánea de su publicación original.
- No hay opción de borrar historial en la aplicación. Un administrador directo de SQL puede alterar tablas: estos registros no son un sistema de auditoría inviolable.
- Acceso a Cierre y a sus procedimientos solo para Administrador, sin caché. Las observaciones de notas no se envían a los logs generales.

## Qué hace cada archivo
- `007_HistorialCierreAcademico.sql`: tablas de historial/eventos, estado vigente y versiones de concurrencia.
- `Notas.sql`: registra cambios de valores y publicaciones, permite volver a publicar tras autorización.
- `CierreAcademico.sql`: valida y ejecuta las tres acciones administrativas; consulta estado e historial.
- `CierreAcademicoInput.cs`: valida operación, identificadores, motivo y formato de versión.
- `CierreAcademicoRepository.cs`: parámetros SQL tipados, consultas y guardado validados.
- `Pages/Notas/Cierre.cshtml(.cs)`: interfaz administrativa y confirmaciones mediante POST con antifalsificación.
- `NotasInput.cs` e `Index.cshtml`: solicitan motivo al modificar una nota ya guardada.

## Verificación
- Solución y Razor compilados: 0 errores, 40 advertencias anteriores.
- `dotnet run --project tests/CierreValidation`: 12 casos nuevos de entradas válidas, motivo, token y corrección.
- `dotnet run --project tests/NotasValidation`: las 16 validaciones anteriores adaptadas al motivo de corrección.
- HTTP sin sesión: portada 200; /Notas y /Notas/Cierre (también con período en la URL) redirigen al login, 302.
- Scripts revisados con ScriptDom; no equivale a ejecución en SQL Server.
- `database/verification/007_VerificarCierre.sql`: cinco escenarios, con rollback: ciclo completo y comprobación de historial, cierre incompleto, docente no administrador, versión antigua y reapertura de asignatura con período cerrado. Requiere administrador, profesor sin rol administrador y estudiante de prueba. Ejecutar en desarrollo sin actividad concurrente; las identidades pueden avanzar.
- Volver a ejecutar también `006_VerificarNotas.sql`, actualizado para incluir el motivo.
- Pruebas pendientes en SQL Server: ciclo anterior, acceso autenticado como Cajero/Profesor/Administrador, dos cierres concurrentes, cierre frente a captura y cierre frente a nuevas asignaciones. La prueba HTTP sin sesión no demuestra autorización entre roles.

## Próximo trabajo
La edición de definiciones de evaluación, reasignaciones, traslados de grupo y cancelación de horarios siguen pendientes. La adaptación financiera necesita primero conciliar el modelo de pagos anterior; no se habilita el nuevo libro para cobros reales.
