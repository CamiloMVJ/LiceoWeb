# Revisión del profesor — punto de continuación

Rama: revision-profesor-2026-10-29. Base: integracion-equipo-2026-10-29, ac418141f31af29f7c6beca96ca4752430423e56.

## Estado real
Esta entrega es parcial. NO habilitar el esquema financiero nuevo para cobros reales.
Implementado: portada comercial adaptable sin tarifas fijas, formulario de cuentas internas exclusivo del administrador, ajuste de EF Tools a versión 8, migración aditiva de estructura académica/expedientes/finanzas.
El SDK .NET 8 fue descargado en la continuación. MSBuild falla por restricciones de información de procesos del entorno; no se afirma compilación de solución. Se compilaron y ejecutaron directamente con Roslyn las ocho pruebas de validación del expediente: todas pasan. También se compiló por Roslyn el C# de las páginas de estudiantes, repositorio y servicio con las referencias reales de ASP.NET Core/SqlClient. No se compiló Razor ni la solución completa. No hay SQL Server: ejecución SQL pendiente.

## Instalación del avance
1. Respaldar la base y usar una copia de desarrollo.
2. Restaurar dependencias y compilar la solución con SDK .NET 8.
3. Verificar Identity y scripts 001–003 existentes. No repetirlos.
4. Revisar/ejecutar database/migrations/004_RevisionProfesor.sql una sola vez en LiceoWeb_Dev.
5. Entrar como administrador y abrir /Personal. Probar creación, correo duplicado, contraseña inválida y rol manipulado. Probar rechazo de GET/POST como Profesor y Cajero.
6. La portada conserva dirección/teléfonos del código anterior; el colegio debe confirmar vigencia. No hay fotografías verificadas: añadir imágenes reales con autorización antes de publicar. No se inventan instalaciones.

## Avance de continuación: expediente
- Listado real filtrado y limitado a 200 filas, sin cargar información médica al cajero.
- Formulario /Estudiantes/Expediente: alta/edición completa por administrador; padre, madre y tercero, contacto internacional, salud, traslado y checklist documental.
- Servicio/repo y procedimiento transaccional; rowversion rechaza actualizaciones sobre datos antiguos. Se mantiene NombreTutor/Telefono del modelo previo para compatibilidad.
- Familiares se versionan al cambiar: no se borra la relación anterior. La tutela guarda nombre histórico y referencia documental. Los intervalos Desde/Hasta se interpretan [Desde,Hasta); cambios del mismo día se ordenan por Id. La precisión intradía de vigencias sigue pendiente si se necesita.
- Edad calculada en hora local; sin valor persistido susceptible de quedar desactualizado.
- Baja con motivo y auditoría; conserva deudas y pagos. GET no modifica.
- Profesor excluido de rutas financieras y de expedientes. Cajero tiene listado básico, no formulario médico. Alta/edición completa queda a administración; la posible captura mínima por cajero queda pendiente de acordar.
- Creación de cuentas ahora registra auditoría SQL en la misma transacción Identity; requiere Registrar_Auditoria instalado.
- Formularios sensibles usan NoStore. No se escriben contenidos médicos en logs ni en Auditoria.
- Se sustituyó el modal corto por una página organizada por secciones debido a la extensión del expediente. Los accesos antiguos Registrar/Editar redirigen a ella.

### Instalar esta continuación
1. Ejecutar 005_ExpedienteVersionado.sql después de 004. No ejecutar 001 otra vez.
2. Ejecutar completo database/procedures/Expediente.sql (incluye GO; usar SSMS).
3. Asegurar Registrar_Auditoria de la etapa 3 instalado.
4. Compilar: dotnet build LiceoWeb.sln.
5. Pruebas de validación: dotnet run --project tests/ExpedienteValidation.
6. En base de prueba, ejecutar database/verification/004_VerificarExpediente.sql. Crea, cambia tutor y da de baja, y revierte los datos. Las secuencias pueden avanzar.
7. Probar dos pestañas editando el mismo expediente: la segunda debe mostrar conflicto y conservar entradas, sin sobreescribir.
8. Probar /Estudiantes/Expediente y POST como Cajero/Profesor: denegado. Probar filtros sin registrar datos sensibles.

## Continuar más tarde — trabajo obligatorio restante
1. Compilar la integración completa y corregir errores previos. Revisar Pages/Cobros/Index1 e Index2, clases vacías Registrar/Editar y CobrosMensualidadModel.cs en raíz antes de eliminar algo.
2. Crear repositorios y servicios académicos/financieros restantes. El expediente ya tiene implementación.
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
Leer este documento y git log de la rama. Primero compilar y ejecutar las pruebas SQL y de acceso del expediente en base descartable; después implementar planificación, notas y adaptación financiera. El expediente está conectado, pero pendiente de prueba integrada en SQL Server. Esta rama no representa todavía todos los requerimientos terminados.
