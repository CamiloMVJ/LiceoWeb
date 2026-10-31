# Transición de pantallas antiguas e impresión

Esta entrega modifica la aplicación; **no agrega una migración SQL**. La base debe tener completas las etapas hasta 015 y sus procedimientos actualizados, especialmente `CobroMultiple.sql`.

## Actualizar
1. Guarda tus cambios locales y actualiza `revision-profesor-2026-10-29`.
2. Verifica la instalación hasta 015 según `AnulacionRecibos.md`. Compila y reinicia la aplicación.
3. Antes del corte (`ControlFinanciero.Migrado=0`), el menú conserva los accesos anteriores. Si la tabla todavía no existe, se considera una instalación anterior a 012.
4. Después del corte (`Migrado=1`), se ocultan Mensualidades, Gestión de mensualidades, Mantenimiento, Evaluaciones, Promoción, Comprobantes, Arreglos, Tarifas y Reportes del libro anterior. Usa Estado de cuenta, Generar cargos y Aranceles. Los pagos históricos se consultan dentro de la cuenta de cada estudiante.
5. Una URL antigua de consulta redirige a `/Finanzas/LibroAnterior`, con enlaces al módulo nuevo. Un POST u otro envío antiguo devuelve 409 sin ejecutar el handler; no reproduce automáticamente el movimiento en el módulo nuevo.
6. Si no se puede verificar el estado en la base, esas rutas devuelven 503 y no ejecutan operaciones. El menú oculta temporalmente los enlaces antiguos e informa del problema. No se interpreta una falla de conexión como permiso para operar el libro anterior.

## Cobertura
El filtro protege todas las páginas de `/Cobros`, `/Mensualidades`, `/Matriculas`, `/Precios`, `/Arreglos`, `/Recibos` y `/Reportes`. Incluye variantes antiguas como Cobros/Index1 e Index2. No afecta `/Estudiantes/Expediente`, los módulos académicos ni Identity. La autorización de roles se ejecuta antes del filtro.

La consulta del estado se comparte únicamente dentro de una petición, no se guarda entre peticiones. Una pestaña antigua que envíe después del corte vuelve a comprobar el estado. Si una petición alcanzó el handler justo mientras se aplicaba el corte, los triggers de la migración 012 siguen siendo la barrera definitiva contra escrituras en el libro cerrado. El filtro mejora la navegación, no reemplaza esos triggers.

No se implementan reportes financieros consolidados nuevos en esta entrega. Los reportes anteriores se retiran tras el corte para evitar presentar datos incompletos como si fueran los resultados del libro nuevo.

## Imprimir recibos
1. Abre **Estado de cuenta y cobros**, busca al estudiante y selecciona un recibo.
2. Pulsa **Versión para imprimir o guardar PDF**.
3. Se abre `/Finanzas/ImprimirRecibo/{id}`, con los datos reales del recibo y sin menú ni barra de sesión. Mantiene la misma autorización y consulta de la página de recibos; no contiene datos de ejemplo.
4. Pulsa **Imprimir o guardar PDF**. Selecciona impresora o PDF en el navegador. Usa A4 o Carta; desactiva encabezados/pies del navegador si no deseas la URL.
5. Los recibos anulados conservan la marca **RECIBO ANULADO**, motivo, responsable, referencia, dinero devuelto y saldo restituido, además del detalle original. Los saldos impresos son las instantáneas del comprobante, no el saldo actual.
6. Para recibos largos, el encabezado de tabla se repite y se evita dividir una fila. Revisa siempre la vista previa del navegador, especialmente con conceptos largos o muchas aplicaciones.

La página es HTML imprimible; no genera ni guarda automáticamente un archivo PDF en el servidor. El pequeño JavaScript llama a `window.print()`: no calcula importes ni modifica datos.

## Archivos
| Archivo | Función |
|---|---|
| `Services/EstadoLibroFinanciero.cs` | Consulta de estado con límite de tiempo y caché por petición |
| `Filters/LibroAnteriorFilter.cs` | Redirección de GET/HEAD y bloqueo de envíos antiguos antes del handler |
| `Program.cs` | Registro del servicio y filtro global de Razor Pages |
| `_NavigationPartial.cshtml` | Menú según el estado real del libro |
| `Finanzas/LibroAnterior.cshtml` | Orientación al acceder a una pantalla anterior |
| `Finanzas/_DetalleRecibo.cshtml` | Contenido compartido por consulta e impresión, incluido historial |
| `Finanzas/ImprimirRecibo.cshtml` | Documento independiente y protegido para imprimir |
| `wwwroot/css/recibo-impresion.css` | Estilos de pantalla/papel y paginación |
| `wwwroot/js/recibo-impresion.js` | Abre el diálogo de impresión |
| `tests/LibroAnteriorValidation` | Prueba el filtro con estados simulados y verifica que no ejecuta handlers bloqueados |

## Validaciones pendientes en tu entorno
- En copia de SQL Server: comprobar menú antes/después del corte y fallo de conexión. Probar GET y POST antiguo desde una pestaña abierta antes del corte.
- Como Cajero/Administrador: consulta e impresión. Como Profesor: acceso denegado. Probar antifalsificación y autorización con sesiones reales.
- Imprimir recibos vigentes/anulados, con nombres y motivos largos y con hasta 50 conceptos, tanto A4 como Carta. Comprobar que marca de anulado, importes y saltos de página resulten legibles.
- El nuevo flujo de matrícula todavía requiere integración con cargos; retirar el formulario financiero anterior no completa esa integración.

## Continuar más tarde
Siguiente bloque: integración definitiva de matrícula académica con generación de cargos, pruebas SQL de cobros/anulaciones y resolución de pendientes académicos/cuentas documentados en RevisionProfesor.md. Reportes consolidados nuevos pendientes. No confundir compilación y pruebas con estados simulados con validación operativa en el colegio.

## Verificación realizada en esta entrega
Compilación C#/Razor sin errores y 13 pruebas del filtro aprobadas con estados simulados, incluyendo 409, 503 y no ejecución del handler. Pruebas HTTP: inicio público 200; impresión, página de transición y Cobros redirigen a login sin sesión; CSS y JavaScript responden 200. No se validó el menú contra SQL Server ni el resultado visual/impreso de recibos autenticados.
