# Cancelación de horarios con historial

## Uso
En Planificación, la tabla Horario muestra únicamente horarios vigentes. Cada fila ofrece Cancelar; abre una página con la clase seleccionada y solicita un motivo de 10 a 500 caracteres. Solo Administrador puede consultar, confirmar y revisar el historial. La confirmación usa POST con antifalsificación; abrir el enlace no modifica datos.

Al confirmar se conserva HorarioClase, se registra CancelacionHorario y se audita en una transacción. La instantánea conserva año, período, sección, asignatura, docente, aula y horas tal como estaban al cancelar. El historial muestra fecha local de Nicaragua, responsable y motivo, en páginas de 50 filas. No reconstruye cancelaciones previas a esta implementación.

Mi horario deja de mostrar las horas canceladas; una asignación sin horas vigentes puede seguir apareciendo sin horas. El espacio queda libre para crear otra clase. No se cancela la asignación docente, el grupo, notas, matrículas ni cargos. Un período cerrado impide cancelar. Para mover una clase, la cancelación y la creación del nuevo horario son dos pasos explícitos; si el alta nueva falla, la cancelación previa permanece y se debe resolver. No se ofrece reactivación ni modificación automática.

## Archivos y ejecución manual
Detener la aplicación y respaldar una copia de desarrollo con las etapas hasta 017. Descargar la versión actual de revision-profesor-2026-10-29. En SSMS seleccionar LiceoWeb_Dev y ejecutar, en orden:
1. `database/migrations/018_CancelacionHorarios.sql`, una sola vez. Agrega Version a HorarioClase, tabla CancelacionHorario y vista HorarioClaseVigente. Si detecta instalación previa o parcial se detiene, sin borrar datos.
2. `database/procedures/Horario_Cancelar.sql`: autorización, validación, bloqueo compartido con planificación/cierre, control de versión, reintento por operación y auditoría.
3. `database/procedures/Horario_Consultar.sql`: datos para confirmar una cancelación, solo administración.
4. `database/procedures/Horario_Historial.sql`: historial paginado, solo administración.
5. `database/procedures/Planificacion.sql`: actualiza cruces de horarios, listado administrativo y Mi horario para consumir solo horarios vigentes. Obligatorio; el código anterior seguiría mostrando los cancelados.
6. Compilar/iniciar la aplicación. Los archivos de procedimientos contienen CREATE OR ALTER y pueden volverse a aplicar. No necesitan modo SQLCMD ni instalador automático.

La aplicación utiliza HorarioRepository, CancelarHorarioInput y las páginas CancelarHorario/HistorialHorarios. Los estilos compartidos se conservan. Este cambio no modifica los scripts financieros.

## Concurrencia y reintentos
La versión oculta permite rechazar una página antigua si cambió el registro. Los cruces, la cancelación y el cierre usan Liceo.Planificacion: dos solicitudes concurrentes se serializan. Reenviar la misma operación con los mismos datos no duplica ni la cancelación ni la auditoría. Otra operación sobre un horario ya cancelado se rechaza; reutilizar un identificador de operación con otros datos también. No se permiten cancelaciones parciales del horario.

## Verificación
- `dotnet run --project tests/CancelarHorarioValidation`: validación de entradas.
- `database/verification/018_VerificarCancelacionHorarios.sql`: seis escenarios con rollback: cancelación e historial, reintento, liberación del espacio, período cerrado, versión obsoleta, Profesor denegado, doble cancelación y operación reutilizada con otros datos (varias comprobaciones en el caso positivo). Ejecutar solo en copia sin actividad concurrente; los contadores pueden avanzar.
- En navegador: cancelar como Administrador; comprobar historial y Mi horario del Profesor; intentar rutas y POST como Profesor/Cajero; dos pestañas sobre el mismo horario; cancelar simultáneamente con cerrar período; motivo largo/tildes, tabla vacía, paginación y teclado.

Las pruebas SQL y con sesiones autenticadas no se han ejecutado en este entorno. La revisión sintáctica no sustituye ejecutar SQL Server ni validar concurrencia real.

Los cambios de docente y traslados previos a calificaciones/publicaciones se incorporan en 019 (CambiosPlanificacion.md). Siguen pendientes edición de evaluaciones y administración de cuentas existentes.

Validación de esta entrega: compilación C#/Razor sin errores (40 advertencias previas), 12 pruebas nuevas de cancelación y 12 de planificación aprobadas; seis archivos SQL analizados con ScriptDom. Acceso HTTP anónimo a cancelación, historial, planificación y Mi horario redirige al login. No se ejecutó SQL Server ni se probaron sesiones autenticadas o concurrencia real.
