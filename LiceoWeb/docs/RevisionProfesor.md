# Revisión del profesor — punto de continuación

Rama: revision-profesor-2026-10-29. Base: integracion-equipo-2026-10-29, ac418141f31af29f7c6beca96ca4752430423e56.

## Estado real
Esta entrega es parcial. NO habilitar el esquema financiero nuevo para cobros reales.
Implementado: portada comercial adaptable sin tarifas fijas, formulario de cuentas internas exclusivo del administrador, ajuste de EF Tools a versión 8, migración aditiva de estructura académica/expedientes/finanzas.
La solución completa compila con SDK .NET 8.0.427, incluidas las vistas Razor: cero errores y 40 advertencias preexistentes (principalmente nulabilidad en mensualidades). Se corrigieron las clases duplicadas Index1Model/Index2Model de EvBoTa/Promoción, conservando ambas rutas. Pasan 8 pruebas de expediente y 12 de planificación. No hay SQL Server en el entorno: las pruebas SQL integradas siguen pendientes; la sintaxis de los procedimientos de expediente y planificación se validó con ScriptDom.
Prueba HTTP ejecutada: portada/login/CSS responden 200; registro público 404; planificación, catálogos, MiHorario, expediente y cuentas redirigen al login sin sesión. Esto no sustituye las pruebas con usuarios autenticados de distintos roles.

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

## Avance de continuación: planificación académica
- Catálogos: años, períodos, modalidades, turnos, aulas y asignaturas. Alta, consulta, edición antes de uso y activación/inactivación sin borrar referencias.
- Pensum por año/modalidad/nivel y materias; grupos por período, turno y aula; asignación de cuentas Profesor.
- Horarios con detección de cruces por docente, aula y grupo, considerando fechas del período y admitiendo clases adyacentes.
- Inscripción a grupo con comprobación de estudiante activo, matrícula del mismo año/modalidad/nivel, cupo y pertenencia única al período.
- Mi horario muestra exclusivamente las asignaciones de la cuenta autenticada.
- Mutaciones con autorización, auditoría y bloqueo transaccional compartido para evitar carreras.
- Instalación: ejecutar database/procedures/Planificacion.sql después de las etapas anteriores. No necesita tablas adicionales.
- Guía: docs/PlanificacionAcademica.md. Pruebas: tests/PlanificacionValidation y database/verification/005_VerificarPlanificacion.sql.
- Doce pruebas C# de validación y compilación de solución completa satisfactorias. Sintaxis SQL revisada con ScriptDom (no equivale a ejecutar SQL Server).

## Continuar más tarde — trabajo obligatorio restante
1. Ejecutar pruebas integradas SQL y de autorización en una base de desarrollo. Verificar la integración completa, incluidos los módulos financieros previos.
2. Completar cambios de grupos/asignaciones y cancelación de horarios conservando historial. La etapa actual permite crearlos, pero no reasignarlos ni cerrar períodos.
3. Notas: validar pertenencia del alumno al grupo y docente a asignación en cada GET/POST; no basta pertenecer al rol Profesor. Bloquear períodos cerrados. Nota 0..Maximo; ausente NULL no cero. Peso total <=100 durante configuración, exactamente 100 al cerrar/publicar. Calcular suma(Nota/Maximo*Peso), no suma de notas brutas. Usar bloqueo por asignación y rowversion para concurrencia. Añadir evaluación cualitativa configurable.
4. Finanzas: catálogo administrable y tarifas por año/modalidad; generación idempotente de cargos. Migrar/conciliar deudas, abonos y pagos antiguos sin operar dos libros paralelos. Recibo único con varias aplicaciones, pagador, número común, IdOperacion estable; validar cargos/estudiante e importes en una transacción. Incorporar saldo anterior y final antes de habilitar ReciboMultiple. Estado de cuenta sin duplicar ingresos; anulaciones con contrapartida, sin DELETE.
5. Cuentas: al incorporar desactivación y cambio de rol, impedir eliminar el último administrador y renovar las sesiones afectadas. Creación ya tiene auditoría persistente.
6. UI: completar notas, aranceles, estado de cuenta y enlaces de módulos anteriores que aún sean solo formularios.
7. Colegio: confirmar fotos, datos de contacto, formato de traslado, escala de notas, catálogo de niveles y política de preinscripción. No inventar información institucional ni normativa.
8. Pruebas pendientes: autorización directa de páginas/POST, cruces concurrentes, cupo lleno, docente ajeno, nota fuera de rango, doble cobro, reintento idempotente, rollback, recibo multiconcepto y conciliación.

## Decisiones de alcance
Portal de padres, notificaciones automáticas y preinscripción/reserva de cupo quedan fuera de esta entrega; la política de preinscripción requiere confirmación del colegio. Matutino es turno; dominical describe jornada/frecuencia: no confundir con niveles Preescolar/Primaria/Secundaria. No cambiar SQL Server a PostgreSQL.

## Punto exacto para retomar
Leer este documento y git log. Probar la planificación en SQL Server; luego implementar registro de notas y cierre de períodos sobre las asignaciones existentes, antes de abordar la adaptación financiera. Esta rama aún no completa todos los requerimientos del profesor.
