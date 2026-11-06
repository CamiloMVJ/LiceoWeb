# Permisos de LiceoWeb

Los nombres de roles de Identity son `Administrador`, `Cajero` y `Profesor`. Los tres pueden entrar al panel interno. La portada y el inicio de sesión son públicos.

| Pantalla o acción | Administrador | Cajero | Profesor |
| --- | --- | --- | --- |
| Listado y búsqueda de estudiantes | Sí | Sí | No |
| Crear, actualizar o dar de baja expedientes | Sí | No | No |
| Consultar cuenta, cobrar y abrir recibos | Sí | Sí | No |
| Generar cargos individuales y globales | Sí | No | No |
| Aranceles, conciliación, reportes, anulación de recibos | Sí | No | No |
| Organización académica, catálogos, inscripción a grupos | Sí | No | No |
| Calificaciones | Todas las asignaciones | No | Sus asignaciones |
| Mi horario | Su propio horario por URL directa | No | Su propio horario |
| Tipos de evaluación, cierre e historial académico | Sí | No | No |
| Cuentas del personal | Sí | No | No |

Las pantallas antiguas de cobros, mensualidades, matrículas y recibos admiten Administrador y Cajero solo mientras esté abierto el libro anterior. Las de precios, arreglos y reportes antiguos son exclusivas del Administrador y también se cierran al aplicar el corte. Los GET antiguos redirigen al aviso del libro anterior después del corte; los POST se bloquean.

## Cobrar como cajero

1. En el menú o panel elige **Cobrar a estudiante**. También puedes entrar al listado y pulsar **Ver cuenta y cobrar** junto al estudiante.
2. Consulta la cuenta. Para registrar un pago en el libro nuevo se requiere corte aplicado y al menos un cargo pendiente.
3. Indica pagador, método y monto a aplicar. Confirma el cobro y abre el recibo.
4. Si falta una obligación, solicita al Administrador que la genere en **Generar cargos**.

La política `GestionFinanciera` protege la cuenta y los recibos; SQL comprueba el rol también. Las páginas de administración requieren `SoloAdministrador`. Ocultar una opción del menú no sustituye estas validaciones.

Para verificar en una copia de desarrollo: ingresar con una cuenta de cada rol; revisar el menú y probar acceso directo a `/Finanzas/Cuenta`, `/Finanzas/Cargos` y `/Planificacion`. En Cajero probar la cuenta con y sin deuda, y registrar un pago de prueba sobre un cargo pendiente.
