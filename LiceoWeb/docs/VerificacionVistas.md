> Actualización 025: se retiró el traslado del escritorio y sus conciliaciones. Las referencias a ese flujo en el historial de este documento ya no se aplican. Consultar [RetiroConciliaciones.md](RetiroConciliaciones.md).

# Verificación de expediente, búsqueda y finanzas

## Actualizar una base de desarrollo existente

1. Actualiza el código y detén la aplicación. Ejecuta `--probar-conexion` para confirmar el nombre de la base que usa la aplicación.
2. Con migraciones hasta 022 instaladas, en esa misma base ejecuta completos, con sus separadores GO, los archivos de `LiceoWeb/database/procedures/`: `Aranceles.sql`, `Conciliacion.sql`, `Planificacion.sql`, `Evaluacion_ConsultarEdicion.sql` y `Mensualidades_Legado.sql`.
3. Reinicia la aplicación. No se agrega una migración de tablas. No ejecutes `Procedimientos.sql`: pertenece a Registro_Pagos y contiene definiciones anteriores.
4. Si solo usas el libro nuevo, los tres procedimientos legados no son necesarios para cobrar. Después del corte, la aplicación redirige la ruta anterior y SQL rechaza su procedimiento de pago. No desactives los triggers ni reviertas el corte para abrir un formulario antiguo.

Comprueba el estado con `SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1;`. Si no existe la fila, diagnostica la migración 012. Si el log de catálogo indica SQL 51100 en Registrar_Auditoria, revisa que el procedimiento instalado acepte el nombre de la base. El instalador consolidado para LiceoWeb_Limpia ya adapta el nombre; no lo sobrescribas con una copia preparada solo para LiceoWeb_Dev.

## Expediente y búsqueda

- Selecciona un grado. La modalidad se muestra al seleccionar y se calcula nuevamente en el servidor antes de guardar. Los registros antiguos con otra grafía no cambian hasta que eliges su equivalente y guardas. Revisa la misma grafía en el pensum si hay expedientes o grupos antiguos; la inscripción exige que coincidan.
- En Estado de cuenta, Saldos, Cargos, Obligaciones, Estudiantes, inscripción a grupos y búsqueda de Mensualidades, escribe al menos dos caracteres. Aparecen hasta cuatro activos, con nombre, grado y registro. Selecciona la coincidencia y usa el botón del formulario. La operación utiliza el registro, incluso si dos nombres son iguales.
- Las listas de altas y selección operativa excluyen registros inactivos cuando el catálogo tiene estado. Se conservan historiales y pantallas de administración para consultar, reactivar o corregir. Un período cerrado sigue disponible en Cierre e historial académico para que se pueda consultar o reabrir.
- El filtro de inactivos en las sugerencias no borra expedientes ni deudas. El listado de estudiantes conserva su filtro de estado y las obligaciones ya capturadas siguen consultables.

## Aranceles y tarifas

1. En Catálogos académicos, crea el año y las modalidades que vas a usar; déjalos activos.
2. En Aranceles, crea el concepto con código, nombre, estado activo y motivo. Ejemplo: MAT / Matrícula.
3. En Tarifa, selecciona arancel, año y modalidad activos. Registra el importe y motivo. Una tarifa es la combinación de esos tres datos; editarla no cambia la combinación ni recalcula cargos ya emitidos.
4. Solo si migras datos antiguos y el libro anterior sigue abierto: entra en Vincular conceptos. Relaciona cada origen (Matriculas, Mensualidades, Mantenimientos, EvBoTaS, Promociones) con su arancel y guarda con motivo. Una relación existente no se reasigna desde el formulario. Repetir el mismo vínculo no duplica la relación.
5. En Preparar obligaciones, registra el motivo y captura. Se necesita la correspondencia de los cinco orígenes. Capturar copia referencias para revisar; no genera deuda ni pagos.
6. Con el libro nuevo activo, configura periodicidad en Generar cargos. La matrícula académica requiere el arancel anual correspondiente. Los conceptos del libro anterior no son requisito para una base sin datos históricos.

## Conciliación de saldos a favor

1. Antes del corte, selecciona un estudiante por nombre y consulta.
2. Compara el saldo y los pagos históricos con recibos y documentos. Cero filas significa que no hay saldo registrado.
3. Elige Aprobado documentalmente o Rechazado. Escribe la referencia del respaldo y el motivo.
4. Guarda y verifica el historial. Si otra revisión o la fuente cambió, recarga y vuelve a verificar.
5. El saldo inicial solo se aplica con el corte, si la aprobación sigue vigente. Después del corte esta pantalla permite consultar. En una base limpia no tienes que aprobar saldos ficticios.

## Conciliación de obligaciones

1. Antes del corte, configura aranceles y tarifas históricas compatibles y captura las obligaciones desde Aranceles.
2. Abre Conciliación de obligaciones. Puedes filtrar por estudiante o revisar el listado completo.
3. Abre una obligación y coteja origen, fecha/año, modalidad, estado, importe y comprobante.
4. Si la fuente cambió, usa Recapturar origen con motivo y vuelve a revisar la nueva captura.
5. Selecciona una tarifa activa del mismo arancel, año y modalidad; el importe de la tarifa no reemplaza el histórico.
6. Elige deuda pendiente, sin deuda o rechazada según los documentos. Registra motivo y verifica que la revisión aparezca en el historial. El corte vuelve a validar la decisión. Después del corte queda en modo consulta.

## Cierre e historial académico

1. Configura un período con grupos, estudiantes y materias. Asigna docentes a todas las materias del pensum.
2. En Calificaciones, cada docente registra las evaluaciones y las notas y publica su asignatura. Las evaluaciones cuantitativas deben sumar 100% cuando correspondan; las cualitativas requieren un resultado válido.
3. Como administrador, abre Cierre e historial académico y selecciona el período. Revisa publicaciones y pendientes.
4. Escribe el motivo y confirma Cerrar período. El servidor exige grupos con estudiantes, docentes asignados, publicaciones vigentes y resultados válidos.
5. Para corregir, reabre primero el período si está cerrado. Luego selecciona Autorizar corrección para la asignación correspondiente y registra el motivo. El docente corrige y publica de nuevo. Repite el cierre si corresponde.
6. Consulta el historial de notas y los eventos. Reabrir el período por sí solo no desbloquea las asignaturas publicadas.

## Qué verificar en SQL Server y navegador

- En dos copias de desarrollo, comprobar el vínculo antes del corte y su rechazo después del corte. Tras el vínculo válido, verificar su fila y la auditoría en la misma operación.
- Buscar homónimos, nombres con y sin tildes, y un estudiante inactivo. Intentar enviar un grado fuera de la lista.
- Probar el flujo legado con cuotas y centavos, con saldo, sin cuotas, y con dos envíos de la misma operación. Verificar que no se duplica el comprobante, que las cuotas y el saldo cuadran y que después del corte no se escribe.
- Probar saldo y obligación con datos históricos, incluida recaptura y rechazo de una revisión antigua. Probar un cierre incompleto, el cierre válido y la corrección autorizada.
- La revisión de código, las pruebas de validación y la comprobación de sintaxis no sustituyen estas pruebas integradas.
