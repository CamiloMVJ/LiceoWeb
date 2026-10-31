# Planificación académica

## Instalación
Requiere 004_RevisionProfesor.sql, 006_Calificaciones.sql y Registrar_Auditoria. La versión actual protege los grupos con notas publicadas. No hay nueva migración de tablas en esta etapa. Ejecutar completo database/procedures/Planificacion.sql en LiceoWeb_Dev (SSMS, incluye GO). Compilar y ejecutar la aplicación.

## Flujo del administrador
1. Catálogos académicos: crear año; período (fechas del mismo año); modalidades, turnos, aulas con ubicación/capacidad; asignaturas con código. Los horarios dominicales se representan con día 7; no confundir día/turno con nivel educativo.
2. Planificación → Pensum: elegir año/modalidad/nivel. Por compatibilidad, modalidad y nivel deben coincidir con los valores de las matrículas existentes al inscribir estudiantes (por ejemplo Primaria y 1er Grado).
3. Materia: incorporar las asignaturas al pensum ANTES de crear grupos. No se cambia el plan histórico una vez usado.
4. Grupo: seleccionar pensum, período del mismo año, turno, aula y sección.
5. Docente: asignar una cuenta con rol Profesor a una materia del pensum. Una asignación por grupo/materia.
6. Horario: elegir asignación, día 1–7 y horas. Intervalos [Inicio,Fin): una clase puede comenzar exactamente al finalizar otra. Se comparan grupos, aulas y docentes de períodos cuyas fechas se superponen.
7. Estudiante: ingresar código de estudiante activo y seleccionar grupo. Requiere matrícula existente del mismo año/modalidad/nivel, plaza disponible y no estar en otro grupo del mismo período. NO crea la matrícula financiera ni un pago.
8. Profesor: Mi horario muestra solo asignaciones de su propia cuenta. No acepta un identificador de otro profesor en el formulario.

## Integridad
La autorización se comprueba en PageModels y procedimientos. Todas las mutaciones toman el bloqueo de aplicación Liceo.Planificacion con dueño Transaction, y escriben auditoría. Este bloqueo serializa cambios de planificación para el volumen de un colegio; futuros procedimientos de cambios de horarios deben respetarlo. La asignación de estudiante también bloquea su fila conforme al contrato financiero.

Catálogos permiten alta, consulta, edición antes de uso y activación/inactivación (períodos no usan esa operación). No hay DELETE. Los objetos ya usados no cambian su definición histórica. La inactivación impide nuevas selecciones de catálogo al crear planes/grupos, pero no borra las clases existentes. El cierre de período está implementado desde 007 (CierreAcademico.md); la sustitución de asignaciones sigue pendiente.

Los números Id visibles en algunas tablas son referencias de los catálogos; los desplegables muestran etiquetas. No hay datos de demostración ni inserciones automáticas de materias o turnos.

## Pruebas
- dotnet run --project tests/PlanificacionValidation: validaciones de año, aula, período, acciones, docente y horario.
- database/verification/005_VerificarPlanificacion.sql: requiere cuentas Administrador y Profesor; crea plan y horarios adyacentes, provoca conflicto y verifica rollback. Ejecutar en desarrollo sin actividad concurrente. Secuencias/identidades pueden avanzar.
- Probar GET/POST de Catalogos/Index como Cajero y Profesor: acceso denegado.
- Dos administradores creando horarios solapados: solo uno debe confirmar.
- Validar materia ajena al pensum, período de otro año, estudiante sin matrícula y cupo lleno.
- Como dos profesores distintos, comprobar separación de MiHorario.

## Límites de esta etapa
No se implementó aún edición/reasignación de grupos con historial, traslado entre grupos, cancelación de horarios; el cierre de período está disponible en CierreAcademico.md. Las calificaciones y su publicación están descritas en Calificaciones.md; el cierre integral de período está disponible desde 007. No confundir las pruebas C# sin DB con la ejecución integral de SQL Server.

## Verificación de esta entrega
Build de solución y Razor completado: 0 errores, 40 advertencias preexistentes. Doce pruebas de validación de planificación y ocho de expediente pasan. ScriptDom acepta los scripts nuevos. Arranque HTTP comprobado: portada/login públicos; registro cerrado; rutas internas redirigen a login sin sesión. Falta ejecutar SQL Server y pruebas autenticadas/concurrentes.
