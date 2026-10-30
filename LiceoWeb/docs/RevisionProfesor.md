# Revisión del profesor — punto de continuación

Rama: revision-profesor-2026-10-29. Base: integracion-equipo-2026-10-29, ac418141f31af29f7c6beca96ca4752430423e56.

## Estado real
Esta entrega es parcial. NO habilitar el esquema financiero nuevo para cobros reales.
Implementado: portada comercial adaptable sin tarifas fijas, formulario de cuentas internas exclusivo del administrador, ajuste de EF Tools a versión 8, migración aditiva de estructura académica/expedientes/finanzas.
No se dispone de SDK dotnet ni SQL Server en el entorno de revisión: compilación y ejecución SQL pendientes.

## Instalación del avance
1. Respaldar la base y usar una copia de desarrollo.
2. Restaurar dependencias y compilar la solución con SDK .NET 8.
3. Verificar Identity y scripts 001–003 existentes. No repetirlos.
4. Revisar/ejecutar database/migrations/004_RevisionProfesor.sql una sola vez en LiceoWeb_Dev.
5. Entrar como administrador y abrir /Personal. Probar creación, correo duplicado, contraseña inválida y rol manipulado. Probar rechazo de GET/POST como Profesor y Cajero.
6. La portada conserva dirección/teléfonos del código anterior; el colegio debe confirmar vigencia. No hay fotografías verificadas: añadir imágenes reales con autorización antes de publicar. No se inventan instalaciones.

## Continuar más tarde — trabajo obligatorio restante
1. Compilar la integración completa y corregir errores previos. Revisar Pages/Cobros/Index1 e Index2, clases vacías Registrar/Editar y CobrosMensualidadModel.cs en raíz antes de eliminar algo.
2. Crear repositorios y servicios para las tablas de 004. El esquema es solo estructura, no lógica completa.
3. Conectar expediente a formularios existentes: padre y madre independientes, permitir datos desconocidos sin inventarlos; tutor padre/madre/tercero, vigencias sin solapamientos, cierre y alta de tutela sin sobrescribir historia. Edad derivada de nacimiento. Auditoría sin copiar información médica a logs. Documentos inicialmente como checklist, sin ficheros públicos. Validar traslado y formato real del colegio/MINED, no inventar obligatoriedad normativa.
4. Planificación: CRUD de catálogos, pensum por año/nivel, grupos, asignación docente/asignatura y horarios. Validar año del pensum/período, asignatura en pensum, rol Profesor, cupo y matrícula; detectar cruces por aula/docente/grupo dentro de transacción. No borrar catálogos referenciados: inactivar.
5. Notas: validar pertenencia del alumno al grupo y docente a asignación en cada GET/POST; no basta pertenecer al rol Profesor. Bloquear períodos cerrados. Nota 0..Maximo; ausente NULL no cero. Peso total <=100 durante configuración, exactamente 100 al cerrar/publicar. Calcular suma(Nota/Maximo*Peso), no suma de notas brutas. Usar bloqueo por asignación y rowversion para concurrencia. Añadir evaluación cualitativa configurable (mencionada en audio).
6. Finanzas: catálogo administrable y tarifas por año/modalidad; generación idempotente de cargos. Diseñar migración explícita de deudas/abonos/pagos antiguos y conciliación por alumno: no operar dos libros paralelos. Recibo único con varias aplicaciones, pagador, número común, IdOperacion estable; validar pertenencia cargos/estudiante, importe aplicado y dinero en una transacción con bloqueo. Incorporar saldo anterior y saldo final antes de habilitar cobro: ReciboMultiple aún no los modela. Mantener recibos anteriores y snapshots. Estado de cuenta debe reunir lo antiguo y lo nuevo sin duplicar ingresos. Anulaciones con contrapartida y auditoría, sin DELETE.
7. Roles: separar permisos académicos, financieros y médicos. Actualmente OperarSistema incluye Profesor y Cajero con acceso amplio heredado. Profesor solo notas/grupos asignados; Cajero finanzas y datos mínimos; administrador configuración/cuentas. Registrar auditoría persistente de provisión (actualmente ILogger). No modificar roles por campos libres; prohibir autodeshabilitar al último administrador al añadir mantenimiento de cuentas.
8. UI: páginas y navegación real de planificación, notas, aranceles y estado de cuenta; no enlaces a páginas inexistentes. Registro expandido por secciones, validación servidor; modal mantiene datos y se reabre si falla.
9. Pruebas: traslado sin código, cambio histórico de tutor, autorización directa, docente ajeno, solapamientos, nota superior al máximo, suma pesos, doble cobro concurrente, reintento IdOperacion, rollback, recibo multiconcepto, conciliación y reimpresión.

## Decisiones de alcance
Portal de padres, notificaciones automáticas y preinscripción/reserva de cupo quedan fuera de esta entrega; la política de preinscripción requiere confirmación del colegio. Matutino es turno; dominical describe jornada/frecuencia: no confundir con niveles Preescolar/Primaria/Secundaria. No cambiar SQL Server a PostgreSQL.

## Punto exacto para retomar
Leer este documento y git log de la rama. Primero compilar y ejecutar pruebas de cuentas y migración en base descartable; luego completar expediente, planificación, notas y adaptación financiera. Esta rama no representa todavía todos los requerimientos terminados.
