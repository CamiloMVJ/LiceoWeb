# Anulación completa de recibos

Administración puede anular recibos del **libro nuevo**, con motivo, receptor y referencia de devolución. Caja puede consultar el resultado, pero no anular. No se anulan pagos históricos del libro anterior ni se admiten anulaciones parciales en esta etapa.

## Instalación
1. Guarda tus cambios y actualiza la rama `revision-profesor-2026-10-29`.
2. Detén la aplicación mientras actualizas la base; usa una copia de desarrollo con las etapas anteriores hasta 014 instaladas.
3. Ejecuta `database/migrations/015_AnulacionRecibos.sql` una sola vez. Crea la contrapartida y la vista de aplicaciones vigentes.
4. **Vuelve a ejecutar completo `database/procedures/CobroMultiple.sql` actualizado.** Ahora calcula deuda excluyendo aplicaciones anuladas y devuelve el estado de anulación. Este paso es obligatorio, aunque ya instalaras el archivo en 013.
5. Ejecuta `database/procedures/AnulacionRecibos.sql`.
6. Compila y reinicia la aplicación. No mezcles la aplicación nueva con procedimientos anteriores. Si instalas desde cero, completa hasta 015 antes de probar las pantallas financieras de esta versión.
7. Como Administrador, abre **Estado de cuenta y cobros → recibo → Revisar anulación**.
8. Revisa los cargos, el dinero neto a devolver, el saldo que se restituirá y la deuda que volverá a estar pendiente.
9. Realiza y documenta la devolución por el mismo método original. El sistema **no ejecuta transferencias bancarias**. Para efectivo registra la referencia de la constancia de entrega; para transferencia, la referencia bancaria; para solo saldo, una constancia interna sin entregar dinero.
10. Introduce motivo, receptor y referencia. Marca la confirmación y pulsa **Confirmar anulación completa**.
11. El recibo muestra **ANULADO**, mantiene el detalle original y añade la devolución, fecha, responsable y saldos al anular. La cuenta muestra deuda reabierta y saldo restituido; el ingreso neto y las aplicaciones vigentes de ese recibo son cero.
12. Ejecuta `database/verification/014_VerificarAnulaciones.sql` y la versión actualizada de `012_VerificarRecibosMultiples.sql`.

## Ejemplo de balance
Un recibo aplica C$100 a deuda: recibe C$120 y devuelve C$20 de vuelto. Al anular se devuelven **C$100**, no C$120, y la deuda aumenta C$100.

Otro recibo aplica C$100 usando C$70 de dinero y C$30 de saldo a favor. Al anular se documenta devolución de C$70, se restituyen C$30 al saldo **actual** del estudiante y se reabre deuda por C$100. No se sobrescribe el saldo con una instantánea antigua; otros cobros posteriores se conservan.

## Cómo se conserva el historial
- `AnulacionRecibo` guarda un registro por recibo: operación, responsable, motivo, receptor, referencia, dinero devuelto, saldo restituido y saldo antes/después de anular.
- `ReciboMultiple` y `AplicacionPago` no se borran ni se reescriben. `AplicacionPagoVigente` excluye las aplicaciones de recibos con contrapartida para calcular deuda cobrable.
- Cobro, anulación y consulta comparten el bloqueo financiero. La contrapartida, restitución de saldo y auditoría se confirman en una transacción.
- Mismo GUID y mismos datos devuelven la anulación existente. Cambiar datos con el mismo GUID se rechaza. Otra operación para un recibo ya anulado también se rechaza.
- Reenviar la operación original de cobro devuelve su recibo original, ahora marcado anulado: no lo reactiva ni vuelve a descontar saldo.
- Un nuevo cobro de la deuda reabierta necesita una operación nueva y genera otro número. No se reutiliza el número del recibo anulado.

## Si ocurre un error al confirmar
Consulta primero el recibo: puede haberse guardado aunque se haya perdido la respuesta. Conserva el formulario y su GUID para reintentar. **No vuelvas a entregar dinero.** El registro en SQL y la entrega física/bancaria no son una única transacción; si una devolución ya realizada queda pendiente de registrar, resuélvela con su comprobante y el mismo formulario. No se comprueba automáticamente que una referencia bancaria corresponda a una devolución real.

## Archivos principales
| Archivo | Función |
|---|---|
| `015_AnulacionRecibos.sql` | Tabla de contrapartidas y vista de aplicaciones vigentes |
| `AnulacionRecibos.sql` | Permiso de administrador, balance, reintentos, restitución y auditoría |
| `CobroMultiple.sql` | Actualiza cobro, deuda y consulta de recibos para reconocer anulaciones |
| `AnularRecibo.cshtml.cs` / `.cshtml` | Revisión y confirmación, con antifalsificación y usuario de sesión |
| `Recibo.cshtml.cs` / `.cshtml` | Conserva original y presenta historial de anulación |
| `Cuenta.cshtml` | Estado vigente/anulado y valores netos, sin sumar ingresos devueltos |
| `014_VerificarAnulaciones.sql` | Revisa contrapartida, auditoría y saldo actual |
| `tests/AnulacionReciboValidation` | Validaciones de entrada sin SQL Server |

## Pruebas integradas obligatorias
En una copia, no en la base cotidiana:
1. Anular efectivo con vuelto, transferencia, solo saldo y pago mixto. Comparar cantidades con el recibo original.
2. Cobrar parcialmente otro cargo después de un recibo y anular el anterior: conservar el movimiento posterior y sumar solo el saldo restituido.
3. Reenviar la misma anulación: una contrapartida, una auditoría y una restitución.
4. Dos administradores intentando anular a la vez con distintos GUID: solo uno confirma.
5. Cobrar y anular simultáneamente: no sobrepagar, no perder restitución y mantener la deuda correcta.
6. Cobrar de nuevo el cargo reabierto: nuevo recibo, original sigue anulado.
7. Intentar POST como Cajero o Profesor, sin antifalsificación o sin confirmación: denegado/rechazado.
8. Forzar fallo de auditoría en copia: rollback de contrapartida y saldo. No envolver el procedimiento en una transacción externa.
9. Repetir un cobro ya anulado con su operación original: devuelve el original sin reactivarlo.

Pendiente: ejecutar estos escenarios en SQL Server con usuarios reales de prueba. La revisión sintáctica y las pruebas C# no verifican transacciones ni concurrencia. No se implementa reactivación de recibos anulados, devolución parcial ni anulación del cargo en esta entrega.

## Validación de esta entrega
Compilación C#/Razor completada; 10 pruebas de entrada aprobadas. Cinco scripts analizados con ScriptDom sin errores de sintaxis. Inicio público 200 y páginas AnularRecibo, Recibo y Cuenta redirigen a login sin sesión. No se ejecutó SQL Server ni se probaron sesiones autenticadas o concurrencia.
