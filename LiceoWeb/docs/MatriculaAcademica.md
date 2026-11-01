# Matrícula académica vinculada al cargo

## Instalación
1. Base de desarrollo con etapas hasta 015 instaladas. Detener aplicación y respaldar antes de migrar.
2. Ejecutar migrations/016_MatriculaAcademica.sql una vez.
3. Reinstalar procedures/Planificacion.sql completo. Compilar/reiniciar aplicación.
4. La configuración toma el arancel de matrícula del mapeo antiguo si existía. En una base vacía que ya aplicó el corte puede faltar ese mapeo: no modificar las tablas antiguas cerradas.

## Configurar el arancel si no existía
Crear el arancel y tarifa desde Aranceles y definir periodicidad Anual desde Generar cargos. En **Generar cargos → Arancel de matrícula académica**, seleccionar el arancel y confirmar. Solo Administración puede hacerlo. Si ya estaba configurado, se muestra la selección existente y no se reemplaza. Requiere reinstalar GeneracionCargos.sql de la versión actual; no editar MapaConceptoLegado ni reabrir el corte.

## Flujo para una matrícula nueva
1. Registrar/actualizar el expediente; modalidad y grado deben coincidir con el pensum del grupo.
2. Configurar año, período, pensum, aula, turno y grupo en Planificación.
3. Desde Generar cargos, revisar el precio y generar el cargo anual del arancel de matrícula para ese estudiante, año y modalidad.
4. En Planificación → Estudiante, seleccionar grupo y código del alumno; guardar.
5. Se crea una matrícula académica por estudiante/año, vinculada al cargo, y se inscribe al grupo en la misma transacción con auditoría. Se permite cargo pendiente: esta entrega no establece pago previo como requisito académico.
6. Cobrar desde Estado de cuenta. No se genera recibo por inscribir en un grupo.
7. Para períodos siguientes del mismo año se reutiliza la matrícula anual, sin otro cargo.

Una matrícula histórica de igual año/modalidad/nivel sirve como respaldo sin volver a cobrar. Los grupos ya existentes no se alteran ni se reconstruyen automáticamente. Antes del corte se conserva la regla histórica.

## Límites y comportamiento
- Dos pasos explícitos: generación financiera y confirmación académica. No hay cargo automático al guardar el expediente.
- Si el grupo está lleno, cerrado, ya publicó notas o el estudiante ya pertenece a otro grupo del período, no se guarda matrícula nueva ni asignación parcial. El cargo creado previamente permanece y requiere revisión administrativa; no se elimina automáticamente.
- No se admite un segundo nivel/modalidad en el mismo año sin una futura operación de traslado. No hay bajas/traslados de matrícula en esta etapa.
- Un reenvío de inscripción no duplica la relación: puede devolver el mensaje de que ya pertenece a un grupo. Consultar el listado antes de repetir.
- La anulación de un recibo reabre deuda; no cancela una matrícula académica.

## Pruebas obligatorias en SQL Server
Inscribir estudiante con cargo anual pendiente/pagado; reconocer matrícula histórica; rechazar sin cargo, modalidad/nivel incorrectos y cargo ajeno; grupo lleno/cerrado/publicado; dos inscripciones concurrentes; siguiente período sin segundo cargo; fallo de auditoría con rollback académico; acceso directo como Cajero/Profesor denegado. Ejecutar en copia: estas pruebas no se han ejecutado aquí.

## Continuar más tarde
Facilitar revisión conjunta de cargo/cupo antes de confirmar; implementar traslados/bajas con historial, reportes académicos y pruebas SQL integradas. Sigue pendiente automatización opcional de mensualidades según la política del colegio.
