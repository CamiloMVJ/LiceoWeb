# Mensualidades por rango para estudiantes matriculados

Instalación: con aplicación detenida y base de desarrollo respaldada, instalar migraciones previas hasta 016, ejecutar 017_LoteMensualidades.sql una vez, reinstalar procedures/GeneracionCargos.sql y ejecutar procedures/Mensualidades_GenerarLote.sql completo. Compilar/reiniciar.

En Generar cargos, buscar estudiante y seleccionar una tarifa de periodicidad Mensual. Marcar Generar rango de mensualidades; indicar mes inicial, mes final y día de vencimiento entre 1 y 28. Dejar vacíos evento y fecha individual. El importe mostrado es por mes: el total nuevo será importe por cantidad de meses. La matrícula académica debe corresponder al año y modalidad de la tarifa. Registrar el expediente no basta: confirmar inscripción en Planificación primero.

Esta generación aplica a la tarifa mensual seleccionada (mensualidad u otro servicio mensual); no se identifica el concepto por su nombre ni se impone un calendario escolar. No genera automáticamente enero–diciembre ni se ejecuta por una tarea programada.

El lote completo, sus cargos y auditorías se guardan en una transacción. Si cualquier mes ya está registrado, incluso en obligaciones históricas reconocidas, todo el lote se revierte; elegir un rango que no incluya meses existentes. No modifica importes anteriores, no genera recibos y no registra pagos. Un reintento con la misma operación devuelve la cantidad original; cambiar parámetros con la misma operación se rechaza. Los cargos generados siguen usando la misma regla de duplicados por arancel/año/período del módulo 014.

GeneracionCargos.sql agrega un parámetro interno opcional para permitir la transacción del lote y suprimir resultados individuales. Su valor por defecto conserva el contrato de la pantalla de cargo individual. Un fallo interno revierte toda la transacción; no utilizar ese modo dentro de transacciones ajenas al lote.

Pruebas SQL pendientes en copia: matrícula ausente/incompatible; tarifa inactiva o modificada; rango 2–11; un mes existente en medio (cero cargos nuevos); mismo GUID repetido; dos lotes concurrentes solapados; fallo de auditoría; comprobar deuda/fechas/suma en cuenta; autorización Cajero/Profesor denegada. No ejecutado contra SQL Server aquí.

Pendiente: confirmación conjunta de matrícula/cargos, selección de meses no consecutivos, configuración de calendario por año y reportes. Se mantiene revisión explícita del administrador antes de generar deuda.
