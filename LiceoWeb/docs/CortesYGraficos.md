# Gráficos y cortes desde la interfaz

**Cobros y devoluciones** muestra entradas, devoluciones, neto, anticipos, estudiantes distintos y promedio de dinero recibido por recibo. Los gráficos incluyen todo el rango filtrado, no solo la página de movimientos. Para más de 62 días se agrupan por mes. Las fechas son locales de Nicaragua; los recibos pagados solo con saldo no se cuentan como dinero nuevo. Las barras tienen detalles y tabla alternativa. El CSV conserva el detalle original.

## Dos procesos diferentes

- **Transición al libro nuevo:** una sola vez. Administración entra a **Cortes de caja**, simula la transición, revisa los resultados y confirma. Se ejecuta el procedimiento real con sus comprobaciones de conciliación. No permite regresar al libro antiguo ni repetir la migración como si fuera un nuevo día.
- **Cortes de caja:** períodos de actividad del libro nuevo. Un administrador abre caja con su fondo físico, cierra indicando el efectivo contado y el motivo, o usa **Cerrar y abrir el siguiente**. No se pueden reabrir ni editar cortes cerrados.

El esperado de efectivo es **fondo + entradas en efectivo − devoluciones en efectivo**. Transferencias y aplicaciones de saldo no incrementan el efectivo físico. El nuevo fondo es una declaración de efectivo que queda en caja, no ingreso ni saldo de un estudiante; no se arrastra automáticamente. La diferencia entre contado y esperado se conserva, incluso si es distinta de cero, junto con el motivo.

Los cobros, anticipos y devoluciones nuevos se vinculan al corte abierto desde SQL. Si no hay uno, se bloquean con mensaje. La creación de cargos no recibe dinero y puede continuar. Todos esos procedimientos comparten el bloqueo financiero: un cierre no captura un cobro a medias. Los cierres guardan una instantánea de los totales y una operación para reintentos.

## Instalación sobre una base existente

Detener la aplicación. Ejecutar **024_CortesCaja.sql** una vez, luego actualizar:
1. CortesCaja.sql
2. CobroMultiple.sql
3. Anticipos.sql
4. AnulacionRecibos.sql
5. CorteFinanciero.sql
6. ReporteFinanciero_Consultar.sql

Todos en database/procedures, salvo la migración en database/migrations. La migración abre el primer corte si el libro nuevo ya está activo y le asigna los movimientos existentes; no inventa un cierre ni un arqueo anterior. El fondo inicial de ese corte es cero: el administrador debe tenerlo en cuenta al comparar con el efectivo real. Si el libro sigue antiguo, el corte inicial se abrirá al confirmar la transición en la interfaz.

El instalador completo ya incluye 024 y los procedimientos; la demostración comienza con un corte abierto. No volver a ejecutar el instalador completo sobre una base existente.

## Verificación en copia de desarrollo

- Comparar métricas y gráficos con los totales del CSV, incluyendo un rango sin movimientos, devoluciones sin cobros y pagos solo con saldo.
- Como administrador, cerrar indicando el contado y abrir el siguiente; comprobar que el historial conserva el resumen del corte anterior.
- Cobrar en el nuevo corte y devolver un recibo de un corte anterior: la devolución corresponde al corte actual, sin cambiar los totales cerrados.
- Cerrar sin abrir otro: Caja debe rechazar pagos/anticipos/devoluciones; abrir uno y comprobar que vuelven a estar disponibles.
- Dos administradores cerrando el mismo corte: el segundo formulario debe rechazarse, o devolver el mismo resultado si es el mismo reintento.
- Cajero y Profesor no pueden abrir la pantalla ni ejecutar sus acciones directas. El Cajero conserva cobros en una caja abierta.
- La transición inicial debe simular antes de confirmar; si hay discrepancias históricas debe detenerse sin poner Migrado a 1.

Estas pruebas de SQL Server y sesiones reales deben ejecutarse en una copia; la compilación y la validación de entrada no prueban la persistencia.
