# Acuerdos técnicos de LiceoWeb

## 1. Tecnología y arquitectura

- Utilizamos ASP.NET Core Razor Pages sobre .NET 8.
- Utilizamos SQL Server.
- Identity administra usuarios, contraseñas y roles mediante Entity Framework.
- El negocio utiliza procedimientos almacenados y Microsoft.Data.SqlClient.
- Las páginas no ejecutan SQL directamente.

El recorrido de una operación será:

Página Razor → servicio → repositorio → SQL Server.

Los resultados regresan por ese mismo recorrido.

## 2. Responsabilidad de cada componente

- Pages: recibe solicitudes, valida el formulario, llama al servicio y muestra resultados.
- ViewModels: define los campos permitidos de entrada y los datos específicos de una pantalla.
- Models: representa datos y resultados del negocio.
- Services: aplica reglas del negocio y coordina operaciones.
- Repositories: ejecuta consultas o procedimientos y transforma los resultados.
- Data: contiene ApplicationDbContext y herramientas comunes de conexión.
- database: contiene scripts SQL del negocio.

Las carpetas no conectan automáticamente las clases.
Los servicios y repositorios se registran en Program.cs.

## 3. Convenciones de nombres

- Clases, propiedades y métodos públicos: PascalCase.
- Variables y parámetros: camelCase.
- Campos privados: _camelCase.
- Los métodos asíncronos terminan en Async.
- Los nombres nuevos del negocio se escriben en español.
- Los nombres de las tablas y procedimientos existentes se conservan,
  salvo que se acuerde expresamente un cambio.

## 4. Base de datos y conexiones

- La base local de desarrollo se llama LiceoWeb_Dev.
- La conexión se identifica como DefaultConnection.
- Cada integrante configura su conexión mediante secretos de usuario.
- No se suben contraseñas ni conexiones con credenciales reales.
- Cada integrante trabaja con su propia base de desarrollo.
- Data/Migrations administra únicamente las tablas de Identity por ahora.
- database/migrations administra las tablas del negocio mediante SQL.
- Una tabla no se modifica simultáneamente mediante EF y scripts independientes.
- Los scripts se ejecutan en el orden documentado.
- Los cambios aplicados a una base compartida se registran en scripts nuevos.
- Cada cambio debe indicar quién debe ejecutarlo y qué modifica.

## 5. Tipos de datos

- Importes en C#: decimal.
- Importes en SQL: decimal(18,2).
- Los formularios aceptan como máximo dos decimales.
- No se utilizan float ni double para dinero.
- Fecha de nacimiento en SQL: date.
- Fecha de nacimiento en C#: DateOnly.
- Año, número de mes e identificadores SQL int: int en C#.
- Registro del estudiante: string.
- Identificador del comprobante: string.
- Identificador del usuario Identity: string.

Las reglas del servidor comprueban formatos, longitudes,
rangos y campos obligatorios.

## 6. Fechas y moneda

- La moneda del sistema es el córdoba nicaragüense.
- La interfaz presenta importes con dos decimales.
- La cultura de presentación es es-NI.
- Para esta primera versión, las fechas de operación del negocio se
  almacenan como hora local de Nicaragua, conservando la convención
  del sistema original.
- Los servidores deben mantener esa misma convención.
- La fecha de operación se establece en el servidor/base, no en el navegador.
- Las fechas de nacimiento no se convierten entre zonas horarias.
- Los reportes incluyen todo el día final del período.
- Los datos de fechas internos de Identity mantienen el tratamiento
  propio de Identity.

## 7. Usuarios y permisos

Los roles serán Administrador y Cajero.

Administrador:
- Puede realizar las operaciones del cajero.
- Puede editar y dar de baja estudiantes.
- Puede modificar precios.
- Puede crear arreglos de pago.
- Puede consultar reportes administrativos.
- Puede provisionar las cuentas autorizadas del personal.

Cajero:
- Puede registrar y consultar estudiantes.
- Puede matricular y registrar cobros.
- Puede consultar deudas, saldos, historial y recibos.
- Puede imprimir comprobantes.

Todas las páginas del negocio requieren una sesión.
El servidor comprueba los permisos en cada operación protegida.
Ocultar botones o enlaces no sustituye la autorización.
El usuario responsable se obtiene de la sesión, no de campos del formulario.
No se permite el registro público de cuentas.

## 8. Reglas comunes de cobro

- Los montos definitivos se consultan y validan en el servidor.
- Un precio o saldo enviado por el navegador no se considera confiable.
- Se rechazan montos negativos.
- Las transferencias requieren referencia.
- El saldo anterior utilizado no vuelve a contarse como ingreso.
- El cambio corresponde al dinero nuevo recibido.
- El saldo anterior no se devuelve como efectivo mediante el flujo normal
  de cobro; una devolución de saldo requeriría una operación separada.
- El pago y sus efectos se registran dentro de una operación transaccional.
- Si la operación falla, se revierten sus cambios.
- Cada operación recibe un identificador para impedir registros duplicados
  ante reintentos.
- Deshabilitar el botón de pago no es la única protección contra duplicados.
- El servidor/base genera el identificador único del comprobante.
- No se utilizan fecha y hora hasta el segundo como única garantía de unicidad.

## 9. Resultado común de cobro

Todos los servicios de cobro devuelven ResultadoCobro.

Sus valores significan:

- IdComprobante: comprobante registrado.
- DineroRecibido: dinero nuevo entregado en esta operación, antes del cambio.
- SaldoUtilizado: saldo anterior aplicado a la deuda.
- DeudaCancelada: importe aplicado a las obligaciones.
- CambioDevuelto: dinero nuevo devuelto al cliente.
- SaldoFinal: saldo disponible después de la operación.

El ingreso neto nuevo es:

DineroRecibido - CambioDevuelto.

La comprobación general del movimiento es:

SaldoAnterior + DineroRecibido =
DeudaCancelada + CambioDevuelto + SaldoFinal.

La clase representa el resultado; no realiza ni valida el cobro.

## 10. Errores y acceso a datos

- Los repositorios utilizan parámetros SQL.
- No se concatenan entradas del usuario en consultas.
- Se declaran tipos y tamaños de parámetros.
- Las conexiones, comandos y lectores se liberan al finalizar.
- No se mantiene una conexión SQL abierta como estado de una pantalla.
- Un error SQL no se convierte silenciosamente en cero, false o lista vacía.
- Una lista vacía significa que la consulta terminó y no encontró registros.
- Los errores de validación se muestran con mensajes claros.
- Los detalles técnicos se registran con ILogger.
- Los errores internos no se muestran completos al usuario.
- No se mezclan transacciones del servicio y del procedimiento sin definir
  cuál es responsable de controlar la operación.

## 11. Desarrollo y Git

- Cada persona trabaja en su rama: camilo, oskar, pao o har.
- Las entregas se revisan mediante pull requests hacia develop.
- main recibe versiones verificadas.
- Cada persona actualiza su rama con develop antes de integrar.
- Camilo coordina cambios en Program.cs, dependencias, diseño común y esquema.
- Cada persona registra en SQL los cambios de su módulo.
- Los cambios incompatibles se coordinan antes de integrarse.
- Un módulo se entrega con validación, permisos y pruebas de sus casos principales.

## 12. Responsables

- Camilo: configuración común, usuarios, permisos, estructura compartida,
  reportes e integración.
- Oskar: estudiantes, matrícula y precio de matrícula.
- Pao: mensualidades, vencimientos, saldos y arreglos.
- Har: mantenimiento, EvBoTa, promoción, recibos e historial de pagos.