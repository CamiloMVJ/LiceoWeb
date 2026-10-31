# Conciliación de saldos a favor

## Instalación
Después de 010, ejecutar migrations/011_RevisionSaldo.sql una vez y procedures/ConciliacionSaldos.sql completo. Actualizar código y abrir **Conciliación de saldos** como Administrador.
Buscar por código de estudiante; consultar saldo de Abonos y comprobantes; elegir Aprobado/Rechazado, indicar referencia documental y motivo. Guardar no modifica Abonos ni genera cargos, pagos o ingresos.

## Reglas
Cada revisión conserva saldo observado, número de filas, instantánea de pagos/historial, huella SHA-256, decisión, respaldo, responsable y fecha UTC. La última revisión debe seguir coincidiendo con la fuente antes de cualquier migración futura. No basta encontrar una aprobación antigua.
La lectura captura saldo y pagos en una transacción; el guardado vuelve a leer y compara. Cambios en saldo o pagos y revisiones simultáneas se rechazan. Se usa el bloqueo de configuración y el de estudiante compartido con el contrato de cobros; HOLDLOCK protege las fuentes durante la captura.
Saldo negativo o varias filas de Abonos impiden aprobar. Ausencia de Abonos se representa como cero con cero filas y requiere decisión documental. No se deducen deudas del saldo ni se reconstruyen automáticamente movimientos anteriores.
Un comprobante con balance inconsistente impide aprobar. Un pago SIN_HISTORIAL exige respaldo documental; el administrador puede aprobar el saldo después de verificarlo, pero esto no certifica cada pago ni convierte su Monto en ingreso nuevo.
Las referencias documentales son texto, no archivos adjuntos. La pantalla muestra todos los pagos del estudiante y las últimas 200 revisiones; para volúmenes grandes queda pendiente paginar pagos.

## Verificación
La solución completa, incluidas las pantallas de conciliación y recaptura anteriores, se compiló con SDK .NET 8. Resultado: 0 errores, 40 advertencias anteriores. Pasan 7 pruebas de validación del formulario (tests/SaldosValidation). HTTP sin sesión: portada 200; saldos y conciliación redirigen al login (302). Las pruebas contra SQL Server siguen pendientes.
verification/010_VerificarSaldo.sql prueba saldo decimal sin generación de pago y rechazo por cambio de fuente o revisión anterior; revierte cada caso. Requiere administrador, base de desarrollo y ausencia de actividad concurrente. Las secuencias pueden avanzar.
Probar además GET/POST como Profesor y Cajero, saldo negativo/duplicado, pago sin historial, balance inconsistente, dos administradores y cobro concurrente. No considerar revisión contable aprobada por el mero hecho de que compile.

## Pendientes
No existe aún corte de escrituras antiguas, importación de saldos iniciales, generación efectiva de cargos, cobro multiconcepto ni estado de cuenta unificado. La aprobación registra la revisión del saldo para ese futuro corte. No habilitar el esquema nuevo con SQL manual.
