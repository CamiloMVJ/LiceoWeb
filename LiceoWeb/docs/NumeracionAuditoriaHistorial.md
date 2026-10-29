# Etapa 8: numeracion, auditoria e historial

## Alcance

Base comun para cobros y trazabilidad de operaciones. No implementa los cobros de cada modulo. No cambia pagos anteriores ni modifica 001/002. Los archivos SQL se revisaron como codigo; no se ejecutaron contra SQL Server en el entorno de elaboracion. Se requiere SQL Server 2016 o posterior y Identity ya instalado.

## Instalacion

Copiar las carpetas Services, database y docs dentro del proyecto LiceoWeb, junto a Program.cs, combinandolas con las existentes. No reemplazar archivos ajenos. Ejecutar en SSMS, conectado a LiceoWeb_Dev, cada archivo completo:

1. database/migrations/003_ComprobantesAuditoria.sql (solo una vez).
2. database/procedures/Registrar_Auditoria.sql.
3. database/procedures/Registrar_Comprobante.sql.
4. database/procedures/Obtener_ComprobanteHistorico.sql.
5. database/verification/002_VerificarEtapa8.sql.
6. database/verification/003_ProbarInfraestructuraConRollback.sql.

No seguir si un archivo falla. Los archivos de procedimientos son lotes independientes; CREATE OR ALTER PROCEDURE debe ser la primera instruccion del lote. La instalacion de tablas verifica la base y rechaza una segunda ejecucion. Los procedimientos se pueden volver a aplicar. No se necesita Add-Migration ni Update-Database para estos scripts del negocio.

En Program.cs, conservar los registros existentes. Agregar using LiceoWeb.Services; y, antes de builder.Build():

```csharp
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<UsuarioActual>();
```

No crear un DbSet de estas tablas en ApplicationDbContext: siguen bajo scripts SQL.

## Objetos

- Secuencia_Comprobantes: produce RC-1, RC-2... No utilizar MAX+1 por pago, fechas como clave ni reiniciar la secuencia. Se admiten saltos por rollback, pruebas o reserva de valores; unicidad no significa numeracion sin saltos. La PK existente de Pagos mantiene la unicidad global.
- Historial_Comprobantes: una fila por pago nuevo, vinculada al comprobante. Guarda operacion, usuario y su nombre, estudiante, modalidad/grado y componentes financieros del momento del pago. No sustituye la tabla de obligaciones ni los detalles de meses abonados.
- Auditoria: bitacora de cambios confirmados. Guarda autor, fecha local Nicaragua, accion, entidad, registro, correlacion y JSON antes/despues. No almacena contrasenas, hashes, tokens ni configuracion de conexion.
- UsuarioActual: obtiene el ID de la sesion del servidor; no acepta un ID de un campo de formulario.

## Integracion de cada cobro (Oskar/Pao/Har)

El servicio o procedimiento principal es dueno de la transaccion completa. Elegir un solo responsable de BEGIN/COMMIT/ROLLBACK. El auxiliar Registrar_Comprobante exige una transaccion abierta, NO confirma, NO cancela deudas, NO actualiza Abonos y NO devuelve un SELECT (evita interferir con ExecuteScalar del procedimiento principal).

1. Recibir un IdOperacion unico estable para la solicitud (Guid en C#, uniqueidentifier en SQL). Conservarlo al reintentar la misma operacion; no crear uno nuevo dentro del repositorio en cada intento.
2. Obtener UsuarioId mediante UsuarioActual en una solicitud autenticada y pasar ese valor al servicio/repositorio. Mantener las politicas y volver a comprobar permisos de la operacion.
3. Abrir la transaccion.
4. Bloquear por estudiante con SELECT ... FROM dbo.Estudiantes WITH (UPDLOCK, HOLDLOCK) WHERE Registro=@Registro; dentro de la misma transaccion. Leer deudas y saldo consistentes; todos los cobros de ese estudiante deben respetar esta convencion.
5. Validar estudiante, modalidad/grado del periodo, tarifas, deuda, metodo y referencia. Los importes de este auxiliar los calcula el negocio en el servidor, NO el navegador.
6. Calcular los seis importes y verificar el balance.
7. Ejecutar Registrar_Comprobante y capturar @IdComprobante OUTPUT. Modalidad y grado deben ser los de la operacion validada, que pueden diferir de los actuales del estudiante.
8. Actualizar obligaciones y saldo en la MISMA transaccion/conexion. Vincular cada obligacion cancelada a @IdComprobante.
9. Confirmar la transaccion y SOLO ENTONCES devolver ResultadoCobro al navegador. Cualquier error o duplicado revierte TODO. No capturar el error y confirmar parcialmente.
10. Si la misma IdOperacion vuelve a enviarse, el auxiliar rechaza el duplicado (error 51203 o restriccion unica en concurrencia). No reintentar el pago con otra ID. Se puede consultar el comprobante original despues de validar usuario y contenido de la solicitud; este paquete no implementa esa recuperacion automatica.

El navegador no elige el usuario, costo definitivo, saldo ni numero de comprobante. Un GUID ayuda a detectar reintentos, pero no reemplaza permisos ni control de concurrencia. Si una misma transaccion agrupa varios conceptos en un unico pago, definir un modelo de detalle antes de adaptar este auxiliar: actualmente es un concepto por comprobante.

## Importes

- DineroRecibido: dinero nuevo entregado, antes del vuelto.
- SaldoAnterior: saldo justo antes del movimiento (leido bajo bloqueo).
- SaldoUtilizado: parte del saldo anterior aplicada a obligaciones.
- DeudaCancelada: monto aplicado a obligaciones; los abonos insuficientes pueden quedar como saldo, segun el modulo.
- CambioDevuelto: parte del dinero nuevo que se devuelve; no devuelve saldo antiguo como efectivo.
- SaldoFinal: saldo resultante.
- SaldoAnterior + DineroRecibido = DeudaCancelada + CambioDevuelto + SaldoFinal.
- Para registros creados por este auxiliar, Pagos.Monto = DineroRecibido - CambioDevuelto (ingreso nuevo neto). No reinterpretar automaticamente registros anteriores sin historial.
- Tipo decimal(18,2); rechazar mas de dos decimales en C# antes de enviarlos a SQL.

ResultadoCobro existente no cambia. SaldoAnterior es dato adicional interno para persistencia/verificacion; no hace falta agregarlo al record para utilizar estos archivos.

## Auditoria en otros cambios

Registrar_Auditoria se invoca desde la misma transaccion que modifica la entidad. Oskar: altas/ediciones/bajas, con valores anteriores/nuevos relevantes. Pao: arreglos y tarifa mensual. Har: otras tarifas y sincronizacion de promocion. Camilo: integracion y lectura de reportes (las consultas no necesitan simular cambios).

Ejemplo de contrato de llamada SQL (valores calculados dentro del procedimiento del negocio):

```sql
EXEC dbo.Registrar_Auditoria
    @UsuarioId=@UsuarioId, @Accion=N'ActualizarPrecio',
    @Entidad=N'Costo_Mensualidad', @RegistroId=@Modalidad,
    @IdOperacion=@IdOperacion, @AntesJson=@AntesJson,
    @DespuesJson=@DespuesJson;
```

Obtener los valores anteriores antes de actualizar, bajo los bloqueos apropiados, y generar JSON con FOR JSON PATH, WITHOUT_ARRAY_WRAPPER. En cambios masivos escribir una entrada por registro afectado con la misma IdOperacion. Exitos de cambios se registran; intentos fallidos se envian a ILogger, no a una auditoria que deberia revertirse con la transaccion.

El auxiliar de cobros ya registra RegistrarCobro; no duplicar esa entrada. La auditoria no se genera automaticamente si un procedimiento no invoca el auxiliar. Los scripts no impiden que un administrador de BD modifique datos; en despliegue, restringir la cuenta de aplicacion a los procedimientos necesarios, evitando UPDATE/DELETE directo de la bitacora/historial y evitando modificar cabeceras de pagos confirmados. Esta bitacora no es un registro inviolable frente al administrador de BD.

## Lectura del recibo (Har)

Usar Obtener_ComprobanteHistorico. No reconstruir modalidad, grado o saldo con Estudiantes o Abonos actuales. Si DatosHistoricosDisponibles=0, los importes y datos no recuperables quedan NULL y la interfaz informa que no hay detalle historico disponible. No llenar esos NULL con datos actuales simulando datos antiguos. El procedimiento no contiene permisos por usuario: la pagina/servicio exige un rol autorizado antes de llamarlo.

Este historial conserva cabecera y resumen financiero, no el detalle de aplicacion por mes. Para listar meses/cuotas pagadas, usar las obligaciones vinculadas o una tabla de aplicaciones que el modulo implemente. La plantilla visual del recibo y datos del colegio se resuelven en el modulo de Har.

## Verificacion

002 espera dos tablas nuevas, una secuencia y tres procedimientos. La consulta de balances debe devolver cero filas. 003 crea un estudiante y comprobante temporales con 1000 recibido, 800 aplicado y 200 de vuelto; cambia temporalmente grado/modalidad, comprueba el historial y la auditoria, y revierte TODO con ROLLBACK. Requiere un administrador confirmado. Ejecutar la prueba completa, sin actividad concurrente. Los IDENTITY/secuencias pueden avanzar aunque se reviertan las filas.

003 prueba solo la infraestructura. La validacion definitiva necesita cobros reales de prueba de cada modulo: cuotas y saldo actualizados, varios pagos simultaneos, duplicado con el mismo GUID, fallo con rollback, reimpresion y conciliacion. Este paquete no habilita por si solo esos flujos.
