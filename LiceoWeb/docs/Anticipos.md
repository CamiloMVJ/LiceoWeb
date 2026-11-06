# Anticipos de estudiantes

En **Cobrar a estudiante**, abre la cuenta de un estudiante activo y pulsa **Registrar anticipo**. Introduce el pagador, el importe ya recibido y el método (efectivo o transferencia; para transferencia se exige referencia). **Acreditar saldo y emitir recibo** deja el dinero como saldo a favor, incluso si la cuenta no tiene deuda. El recibo identifica el anticipo y muestra el saldo antes y después. En un cobro posterior se puede usar **Saldo a favor a utilizar** o **Solo saldo a favor**.

Administrador y Cajero pueden registrar anticipos después del corte financiero. Un mismo envío no acredita saldo dos veces: si se interrumpe la respuesta, consulta los recibos y reintenta desde el mismo formulario. El sobrante de un cobro normal continúa siendo vuelto.

La devolución de un anticipo sigue el flujo de **Revisar anulación**, exclusivo del Administrador. Solo procede si el saldo disponible alcanza para retirar todo el importe; no genera cargos ni reabre deuda. Si el importe se usó y el saldo es insuficiente, no devuelvas dinero con este formulario: revisa las aplicaciones de saldo. En el reporte, un anticipo es entrada de dinero, no un importe aplicado a deuda.

## Instalación

Con la aplicación detenida y en su base de SQL Server, ejecutar una vez `database/migrations/023_Anticipos.sql`. Después ejecutar completos estos archivos de `database/procedures/`, en orden:

1. `CobroMultiple.sql`
2. `Anticipos.sql`
3. `AnulacionRecibos.sql`
4. `ReporteFinanciero_Consultar.sql`

Recompilar y reiniciar. La migración conserva los recibos anteriores y permite que un saldo nuevo exista sin una revisión de migración histórica.

## Verificación en una copia de la base

- Como Cajero, registrar C$ 350,25 a un estudiante activo sin saldo ni deuda. El recibo debe mostrar C$ 350,25 acreditados, cero aplicado a deuda y el mismo saldo disponible en la cuenta.
- Reenviar la misma operación: debe abrir el mismo recibo sin volver a acreditar. Probar una transferencia sin referencia: debe rechazarse.
- Crear un cargo de prueba y aplicarle C$ 100 de ese saldo. La cuenta debe mostrar C$ 250,25. Intentar anular el anticipo de C$ 350,25: debe bloquearse por saldo insuficiente.
- Anular el pago que aplicó saldo en la copia de pruebas. El saldo debe volver a C$ 350,25 y permitir comprobar la devolución del anticipo. Tras anularlo, el saldo debe quedar en cero; el reporte debe mostrar la entrada y devolución del anticipo, sin contarlas como deuda aplicada o revertida.
- Verificar que un recibo previo de cobro se sigue abriendo e imprimiendo, y que Profesor no puede acceder al formulario.
