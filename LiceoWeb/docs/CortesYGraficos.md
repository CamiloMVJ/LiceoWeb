# Gráficos y cortes desde la interfaz

**Cobros y devoluciones** muestra entradas, devoluciones, neto, anticipos, estudiantes distintos y promedio de dinero recibido por recibo. Los gráficos incluyen todo el rango filtrado, no solo la página de movimientos. Para más de 62 días se agrupan por mes. Las fechas son locales de Nicaragua; los recibos pagados solo con saldo no se cuentan como dinero nuevo. Las barras tienen detalles y tabla alternativa. El CSV conserva el detalle original.

## Cortes de caja

Un administrador abre caja con su fondo físico, cierra indicando el efectivo contado y el motivo, o usa **Cerrar y abrir el siguiente**. No se pueden reabrir ni editar cortes cerrados. La transición desde escritorio y sus conciliaciones fueron retiradas en 025.

El esperado de efectivo es **fondo + entradas en efectivo − devoluciones en efectivo**. Transferencias y aplicaciones de saldo no incrementan el efectivo físico. El nuevo fondo es una declaración de efectivo que queda en caja, no ingreso ni saldo de un estudiante; no se arrastra automáticamente. La diferencia entre contado y esperado se conserva, incluso si es distinta de cero, junto con el motivo.

Los cobros, anticipos y devoluciones nuevos se vinculan al corte abierto desde SQL. Si no hay uno, se bloquean con mensaje. La creación de cargos no recibe dinero y puede continuar. Todos esos procedimientos comparten el bloqueo financiero: un cierre no captura un cobro a medias. Los cierres guardan una instantánea de los totales y una operación para reintentos.

## Instalación sobre una base existente

Después de 024, ejecutar únicamente **migrations/025_RetirarConciliacionesLegadas.sql** con la aplicación detenida. El archivo actualiza los procedimientos relacionados y conserva los cortes y movimientos existentes. Si la caja está cerrada, el administrador debe abrirla desde Cortes de caja.

El instalador completo incluye 025; la demostración comienza con un corte abierto. No volver a ejecutar el instalador sobre una base existente. Ver RetiroConciliaciones.md.

## Verificación en copia de desarrollo

- Comparar métricas y gráficos con los totales del CSV, incluyendo un rango sin movimientos, devoluciones sin cobros y pagos solo con saldo.
- Como administrador, cerrar indicando el contado y abrir el siguiente; comprobar que el historial conserva el resumen del corte anterior.
- Cobrar en el nuevo corte y devolver un recibo de un corte anterior: la devolución corresponde al corte actual, sin cambiar los totales cerrados.
- Cerrar sin abrir otro: Caja debe rechazar pagos/anticipos/devoluciones; abrir uno y comprobar que vuelven a estar disponibles.
- Dos administradores cerrando el mismo corte: el segundo formulario debe rechazarse, o devolver el mismo resultado si es el mismo reintento.
- Cajero y Profesor no pueden abrir la pantalla ni ejecutar sus acciones directas. El Cajero conserva cobros en una caja abierta.

Estas pruebas de SQL Server y sesiones reales deben ejecutarse en una copia; la compilación y la validación de entrada no prueban la persistencia.
