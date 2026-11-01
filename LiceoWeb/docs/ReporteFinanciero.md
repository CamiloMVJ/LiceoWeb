# Reporte de cobros y devoluciones

Instalación: actualizar la rama, detener la aplicación y ejecutar completo `database/procedures/ReporteFinanciero.sql` sobre LiceoWeb_Dev. Compilar/reiniciar. No hay migración nueva; mantener instaladas las etapas hasta 017 y sus procedimientos. Requiere corte aplicado.

Entrar como Administrador en **Cobros y devoluciones**. Elegir fechas desde/hasta (ambas incluidas), máximo 366 días. Las fechas corresponden a Nicaragua (UTC−6); los datos UTC se filtran usando límites equivalentes. Por defecto muestra el mes actual.

## Interpretación
- Dinero cobrado: recibido menos vuelto, en la fecha del recibo.
- Dinero devuelto: devolución documentada, en la fecha de anulación.
- Dinero neto: cobrado menos devuelto. Puede ser negativo si se devuelven cobros de otro período.
- Saldo neto: saldo a favor utilizado menos restituido; no es ingreso nuevo.
- Aplicado neto: aplicaciones a deuda menos importes revertidos por anulaciones.
- Agrupación por método y detalle por movimiento con enlace al recibo. El responsable de una devolución es quien anuló, no necesariamente quien cobró.

El reporte conserva el cobro original aunque el recibo se anule después. Por ejemplo: cobro de C$100 el lunes y anulación el martes muestran +100 el lunes y −100 el martes; consultar ambos días arroja cero neto. No se excluye el lunes retroactivamente. Los totales se calculan sobre todo el rango y el detalle muestra 100 movimientos por página. La consulta toma una instantánea temporal bajo el bloqueo financiero; al cambiar de página se realiza otra consulta y podrían existir nuevos movimientos.

No incluye Pagos históricos anteriores al corte ni constituye un balance de deuda, cierre de caja o conciliación bancaria. No exporta a Excel/PDF en esta etapa. Acceso solo para Administrador tanto en Razor como SQL; sin caché de datos personales.

## Pruebas pendientes en SQL Server y navegador
1. Cobro efectivo recibido 120/vuelto 20: cobrado 100.
2. Pago mixto: dinero 70 y saldo 30, aplicado 100; dinero no debe ser 100.
3. Anulación dentro/fuera del rango: aparece por fecha de anulación; saldo restituido negativo, dinero devuelto separado.
4. Solo saldo: dinero cero, saldo/aplicado positivos; anulación los revierte.
5. Límites locales: 05:59:59 UTC pertenece al día anterior; 06:00:00 UTC inicia el día local. Fecha hasta incluye todo su día, sin incluir el siguiente.
6. Más de 100 movimientos: totales constantes entre páginas sin nuevas operaciones; todos los eventos accesibles.
7. Base sin movimientos: resumen cero y mensaje explícito.
8. Usuarios Profesor/Cajero: acceso denegado; Administrador permitido.
9. Generación y anulación concurrentes con la consulta: instantánea coherente.

No ejecutado contra SQL Server en esta entrega. Las pruebas de entrada y la revisión sintáctica no validan estas reglas en ejecución.

Validación realizada: compilación C#/Razor sin errores, 8 pruebas de entrada aprobadas, revisión sintáctica ScriptDom sin errores y acceso HTTP anónimo redirigido a login. Persisten 40 advertencias anteriores de nulabilidad. SQL Server, sesiones autenticadas y revisión de cifras quedan pendientes.
