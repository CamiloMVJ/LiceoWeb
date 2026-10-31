# Adaptación financiera — diagnóstico, catálogo y preparación
Estado: diagnóstico, catálogo y preparación implementados; NO se activó un libro financiero nuevo.
Ejecutar database/verification/008_DiagnosticoFinanciero.sql completo en una copia LiceoWeb_Dev sin actividad de cobros. Requiere tablas originales y etapa 003. Es solo lectura de tablas de negocio; usa una tabla temporal. Validado con ScriptDom, no ejecutado contra SQL Server.

## Resultados
1. Resumen por estudiante: deuda registrada, saldo a favor y pagos sin historial. El saldo no se aplica ni se descuenta automáticamente.
2. Detalle de obligaciones y alertas. Cancelado sin comprobante puede representar beca: no convertirlo a deuda.
3. Pagos y balance. Monto heredado no se suma como ingreso confiable cuando falta historial.
4. Matrículas y comprobante asociado. No convertir matrículas pagadas en cargos pendientes.
5. Tarifas actuales, separadas de importes históricos.

El informe no certifica una conciliación: no detecta cuotas nunca generadas, ni demuestra que pagos con balance aritmético correcto hayan sido realmente recibidos. No garantiza consistencia entre resultados si hay escrituras concurrentes. Guardar/exportar los resultados en un lugar privado, pues contienen nombres y saldos.

## Hallazgos de código
Procedimientos.sql contiene USE Registro_Pagos y parámetros/variables INT para cobros y arreglos. No ejecutarlo automáticamente en LiceoWeb_Dev. El registro histórico completo existe solo para pagos registrados mediante el contrato de comprobantes. El saldo de Abonos es una existencia actual, no un ingreso adicional. Las tarifas actuales no sustituyen el costo original de una obligación.

## Contrato de transición
- Una obligación migrada debe tener clave única de origen (tabla, Id) y conservar importe, año, estudiante y estado.
- Conservar pagos previos como historial; no emitirles nuevos ingresos ni números de recibo.
- Importar el saldo existente como saldo inicial identificado y conciliado; no como cobro.
- Mapear las cinco tablas de costos al catálogo de aranceles, conservando sus referencias. Las tarifas nuevas se versionan; cargos existentes conservan su importe.
- Antes de activar cobros nuevos, impedir escrituras desde todas las rutas antiguas. No mantener dos libros activos.
- El recibo multiconcepto usa una transacción, un estudiante, número global y operación idempotente. Detalles aplicados a cargos sin exceder deuda, con pagador y referencia. Registrar saldo anterior/final y balance.
- Estado de cuenta distingue cargos, aplicaciones, saldos iniciales y anulaciones. No sumar otra vez un pago por cada detalle.
- Reversos conservan historial y requieren permiso y motivo.

## Catálogo y preparación implementados
Instalar migrations/008_CatalogoFinanciero.sql y procedures/Aranceles.sql. Administración puede gestionar aranceles, tarifas con historial y correspondencias, y capturar obligaciones por clave única de origen. Guía: docs/CatalogoFinanciero.md. La captura preserva importes históricos y detecta cambios posteriores de la fuente; no crea cargos cobrables, no concilia automáticamente y no modifica pagos.

## Continuar más tarde
Este avance NO completa la adaptación solicitada. Próximo paso: resolver discrepancias y aprobar conciliación, mapear tarifas/años/modalidades y saldos, implementar corte controlado y migración a cargos; luego recibos multiconcepto y estado de cuenta. Resolver anomalías del diagnóstico antes de ejecutar el corte. No requiere cambiar las migraciones 000–007.
