# Recaptura de obligaciones con historial
Instalación: migraciones hasta 009; ejecutar una sola vez migrations/010_RecapturaObligaciones.sql y después actualizar procedures/Conciliacion.sql completo. Actualizar la aplicación al mismo tiempo: la revisión ahora requiere GeneracionEsperada. No repetir 008/009.

En Conciliación de obligaciones, abrir una obligación, explicar el motivo y pulsar Recapturar origen con este motivo. No exige seleccionar tarifa ni decisión para recapturar. Guarda la captura anterior/nueva con responsable y fecha. Luego seleccionar tarifa compatible y registrar una nueva revisión.
No genera cargos ni pagos. La generación aumenta y las decisiones anteriores quedan históricas. Aunque una fuente vuelva a sus valores anteriores, su aprobación antigua no se reactiva.
No permite origen inexistente, estudiante cambiado, captura ya vinculada a cargo, operación sin diferencias ni formularios antiguos. La versión de captura y la última revisión se verifican bajo el mismo bloqueo transaccional de configuración financiera.
La consulta del historial muestra hasta 200 capturas de la obligación. Las instantáneas JSON incluyen sus valores anteriores y nuevos.

Validación pendiente: no se ejecutaron compilación ni SQL Server en esta continuación. Probar en copia de desarrollo:
1. Capturar y revisar una obligación pendiente.
2. Cambiar el importe en el origen de prueba: revisión rechazada hasta recapturar.
3. Recapturar con motivo: historial antes/después, generación incrementada, decisión anterior no vigente.
4. Guardar desde una pestaña anterior: rechazo sin cambios.
5. Nueva revisión con generación actual: aceptada.
6. Repetir recaptura sin diferencias: rechazo.
7. Probar Profesor/Cajero, origen ausente, cambio de estudiante y captura con CargoId.
8. Fallo de auditoría: rollback de captura e historial.
Los procesos futuros de migración deben exigir generación coincidente y volver a validar la fuente bajo bloqueo; no basta escoger la última decisión por Id.

Próximo bloque: conciliar Abonos y pagos históricos; corte de escrituras antiguas antes de migrar cargos y habilitar recibos multiconcepto y estado de cuenta. Esta función no completa la migración financiera.
