# Calificaciones: instalación y uso

## Instalación en una copia de desarrollo
1. Actualizar la rama revision-profesor-2026-10-29. Respaldar la base.
2. Tener instaladas las migraciones 004 y 005, Identity, Registrar_Auditoria y planificación.
3. Ejecutar una sola vez `database/migrations/006_Calificaciones.sql` en LiceoWeb_Dev. Conserva las evaluaciones anteriores como cuantitativas.
4. Ejecutar completo `database/procedures/Notas.sql` en SSMS (incluye GO).
5. Volver a ejecutar `database/procedures/Planificacion.sql`: ahora impide incorporar estudiantes después de publicar resultados y en períodos cerrados. La versión nueva requiere la migración 006.
6. Compilar y ejecutar. El menú Calificaciones aparece para Administrador y Profesor; Cajero no tiene acceso.

## Flujo
1. Administración crea los tipos de evaluación desde Calificaciones → Crear tipo de evaluación. Los nombres los define el colegio; no se insertan datos de demostración.
2. Crear el grupo, inscribir a sus estudiantes y asignar al profesor mediante planificación.
3. En Calificaciones seleccionar grupo/asignatura. El profesor solo puede ver y modificar sus asignaciones; administración puede trabajar todas.
4. Crear evaluaciones: nombre, tipo, fecha del período y modalidad. En cuantitativas, máximo y peso son distintos: un examen de 30 puntos puede valer 30 % o el porcentaje acordado. Los pesos acumulados no pueden superar 100 %.
5. Para cualitativas, escribir entre 2 y 20 resultados, uno por línea. No se convierten a números y no suman al peso numérico. No hay equivalencias ni umbral de aprobación inventados.
6. Abrir Ver resultados y luego Calificar junto al estudiante. Guardar un resultado a la vez. Vacío significa pendiente; cero significa calificado con cero. Las observaciones son académicas.
7. Revisar el resumen: suma de nota/máximo × peso. Por ejemplo, 21/30×30 + 56/70×70 = 77. El acumulado parcial no es una calificación final; se muestra cantidad de pendientes y peso configurado. Consultar resultados cualitativos en cada evaluación.
8. Revisar publicación → Confirmar publicación y bloquear. Exige estudiantes, evaluaciones, todos los resultados y peso numérico exactamente 100 % si hay evaluaciones numéricas. Las asignaturas solo cualitativas no necesitan pesos.

Publicar es una operación interna. No envía notificaciones, no crea portal de padres y no cierra todo el período. Una asignatura publicada no admite cambios; su grupo tampoco admite estudiantes nuevos. Revisar todo ANTES de confirmar. La reapertura administrativa con historial y el cierre integral del período están disponibles instalando 007; ver CierreAcademico.md.

## Archivos y responsabilidades
- `ViewModels/NotasInput.cs`: validación de formularios, precisión decimal y definición de escala.
- `Repositories/NotasRepository.cs`: parámetros SQL tipados; usuario obtenido del servidor, nunca del formulario.
- `Services/NotasService.cs`: valida antes de guardar y toma la cuenta autenticada.
- `Pages/Notas/Index.cshtml(.cs)`: selección, configuración, captura, consulta y confirmación. GET no modifica; POST usa antifalsificación de Razor Pages. Respuestas sin caché.
- `006_Calificaciones.sql`: amplía evaluaciones y notas, crea opciones cualitativas y registro de publicación.
- `Notas.sql`: autorización por asignación en consultas y escrituras, reglas de notas, concurrencia y publicación. La escala y el máximo válidos siempre provienen de la base.
- `Planificacion.sql`: protege la composición de grupos publicados y períodos cerrados.

## Concurrencia e integridad
Las escrituras usan una transacción y el bloqueo de aplicación Liceo.Planificacion compartido con planificación. Serializa cambios para el volumen de un colegio y evita publicar mientras se incorpora un alumno. Reemplaza el bloqueo solo por asignación propuesto inicialmente para cubrir también esta interacción. Todas las futuras mutaciones académicas deben respetarlo.
Cada nota usa rowversion. Dos formularios sobre la misma versión no se sobreescriben: el segundo recibe conflicto y debe recargar. Las modificaciones registran auditoría de operación, no el texto de las observaciones. Desde 007, cada modificación exige motivo y conserva valor y observación anterior/nuevo; no se reconstruye historia previa.
No se habilita edición/eliminación de la definición de evaluaciones ni edición/inactivación de tipos. Esto evita cambiar silenciosamente la escala aplicada; esas operaciones requieren un flujo de corrección posterior.

## Pruebas
- `dotnet run --project tests/NotasValidation`: 16 casos de formulario sin base de datos.
- `database/verification/006_VerificarNotas.sql`: siete escenarios SQL, cada uno revertido: nota cero, ponderación y cualitativas/publicación válidas; máximo excedido; pesos excedidos; conflicto sin token; publicación incompleta; cambios tras publicación; resultado fuera de escala. Requiere cuentas Administrador/Profesor y un estudiante existente de prueba. Ejecutar sin actividad concurrente, en desarrollo. Puede avanzar identidades.
- Pruebas manuales obligatorias: Profesor A intentando abrir/guardar asignación de B; Cajero entrando por URL y POST; dos pestañas guardando una misma nota; publicación e inscripción simultáneas; período cerrado; edición de pendiente; profesores con grupos vacíos.
- Las comprobaciones de sintaxis y C# NO sustituyen la ejecución en SQL Server ni las pruebas autenticadas.

Verificación de esta entrega: compilación completa y Razor con 0 errores y 40 advertencias anteriores; 16 pruebas nuevas C# aprobadas; scripts aceptados por ScriptDom. HTTP sin sesión: portada/login 200, registro 404 y /Notas y /Planificacion redirigen al login (302). No se ejecutaron los procedimientos en SQL Server ni las pruebas con docentes autenticados.

Actualización 007: la versión actual de Notas.sql requiere 007_HistorialCierreAcademico.sql. Instalar también CierreAcademico.sql. El motivo es obligatorio para modificar notas existentes.
