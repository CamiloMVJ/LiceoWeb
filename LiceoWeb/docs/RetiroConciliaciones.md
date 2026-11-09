# Operación web sin traslado del sistema de escritorio

Desde la migración **025**, se retiran Conciliación de obligaciones y Conciliación de saldos a favor. No son un cierre anual ni un corte de caja. Ya no se importa información del programa de escritorio.

Se eliminan las dos páginas y sus modelos, repositorio, registro de servicios, opciones del menú y procedimientos. Aranceles conserva solo Arancel y Tarifa: desaparecen Vincular conceptos, Preparar obligaciones, correspondencias y capturas. Cortes de caja conserva abrir, cerrar, cerrar y abrir el siguiente e historial; se retira la simulación/activación del libro anterior.

## Actualizar una base existente

1. Respaldar la base y detener la aplicación.
2. Actualizar la rama ajustes-verificacion-vistas.
3. En SSMS seleccionar la base usada por la aplicación y ejecutar **todo database/migrations/025_RetirarConciliacionesLegadas.sql**. Requiere las etapas hasta 024.
4. No ejecutar otra vez 001–024 ni el instalador completo sobre esa base. La 025 incluye la actualización de todos los procedimientos afectados, sin SQLCMD ni archivos externos.
5. Compilar y arrancar la aplicación. Si no había caja abierta, el administrador la abre en **Cortes de caja**.
6. Ejecutar database/verification/025_VerificarSinConciliaciones.sql: es de solo lectura y comprueba retiro e integridad financiera.

La actualización es transaccional. Quita los procedimientos Conciliacion_*, Saldo_Instantanea, Saldo_Consultar, Saldo_Revisar y CorteFinanciero_Ejecutar; la vista ObligacionLegada; y las tablas ObligacionMigrada, RevisionObligacion, HistorialCaptura, PreparacionObligacion, MapaConceptoLegado y RevisionSaldo. Los datos de preparación/revisión contenidos en estas tablas se eliminan por el retiro solicitado. Las tablas de auditoría se conservan.

No cambia estudiantes, usuarios, notas, cargos, aplicaciones, recibos, anulaciones, saldo inicial/disponible ni cierres de caja. Se conserva la columna nullable RevisionSaldoId sin su FK, únicamente para compatibilidad con los scripts demo ya distribuidos; el programa ya no la consulta ni la usa para aprobar/importar saldos. No se reabren cajas cerradas ni se genera efectivo.

Migrado queda en 1 como indicador interno de compatibilidad del esquema web. No implica una transferencia de datos. Las URLs de las páginas retiradas dejan de existir; los formularios financieros heredados siguen bloqueados y no se muestran en el menú.

## Nuevas instalaciones

El instalador completo llega hasta 025 y deja directamente activo el esquema web. Sus tres cuentas y datos demo se mantienen; se abre la caja demo después de crear las cuentas. No requiere simulación ni conciliación ni activación manual.

## Operaciones que continúan disponibles

- Aranceles y tarifas para precios por año/modalidad.
- Cargos individuales, por modalidad y mensualidades.
- Cuenta del estudiante, cobros, anticipos, recibos y devoluciones.
- Reporte con gráficos y cortes de caja exclusivos del administrador.
- Matrícula, horarios y calificaciones.

Los archivos 001–024 se conservan como historia de evolución del esquema para poder actualizar instalaciones existentes. Las guías antiguas de conciliación no son instrucciones de instalación vigentes.

## Pruebas

Compilar la aplicación y ejecutar ArancelesValidation, CortesCajaValidation, LibroAnteriorValidation, CobroMultipleValidation, AnticipoValidation, AnulacionReciboValidation y GeneracionCargosValidation. El generador y test_instalador verifican la reproducibilidad y las dependencias de la instalación. Estas comprobaciones no sustituyen ejecutar 025 y su verificación sobre una copia de SQL Server.

### Resultado de comprobaciones en este cambio

- Aplicación y Razor: compilación .NET 8 con 0 errores y 0 advertencias.
- Ocho suites de validación aprobadas (aranceles, caja, barrera de rutas antiguas, cobros, anticipos, anulaciones, cargos e Identity demo).
- HTTP local: GET y POST de las dos páginas retiradas responden 404; Cortes y Cuenta siguen exigiendo inicio de sesión (302 sin sesión).
- Generación reproducible de la migración 025 y del instalador; 47 procedimientos vigentes sin referencias a objetos retirados.
- Sintaxis SQL revisada con ScriptDom. La ejecución transaccional de 025, los balances reales y la presentación autenticada requieren comprobarse en una copia de SQL Server; no se ejecutaron en la base del usuario.
