# LiceoWeb: paso 2, estructura de desarrollo

Estos scripts se prepararon a partir de Registro_3.sql. No se han ejecutado contra SQL Server en este entorno; se revisaron como codigo. No contienen datos reales, cuentas ni contrasenas.

## Copiar
Copia la carpeta database dentro de LiceoWeb (junto a Program.cs), conservando las subcarpetas que ya existen. No coloques otra carpeta LiceoWeb dentro de tu proyecto.

## Ejecutar con SSMS
Conectate a la instancia de desarrollo: (localdb)\MSSQLLocalDB, autenticacion Windows, si esta instalada. Si utilizas otra instancia, ejecuta todos los scripts en ella y utiliza despues esa misma instancia en la conexion de la aplicacion.
1. migrations/000_CrearBaseDesarrollo.sql.
2. Selecciona LiceoWeb_Dev en el selector de base y ejecuta migrations/001_EstructuraInicial.sql completo.
3. En LiceoWeb_Dev ejecuta migrations/002_Integridad.sql completo.
4. Ejecuta seeds/001_Tarifas.sql completo.
5. Ejecuta verification/001_VerificarEtapa2.sql.
Detente si algun archivo informa un error; no ejecutes los siguientes hasta resolverlo. No ejecutes 001 otra vez sobre tablas existentes.

## Resultado esperado
15 tablas del negocio, todas con clave primaria; 15 filas de tarifas (3 modalidades por 5 conceptos); ninguna tabla de usuarios propia; tablas de estudiantes y pagos sin registros. Identity agregara despues sus tablas AspNet... mediante Update-Database. El paso 2 no conecta aun la aplicacion ni habilita cobros.

## Cambios respecto al original
- Se omite Usuarios_Sistema: Identity administrara las cuentas.
- No hay DROP TABLE, DELETE, credenciales ni procedimientos de cobro.
- Todos los importes definidos son decimal(18,2), no int.
- FechaNacimiento es date y debe suministrarse expresamente.
- Metodo_Pago admite Efectivo, Transferencia y Saldo.
- Secuencia_Estudiantes no cicla y se limita a 7 digitos para evitar truncar identificadores.
- Se agregan PK de Mensualidades y Abonos, unicidad de obligaciones por periodo y validaciones de montos/mes/ano.
- Tarifas conserva los importes del archivo original; se insertan solo modalidades que faltan y no se sobrescriben precios existentes.
- Las tablas del negocio no son administradas por ApplicationDbContext; sus migraciones se aplican como SQL. EF administra solo Identity por ahora.

## Trabajo posterior (no resuelto por este paquete)
No ejecutes los procedimientos originales esperando compatibilidad monetaria completa: sus parametros/variables int y fechas nvarchar deben adaptarse a decimal/date. Falta crear/adaptar procedimientos, numeracion unica de comprobantes (distinta de Secuencia_Estudiantes), auditoria, historial financiero y proteccion de concurrencia/reintentos. El archivo 003_ComprobantesAuditoria.sql se construira al acordar ese contrato con los responsables. En particular Pagos.Monto mantiene su nombre heredado: su significado financiero debe unificarse antes de usarlo en reportes. No se migran datos de la base antigua. No se crean alumnos/pagos ficticios en esta etapa.

## Control de versiones
Guardar estos archivos en la rama camilo y documentar el orden. Un script aplicado a una base compartida no se reescribe silenciosamente: los cambios posteriores se registran en un nuevo script numerado. El historial de scripts aplicados de cada base se debe mantener en el registro de despliegue.
