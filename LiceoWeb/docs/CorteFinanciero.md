# Corte financiero transaccional — desarrollo

## Estado y alcance
Implementado el procedimiento de simulación/aplicación de cargos y saldos conciliados, con barreras de escritura en el libro anterior. Migración, procedimiento y script de prueba pasan el análisis sintáctico con ScriptDom. NO se ejecutó contra SQL Server en este entorno. El siguiente módulo de cobro multiconcepto todavía no está habilitado: aplicar el corte dejará los cobros antiguos bloqueados. En esta etapa usar la simulación; probar aplicación únicamente en una copia descartable para validar la transición.
No existe botón de corte en la web. Nunca activar cambiando ControlFinanciero manualmente.

## Instalación
1. Base de desarrollo respaldada, migraciones hasta 011 y procedimientos actualizados de conciliación, recaptura, aranceles y saldos.
2. Ejecutar migrations/012_CorteFinanciero.sql una vez. No activa el corte: instala barreras y tablas de destino vacías.
3. Ejecutar procedures/CorteFinanciero.sql completo.
4. Terminar la captura y revisión vigente de todas las obligaciones. No puede quedar una rechazada o con fuente cambiada/ausente.
5. Aprobar documentalmente el saldo de cada estudiante con pagos, abonos u obligaciones, aunque el saldo sea cero. Una aprobación antigua no sirve si hubo pagos o cambios posteriores.
6. Ejecutar sin actividad concurrente en una ventana de mantenimiento: la simulación también bloquea tablas temporalmente y puede consumir identidades aunque termine en rollback.

## Simulación
Obtener el Id real de la cuenta administradora en AspNetUsers. En SSMS, sobre LiceoWeb_Dev:

```sql
DECLARE @Usuario nvarchar(450)=N'ID_REAL_DEL_ADMINISTRADOR';
DECLARE @Operacion uniqueidentifier=NEWID();
EXEC dbo.CorteFinanciero_Ejecutar
 @UsuarioId=@Usuario,@Operacion=@Operacion,@Aplicar=0;
```
Resultado esperado: SIMULACION_REVERTIDA, cantidad de cargos, total de deuda y saldo inicial. Los destinos permanecen vacíos. Si falla, resolver el error de conciliación; no borrar controles ni omitir validaciones. La referencia a una cuenta de administrador en SSMS solo es válida para un operador de base autorizado; no exponer UsuarioId como campo editable en una futura web.

## Qué comprueba y transforma
- Bloqueo compartido con configuración financiera y bloqueos exclusivos en fuentes, revisiones y destinos. Los procedimientos antiguos no usan el bloqueo de aplicación, por eso se bloquean también sus tablas.
- Misma colección de obligaciones en fuente/captura; última revisión aprobada de la generación actual; tarifa compatible con concepto/año/modalidad.
- Deuda: solo pendiente/vencido, importe positivo, sin comprobante. SinDeuda: cancelada o importe cero. Comprobante debe corresponder al estudiante.
- La última revisión del saldo debe estar aprobada y su huella coincidir con pagos/historial/saldo actuales.
- Se exige destino vacío antes del primer corte: no mezcla datos manuales del libro nuevo con la migración.
- Crea cargos solo para Deuda, con importe histórico y referencia única LEGADO:tabla:Id. Registra todas las obligaciones en ObligacionMigrada, incluidas SinDeuda sin cargo.
- Vencimiento queda NULL porque el origen no siempre acredita una fecha exacta; no se inventa mora. Los futuros reportes deben distinguir vencimiento desconocido.
- SaldoFinanciero conserva importe inicial, disponible e Id de la revisión que lo respalda. No lo registra como ingreso ni emite recibos por pagos antiguos.
- Verifica totales y activa barreras en la misma transacción. Cualquier error revierte control, cargos, saldos, correspondencias y auditoría.

## Aplicación en copia descartable
Solo después de aprobar las pruebas de simulación, respaldo y permisos. Conservar un Guid para la operación. Llamar al mismo procedimiento con Aplicar=1 y Confirmacion=N'APLICAR CORTE EN DESARROLLO'. Esto cierra las escrituras antiguas; no habilita por sí mismo el nuevo módulo de cobros.
Reintentar con el mismo Guid devuelve YA_APLICADO sin duplicar datos; con otro Guid se rechaza. No hay reapertura desde la aplicación. Para deshacer un ensayo aplicado, restaurar la copia descartable respaldada, no cambiar Migrado a cero.

## Barreras y límites
Triggers AFTER INSERT/UPDATE/DELETE bloquean tablas financieras antiguas, tarifas antiguas y preparación/revisiones después del corte. No impiden que un administrador de SQL deshabilite triggers o ejecute TRUNCATE: usar una cuenta de aplicación sin privilegios de DDL/administración para el despliegue. Los triggers se comprueban habilitados antes de cortar. La edición de estudiantes sigue disponible.
Las pantallas antiguas aún no se han sustituido: después del corte un intento de escribir fallará. Queda pendiente adaptar la navegación y presentar un aviso específico junto con los cobros nuevos. Las consultas históricas pueden seguir leyendo.

## Pruebas obligatorias
verification/011_VerificarSimulacionCorte.sql comprueba simulación y repetición sin datos persistidos; requiere base completamente conciliada. No ha sido ejecutado aquí.
En otra copia descartable: aplicar, verificar deudas y saldos por estudiante, cero nuevos pagos/recibos, correspondencias únicas; reintentar Guid; rechazar otro Guid; intentar INSERT/UPDATE/DELETE desde cada módulo antiguo; provocar error durante aplicación y comprobar rollback; ejecutar cobro antiguo concurrente y confirmar bloqueo o aborto sin corrupción. Probar revisiones antiguas y fuente modificada, tarifa ajena y destino no vacío. Verificar ausencia de bloqueo en operación normal antes del corte.

## Continuar
Cobro multiconcepto con número común, pagador, saldo anterior/final, operación idempotente y reversos; después estado de cuenta y sustitución de rutas antiguas. No dar el sistema financiero por terminado al instalar esta etapa.
