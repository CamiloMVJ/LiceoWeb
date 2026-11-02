# Edición de definiciones de evaluación (020)

## Uso
En Calificaciones, elegir una asignación y abrir **Definición e historial** junto a la evaluación. Administrador puede gestionar todas; Profesor únicamente las de sus asignaciones actuales. Cajero no tiene acceso. Se puede corregir nombre, tipo, fecha, modalidad, máximo, peso y escala cualitativa, indicando un motivo de 10 a 500 caracteres.

La edición queda bloqueada si el período está cerrado, si la asignatura tuvo una publicación (aunque se reabriera), o si la evaluación tiene registros de Calificacion/HistorialCalificacion. Un registro pendiente con nota nula también bloquea: la definición ya se utilizó. No se modifican notas ni su autoría. La edición del catálogo global de tipos, su inactivación y la eliminación de evaluaciones no se incluyen.

La fecha debe pertenecer al período. Para cuantitativas, máximo y peso positivos con hasta dos decimales; la suma de pesos de la asignatura, excluyendo el valor anterior de la propia evaluación, no puede superar 100%. Para cualitativas se requieren 2–20 valores diferentes; el peso se fija en cero y el máximo técnico en uno. Se permite cambiar de modalidad solamente bajo las restricciones anteriores. La escala anterior queda en el historial.

Cada cambio guarda antes/después, motivo, responsable y fecha. El historial se muestra en páginas de 50 registros, en hora de Nicaragua (UTC−6). No reconstruye cambios anteriores a esta etapa. La confirmación usa POST y antifalsificación; abrir el enlace no escribe.

## Concurrencia
Edición, calificación, creación/publicación de evaluaciones y cambios académicos comparten el bloqueo Liceo.Planificacion. La versión de Evaluacion rechaza ediciones desde formularios antiguos. GUID y hash evitan duplicados al reenviar la misma operación; la misma operación con otros datos se rechaza.

La captura de notas ahora envía también VersionEvaluacion, separada de la versión de la propia calificación. Si alguien cambia la definición mientras otro tiene abierto el formulario de notas, se rechaza ese envío aunque la nota quepa en el máximo nuevo. Debe recargar y revisar el nuevo criterio. Si la calificación se guarda primero, la edición de definición se bloquea por existencia de registros. No se invalida la versión por crear otras evaluaciones; la suma de pesos se comprueba en la transacción al editar.

## Archivos y ejecución manual
Detener la aplicación y respaldar la base de desarrollo. Descargar la versión actual de revision-profesor-2026-10-29. Con las etapas anteriores hasta 019 aplicadas, seleccionar LiceoWeb_Dev en SSMS y ejecutar:

1. `database/migrations/020_EdicionEvaluaciones.sql`, una sola vez: agrega Version a Evaluacion y tabla HistorialEvaluacion.
2. `database/procedures/Evaluacion_Editar.sql`: validaciones, transacción, reintento, historial y auditoría.
3. `database/procedures/Evaluacion_ConsultarEdicion.sql`: definición, opciones e historial con autorización.
4. **`database/procedures/Notas.sql` completo**: devuelve la versión de definición y la exige al guardar notas. Actualizarlo junto con la aplicación; el código anterior no envía ese dato y sus formularios quedarán rechazados.
5. Compilar e iniciar. Recargar las páginas de calificación abiertas antes de actualizar.

Los procedimientos tienen archivo propio con CREATE OR ALTER. No hay instalador automático ni necesidad de modo SQLCMD. No repetir migraciones anteriores. La migración detecta instalación previa/parcial y se detiene sin borrar datos.

## Código
EditarEvaluacionInput valida entradas reutilizando las reglas de definición de NotasInput. EvaluacionRepository envía parámetros tipados y lee la consulta. Notas/EditarEvaluacion muestra el formulario y el historial; el texto histórico se presenta como campos académicos, no JSON. NotasRepository e Index incluyen VersionEvaluacion en la captura. Las verificaciones SQL antiguas 006 y 007 se actualizaron para enviar el nuevo dato.

## Validación
- Compilación C#/Razor: 0 errores y 40 advertencias preexistentes.
- `tests/EditarEvaluacionValidation`: 19 pruebas nuevas aprobadas.
- `tests/NotasValidation`: 18 pruebas aprobadas, incluyendo ausencia/formato de VersionEvaluacion.
- `tests/CierreValidation`: 12 pruebas aprobadas.
- Siete scripts SQL analizados con ScriptDom; no equivale a ejecución SQL Server.
- Acceso HTTP sin sesión a edición, notas y cierre redirige al login.
- `database/verification/020_VerificarEdicionEvaluaciones.sql`: 11 escenarios preparados con rollback, para copia de desarrollo sin actividad concurrente. Requiere Administrador, Profesor sin rol Administrador y estudiante de prueba. Comprueba actualización/reintento/historial, registros de notas pendientes, historia previa, publicación reabierta, período cerrado, versión antigua, pesos, nota enviada desde definición anterior, pérdida de titularidad, escala cualitativa y operación reutilizada. Los contadores pueden avanzar.

Pendiente ejecutar las verificaciones 020, 006 y 007 en SQL Server, pruebas de roles autenticados, dos pestañas y concurrencia real, revisión visual y teclado. Esta entrega no se ejecutó contra una base SQL Server.

Siguiente bloque principal: desactivación/reactivación y cambio de rol del personal, protegiendo al último administrador y renovando las sesiones afectadas. Quedan pendientes las pruebas integradas y la edición/inactivación del catálogo global de tipos.
