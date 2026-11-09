# Instalación nueva lista para presentar

Este instalador reemplaza las instrucciones antiguas de SQLCMD, cuentas manuales y corte separado.

1. Actualizar la rama ajustes-verificacion-vistas.
2. Abrir database/InstalacionInicialCompleta.sql en SSMS.
3. Ejecutar el archivo completo con **F5 en SSMS normal**. No necesita modo SQLCMD.
4. Esperar **INSTALACIÓN COMPLETA**, con Migrado = 1.
5. Iniciar la aplicación conectada a esa misma instancia y base (ConnectionStrings:DefaultConnection).

El nombre predeterminado es **LiceoWeb_Dev**, igual al de appsettings.json. La instancia predeterminada de la aplicación es LocalDB. Si instalas en SQL Express u otra instancia, configura esa conexión en los secretos locales: SQL no puede cambiar la configuración de tu equipo ni los secretos de Visual Studio.

Si la base ya existe, el script se detiene sin modificarla. Para otra instalación cambia **@Base** al principio por un nombre nuevo y actualiza DefaultConnection. No es un actualizador de bases existentes y no elimina la base anterior.

## Acceso inmediato

| Correo | Contraseña de demostración | Rol |
| --- | --- | --- |
| camilo@liceo.test | Admin1234# | Administrador |
| profesor@liceo.test | Admin1234# | Profesor |
| cajero@liceo.test | Admin1234# | Cajero |

Credenciales públicas para demostración; no usarlas en producción. Se almacenan hashes PasswordHasher V3, no contraseñas en las tablas. No hay que ejecutar --crear-cuentas ni Update-Database.

## Qué queda preparado

- Migraciones SQL 001–025, Identity e historial de su migración EF.
- 47 procedimientos vigentes en orden de dependencia.
- Tres cuentas activas con correo confirmado y rol.
- Primer corte de caja abierto y controles de apertura/cierre exclusivos de Administración.
- Esquema financiero web activo desde la instalación, sin traslado de datos del escritorio.
- Año actual, período abierto, Preescolar / Primaria / Secundaria, aulas, materias y tres grupos.
- 12 expedientes ficticios: cuatro por modalidad; nueve inscritos y tres listos para inscribir.
- Arancel oficial de matrícula correcto y matrícula pagada para los 12 estudiantes.
- Mensualidades del mes actual: ejemplos pagados, parciales y pendientes.
- Tres anticipos de C$ 150 para mostrar el saldo a favor.
- Horarios sin cruces del profesor, con distintos días según el grupo.
- Dos evaluaciones de 50 % por clase; algunas notas guardadas y otras pendientes.

No se simulan fotografías institucionales, archivos adjuntos ni datos de personas reales.

## Recorrido de presentación

Administrador: abrir Organización académica, elegir año, plan y grupo; mostrar horarios; inscribir al cuarto alumno. Los nombres empiezan por Demo.

Profesor: entrar a Calificaciones, elegir clase y evaluación; completar resultados. No publicar hasta terminar las inscripciones de la presentación.

Cajero: abrir Cobrar a estudiante; buscar un alumno Demo; mostrar deuda, pagos y recibos; registrar un anticipo o aplicar saldo a la mensualidad. No ejecutar el corte de nuevo.

## Mantenimiento

Las migraciones y procedimientos siguen siendo las fuentes del esquema. Regenerar y probar con:

    python LiceoWeb/database/tools/generar_instalador.py
    python LiceoWeb/database/tools/test_instalador.py
    dotnet run --project tests/InstaladorDemoValidation

IdentityInicial.sql es una fuente auxiliar generada por EF desde CreateIdentitySchema, no otro archivo que deba ejecutar el usuario. El script final contiene todos los lotes sin archivos externos. No incluye el archivo obsoleto Procedimientos.sql de Registro_Pagos; las tres rutinas mensuales reemplazadas provienen de Mensualidades_Legado.sql.

Las pruebas estáticas revisan estructura, dependencias y contraseñas; no sustituyen ejecutar SQL Server. Si una etapa falla, se detiene toda la instalación y se muestra su nombre y el error original. No continuar creando objetos aislados sobre una instalación parcial.

## Recuperar el error 52408 de la primera versión del instalador demo

Si el instalador anterior terminó en Demostración, lote 3, con el error 52408, no es necesario borrar la base ni volver a cobrar o crear los estudiantes. Actualiza la rama y ejecuta completo **database/seeds/003_CalificacionesDemostracion.sql** sobre esa misma base. El archivo comprueba que estén las cuentas y clases demo, crea solo evaluaciones faltantes y no reemplaza notas ya guardadas. Al finalizar muestra DEMOSTRACIÓN COMPLETADA. Para nuevas bases, el instalador completo ya incluye esta corrección.

## Actualización desde 024

Ejecutar únicamente migrations/025_RetirarConciliacionesLegadas.sql con la aplicación detenida; incluye los procedimientos afectados. Ver RetiroConciliaciones.md.
