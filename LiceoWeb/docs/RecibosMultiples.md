# Cobros multiconcepto y estado de cuenta

Esta etapa incorpora `/Finanzas/Cuenta` y `/Finanzas/Recibo/{id}`, para Administrador y Cajero. Profesor no tiene acceso. Cada recibo aplica uno o varios importes a cargos del mismo estudiante; admite abonos parciales, efectivo, transferencia y consumo del saldo conciliado. No genera cargos nuevos ni anula recibos todavía.

## Instalación en una copia de desarrollo
1. Guarda respaldo de la base. Actualiza la rama `revision-profesor-2026-10-29` con tus cambios locales previamente confirmados.
2. Completa migraciones anteriores hasta 012 y sus procedimientos según `CorteFinanciero.md`. No vuelvas a ejecutar migraciones instaladas.
3. Ejecuta `database/migrations/013_RecibosMultiples.sql` en `LiceoWeb_Dev`. Exige que ReciboMultiple esté vacía; no convierte recibos creados manualmente.
4. Ejecuta todo `database/procedures/CobroMultiple.sql`, incluidos sus separadores GO. Puede reinstalarse con CREATE OR ALTER.
5. Compila y abre el sistema. El nuevo enlace **Estado de cuenta y cobros** aparece para Administrador/Cajero. Antes del corte informa que el libro nuevo no está habilitado.
6. En una copia desechable, termina conciliación, simula el corte y después aplícalo siguiendo `CorteFinanciero.md`. Aplicarlo bloquea las escrituras antiguas. No activarlo en la base de trabajo sin validar los casos siguientes y resolver los pendientes operativos.
7. Busca un estudiante con cargos migrados por su código. Registra importes positivos en los cargos que pagará; deja cero en los demás. Hasta 50 cargos por recibo; para más, usa la siguiente página de selección.
8. Indica pagador, método, dinero recibido y saldo que deseas utilizar. Transferencia requiere referencia y no admite vuelto; efectivo devuelve el excedente. Solo saldo exige dinero recibido cero.
9. Confirma. Se abre el recibo con detalle, vuelto y saldos anterior/utilizado/final. Regresa al estado de cuenta para ver la deuda restante. La impresión se hace con el navegador; todavía no hay plantilla de impresión dedicada.
10. Ejecuta `database/verification/012_VerificarRecibosMultiples.sql` después de tus pruebas.

## Responsabilidad de los archivos
- **013_RecibosMultiples.sql:** amplía recibos con instantánea del nombre, huella de la solicitud y balance, permite pago íntegro con saldo y agrega índice por cargo. Se instala una vez.
- **CobroMultiple.sql:** autorización por rol, consulta de cuenta/recibo y transacción de cobro. El bloqueo compartido con configuración/corte serializa los cobros; conserva cargo, pago, saldo y auditoría en la misma transacción. Rechaza cargos ajenos, anulados o sobrepagados.
- **Cuenta.cshtml.cs:** validación del formulario y parámetros SQL tipados. La identidad del responsable sale de la sesión. Conserva el GUID del formulario si falla el envío.
- **Cuenta.cshtml:** consulta, selección de aplicaciones, formulario, deuda y listado de recibos. Los pagos anteriores se muestran aparte como referencia, sin sumarlos de nuevo.
- **Recibo.cshtml.cs / .cshtml:** consulta autorizada e impresión desde navegador del comprobante persistido. Nombres/conceptos/importes son instantáneas al cobrar; el nombre de usuario responsable se consulta en Identity.
- **tests/CobroMultipleValidation:** pruebas de reglas de entrada en C#; no sustituyen pruebas SQL ni de concurrencia.

## Pruebas integradas obligatorias
Usa una copia, dos sesiones de cajero y cargos/saldos conocidos. Los procedimientos de cobro no aceptan transacción externa: no envolverse en BEGIN TRAN pensando que ROLLBACK deshará la prueba.

| Caso | Resultado esperado |
|---|---|
| Dos cargos de 70 y 30, efectivo 120 | Aplicado 100, vuelto 20, deuda baja 100 |
| Saldo inicial 50, aplicar 30 y efectivo 70 a deuda 100 | Saldo final 20, vuelto 0 |
| Solo saldo por 40 con disponible suficiente | Dinero 0, saldo baja 40 |
| Transferencia por 100 con referencia | Vuelto 0; transferencia por 101 rechazada |
| Dos envíos idénticos con el mismo GUID | Mismo Id/número; un recibo, una auditoría y un descuento |
| Mismo GUID con datos modificados | Rechazo, sin otro recibo |
| Dos GUID intentando pagar simultáneamente toda la misma deuda | Uno cobra; el otro rechaza la deuda ya pagada |
| Cargo de otro estudiante o saldo insuficiente | Rechazo sin escrituras parciales |
| Simular fallo de auditoría en una copia | Rollback del recibo, aplicaciones y saldo (la secuencia puede dejar huecos) |
| Antes del corte / acceso de Profesor | Cobro bloqueado / acceso denegado |
| Reenviar después de timeout con resultado incierto | Mismo formulario/GUID; devuelve recibo si ya se confirmó |

La referencia de transferencia se almacena, pero no se considera única globalmente: revisar documentalmente para evitar capturar la misma transferencia con otro GUID. No se admiten depósitos nuevos a saldo a favor; el excedente de efectivo siempre es vuelto. Un estudiante sin fila de SaldoFinanciero tiene disponible cero y puede pagar en dinero si ya tiene cargos.

## Pendientes y límites
- Ejecutar las pruebas SQL anteriores con SQL Server y cuentas reales de prueba. La revisión sintáctica no prueba nombres, bloqueo ni ejecución.
- Generación idempotente de cargos nuevos desde tarifas, anulaciones con contrapartida y devolución documentada; todavía no disponibles.
- Retirar/redirigir formularios antiguos después del corte: los triggers ya bloquean su escritura, pero algunos enlaces siguen visibles. No usarlos para cobrar tras el corte.
- Optimizar paginación de consulta y presentación de impresión; la selección de cobro muestra 50 cargos, pero consulta la cuenta completa.
- No habilitar operación cotidiana mientras falten las funciones que requiera el colegio. Las pruebas de esta entrega no certifican puesta en producción.

## Verificación realizada en esta entrega
- Compilación .NET 8 y Razor: 0 errores; permanecen 40 advertencias previas de nulabilidad en Mensualidades.
- 19 pruebas de validación de cobro aprobadas.
- Los tres archivos SQL analizados con ScriptDom sin errores sintácticos; no equivale a ejecutarlos en SQL Server.
- Prueba HTTP: inicio público 200 y ambas páginas financieras redirigen a login al acceder sin sesión. Falta probar con sesiones de los tres roles.
