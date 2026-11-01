# Mejora de interfaces con UI/UX Pro Max

Rama independiente: `mejora-ui-ux-2026-11-01`, basada en `revision-profesor-2026-10-29` (20d334f). No se modifica la rama de origen ni el esquema de la base.

## Cambios
- Sistema visual compartido para formularios, tablas, tarjetas, avisos y botones administrativos.
- Mejor jerarquía, legibilidad, campos y zonas táctiles; foco de teclado y enlace para saltar al contenido.
- Menú adaptable a móvil con control explícito, Escape y funcionamiento básico sin JavaScript.
- Inicio del sistema con accesos según rol, sin estadísticas simuladas.
- Selección visible del apartado activo en Planificación.
- Colores institucionales preservados, tipografía local y movimiento reducido.

Se utilizó https://github.com/nextlevelbuilder/ui-ux-pro-max-skill como guía de diseño. Las decisiones adaptadas y consultas están documentadas en `design-system/liceo-hispanidad/MASTER.md`. No se agrega una instalación global de la skill ni dependencias de frontend.

## Probar
Con cambios locales guardados:

```powershell
git fetch origin
git switch mejora-ui-ux-2026-11-01
dotnet build .\LiceoWeb\LiceoWeb.csproj
```

Ejecutar normalmente y recargar con Ctrl+F5. Mantener la misma base y secretos usados en la rama de origen. No ejecutar migraciones adicionales por este cambio visual; si la base aún no estaba actualizada, completar las etapas funcionales de la rama de origen.

Revisar con Administrador, Cajero y Profesor: menú por rol, formularios, tablas anchas, validaciones, modales, cargos, notas y recibos. Verificar móvil, zoom 200%, teclado y mensajes largos. La impresión conserva su documento y CSS independiente.

## Verificación realizada
- Compilación .NET/Razor sin errores; permanecen advertencias previas del proyecto.
- Pruebas Node: apertura/cierre móvil, Escape y devolución de foco, cambio a escritorio; 10 pruebas previas de conservación de desplazamiento.
- Contraste calculado: azul/blanco 14.62:1; texto secundario/blanco 6.29:1; texto/fondo 11.4:1; azul/dorado 5.51:1. No constituye auditoría completa de todos los componentes.
- HTTP de portada/login y recursos visuales comprobados sin base de datos.
- Revisión visual con capturas no completada: Chromium no estaba instalado y la descarga del navegador falló en el entorno. No se probaron pantallas autenticadas con SQL Server. Revisar antes de integrar la rama.
