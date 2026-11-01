# Posición al navegar y configuración de matrícula

## Actualización
Actualizar la rama, detener la aplicación, reinstalar `database/procedures/GeneracionCargos.sql` completo y compilar/reiniciar. No hay migración nueva; requiere las anteriores hasta 017. Si el navegador conserva recursos anteriores, recargar con Ctrl+F5 una vez.

## Navegación
`wwwroot/js/site.js` conserva coordenadas de ventana, panel principal y barra lateral al seguir enlaces internos dentro del sistema. Utiliza sessionStorage por pestaña y consume la posición solo si coincide con el destino inmediatamente siguiente. No cambia la navegación atrás/adelante, anclas, enlaces externos, nuevas pestañas ni autenticación. Si la página destino es más corta, el navegador limita la posición al final disponible. No cambia los envíos de formularios ni desplaza automáticamente hacia abajo los errores de validación.

La posición se guarda durante un máximo de 30 segundos; si el usuario empieza a desplazarse antes de terminar la carga, no se vuelve a imponer la posición guardada. No almacena datos de estudiantes ni financieros. Si sessionStorage está bloqueado, la navegación continúa normalmente.

Prueba manual pendiente: desplazarse abajo en Estudiantes, usar enlaces del menú, alternar los apartados de Planificación, volver atrás, abrir otra pestaña y comprobar páginas cortas. Los tests Node simulan eventos/almacenamiento; no sustituyen revisión visual en navegador real.

## Arancel de matrícula desde la web
En **Generar cargos → Arancel de matrícula académica**, Administración puede elegir por primera vez un arancel activo de periodicidad Anual. Primero crear arancel y tarifa en Aranceles; definir periodicidad en Generar cargos. La selección queda auditada en una transacción y no crea cargos, pagos ni matrículas.

Si ya se configuró desde la migración 016 o por SQL, se muestra el nombre existente. No se sustituye desde esta pantalla: cambiar el concepto requiere revisar el historial. Repetir la misma selección no duplica la configuración; una selección distinta cuando ya existe se rechaza, incluso ante envíos simultáneos. No hace falta modificar el mapeo del libro anterior ni reabrir el corte.

Se actualiza `Cargos_Pantalla` para devolver un quinto conjunto de resultados y se agrega `Cargos_ConfigurarMatricula` en GeneracionCargos.sql. Actualizar procedimiento y aplicación juntos. La autorización administrativa se valida en Razor y SQL; los formularios conservan protección antifalsificación.

Pruebas SQL pendientes: configuración vacía, arancel mensual/inactivo, mismo arancel reenviado, dos administradores intentando elegir aranceles distintos, fallo de auditoría con rollback y acceso como Cajero/Profesor. No ejecutadas en SQL Server aquí.

Siguiente trabajo pendiente: pruebas integradas financieras y matrícula; bajas/traslados académicos con historial; edición de evaluaciones y cuentas; reportes consolidados. No considerar completos esos módulos por esta actualización.

Validación realizada: compilación .NET/Razor sin errores (40 advertencias previas), 10 pruebas Node aprobadas y análisis sintáctico del procedimiento con ScriptDom sin errores. No se ejecutó SQL Server ni revisión visual autenticada.
