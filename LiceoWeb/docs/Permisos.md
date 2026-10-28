# Permisos de LiceoWeb

## Roles

- Administrador
- Cajero

Los nombres deben utilizarse exactamente así en el código
y al asignar roles mediante Identity.

## Políticas

OperarSistema:
- Requiere una sesión.
- Requiere el rol Administrador o Cajero.

SoloAdministrador:
- Requiere una sesión.
- Requiere el rol Administrador.

## Distribución de acceso

| Función | Administrador | Cajero |
|---------|-----------|---| ------ |
| Inicio del sistema | Sí | Sí |
| Registrar estudiantes | Sí | Sí |
| Consultar estudiantes | Sí | Sí |
| Editar estudiantes | Sí | No |
| Dar de baja estudiantes | Sí | No |
| Matricular | Sí | Sí |
| Registrar cobros | Sí | Sí |
| Consultar deudas y saldos | Sí | Sí |
| Consultar e imprimir recibos | Sí | Sí |
| Modificar precios | Sí | No |
| Crear y consultar arreglos | Sí | No |
| Consultar reportes administrativos | Sí | No |

## Rutas administrativas

- /Precios y sus páginas.
- /Arreglos y sus páginas.
- /Reportes y sus páginas.
- /Estudiantes/Editar.
- /Estudiantes/DarBaja.

Si cambia el nombre de una página, debe actualizarse su protección.

## Reglas de implementación

- Ocultar enlaces no reemplaza la autorización en el servidor.
- Las páginas del negocio requieren un rol autorizado.
- Las páginas de acceso de Identity deben permitir iniciar sesión.
- No se permite seleccionar un rol desde un formulario público.
- El usuario responsable de una operación se obtiene de la sesión.
- Las cuentas y asignaciones de roles se provisionan en el paso 6.
- Nuevas APIs o endpoints necesitan su propia autorización:
  las convenciones de Razor Pages no los protegen automáticamente.

## Pruebas pendientes con cuentas

- Administrador puede operar y entrar a funciones administrativas.
- Cajero puede operar, pero no entra a funciones administrativas.
- Un usuario autenticado sin rol no puede operar.
- Un visitante sin sesión es enviado al inicio de sesión.