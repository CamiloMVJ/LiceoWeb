# Administración de cuentas del personal — etapa 021

Solo Administrador. Entrada: menú «Cuentas del personal» → `/Personal/Administrar`. La creación sigue en `/Personal/Index`. No hay autorregistro público.

## Instalar este avance

1. Respaldar la base y probar en una copia de `LiceoWeb_Dev`. Detener la aplicación mientras se actualizan SQL y código.
2. Tener completas las etapas hasta 020, las tablas de Identity y `dbo.Registrar_Auditoria`. No repetir 001 ni las migraciones ya aplicadas.
3. Ejecutar **una vez** `database/migrations/021_AdministracionPersonal.sql`. Si indica instalación parcial, revisar el esquema; no borrar tablas para repetir.
4. Ejecutar completos, en este orden, los archivos de `database/procedures/`:
   - `Personal_Autorizar.sql`
   - `Personal_Consultar.sql`
   - `Personal_Guardar.sql`
   - `Planificacion.sql`
   - `Planificacion_Cambiar.sql`
   - `Planificacion_CambioConsultar.sql`
5. Actualizar y compilar la aplicación con `dotnet build LiceoWeb.sln`. Mantener sus secretos locales de conexión; no subir contraseñas.
6. Iniciar la aplicación y entrar con un administrador existente. Las cuentas sin fila en `EstadoCuentaPersonal` conservan su estado activo anterior. Los bloqueos y requisitos de Identity siguen aplicándose.
7. En una copia aislada y sin usuarios conectados, ejecutar `database/verification/021_VerificarAdministracionPersonal.sql`. Son 16 escenarios con rollback. Uno modifica temporalmente la disponibilidad de contraseñas de administradores para probar la última cuenta habilitada; todos los cambios se revierten. No usar en una base operativa.
8. Ejecutar `dotnet run --project tests/PersonalValidation` y completar las pruebas manuales siguientes.

No hay instalador automático. La aplicación actualizada necesita la tabla nueva para autenticar y validar sesiones: instalar la migración antes de iniciar esta versión.

## Uso

- Buscar por correo; el listado muestra 50 cuentas por página, rol, baja administrativa, bloqueo de Identity y correo sin confirmar.
- Abrir «Ver y administrar». Seleccionar Administrador, Profesor o Cajero; marcar/desmarcar «Cuenta activa» y explicar el motivo (10–500 caracteres).
- «Confirmar cambios» guarda estado y rol en una transacción con historial y auditoría. No se borran usuarios, notas, comprobantes ni asignaciones históricas.
- No puede modificar su propia cuenta. Otro administrador debe hacerlo. Cuentas sin rol, con varios roles o roles desconocidos requieren revisión técnica; la pantalla no elimina permisos ambiguos silenciosamente.
- Si el docente tiene asignaciones de períodos abiertos, primero cambiar el docente en Planificación. Las asignaciones de períodos cerrados se conservan.
- Si la cuenta cambió en otra pestaña, revisar «Estado actual» y usar «Recargar cuenta» antes de volver a confirmar. El motivo escrito se conserva ante un error. Una repetición exacta de la misma operación no duplica historial.
- Se muestran los últimos 50 cambios de la cuenta; el historial completo permanece en SQL.
- Reactivar permite volver a autenticarse, pero no elimina bloqueos temporales de Identity ni confirma correos automáticamente. No se restablecen contraseñas desde esta pantalla.

## Qué hace cada archivo

| Archivo | Responsabilidad |
| --- | --- |
| `021_AdministracionPersonal.sql` | Estado de acceso separado de Identity e historial con actor, motivo y valores anteriores/nuevos. No copia contraseñas ni sellos al historial. |
| `Personal_Autorizar.sql` | Dentro de una transacción, serializa cambios del personal y verifica el rol/estado actual del administrador en SQL. También lo usa la creación de cuentas. |
| `Personal_Consultar.sql` | Listado paginado, detalle e historial; solo administrador habilitado. No devuelve hashes ni sellos de seguridad. La versión devuelta es ConcurrencyStamp. |
| `Personal_Guardar.sql` | Autorización, no modificar propia cuenta, control de versión, reintento, último administrador utilizable, asignaciones abiertas, actualización de rol/estado/sellos, auditoría atómica. |
| `PersonalInput.cs` | Validación del formulario en servidor; SQL vuelve a validar los datos críticos. |
| `PersonalRepository.cs` | Llamadas SQL parametrizadas. El actor proviene de la sesión, nunca del formulario. |
| `Personal/Administrar.cshtml` y `.cshtml.cs` | Listado, formulario, confirmación e historial; protección por política, antifalsificación y NoStore. GET no cambia cuentas. |
| `EstadoCuentaPersonal.cs` | Consulta el estado activo; cuenta ausente no habilitada. Un error SQL no se interpreta como autorización. |
| `PersonalSignInManager.cs` | Conserva Identity y comprueba la baja al iniciar sesión y validar sellos, incluyendo segundo factor. |
| `Program.cs` | Registra los servicios y valida SecurityStamp en cada solicitud autenticada. Conserva el validador de cookies de Identity. |
| Procedimientos de planificación actualizados | Excluyen cuentas desactivadas, no confirmadas o bloqueadas al asignar/cambiar docentes, tanto en listas como en SQL. |
| `IdentitySeeder.cs` | El comando manual de desarrollo comparte el bloqueo de personal; no cambia automáticamente cuentas existentes. |

## Sesiones y concurrencia

Cada cambio renueva SecurityStamp y ConcurrencyStamp. Las cookies anteriores se rechazan en la **siguiente solicitud**; una página que ya está abierta no desaparece sola y una solicitud ya iniciada no se cancela. Un restablecimiento de contraseña no revierte la baja administrativa, porque esta se guarda aparte de LockoutEnd.

El bloqueo `Liceo.Personal` serializa creación y administración. Para administrar se toma después `Liceo.Planificacion`, antes de actualizar Identity. Así se comprueban asignaciones y estado sin competir con una nueva asignación docente. Dos cambios basados en una misma versión no se sobrescriben; una repetición con el mismo identificador y datos devuelve éxito sin duplicar registros. Estas garantías cubren los flujos de la aplicación, no ediciones SQL externas realizadas por operadores.

Validar sellos en cada solicitud implica lecturas adicionales de Identity/estado. Es una decisión de seguridad para este sistema; medir carga antes de cambiar el intervalo. La comprobación del último administrador exige otra cuenta activa, correo confirmado, contraseña presente y sin bloqueo vigente; no prueba que alguien conozca su contraseña.

## Verificación pendiente en SQL Server y navegador

- Administrador: crear una cuenta, desactivarla, reactivarla y cambiar su rol. Profesor/Cajero: GET/POST de Personal denegados. Formulario sin token antifalsificación rechazado.
- Abrir sesión en otro navegador. Después de una baja o cambio de rol, su siguiente solicitud debe ir al login. Reactivación exige nuevo inicio; las cookies anteriores no recuperan validez.
- Probar también «Recordarme», segundo factor si está configurado y restablecimiento de contraseña: una cuenta desactivada sigue sin entrar.
- Dos administradores intentan desactivar al otro simultáneamente: solo uno termina; el segundo pierde autorización. Dos pestañas modifican la misma cuenta: la versión antigua se rechaza.
- Docente con período abierto: baja/cambio de rol denegado; reasignar y repetir. Docente con asignaciones solo cerradas: historial preservado.
- Solicitud de asignación docente abierta antes de desactivarlo: SQL debe rechazarla aunque siga figurando en la página antigua.
- Comprobar buscador, enlaces, estados y navegación en móvil/teclado.

Verificado aquí: compilación de C#/Razor; 24 pruebas de entrada y SignInManager con dobles de Identity/estado; sintaxis de ocho scripts mediante ScriptDom; acceso HTTP anónimo. No hay SQL Server disponible: no se ejecutaron los 16 escenarios SQL ni pruebas de sesiones persistidas/concurrencia real. Los dobles de prueba no sustituyen esas comprobaciones.
