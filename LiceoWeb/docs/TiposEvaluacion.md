# Administración de tipos de evaluación

Desde Calificaciones → Administrar tipos de evaluación, el Administrador puede consultar todos los tipos, editar nombres sin uso, inactivar, reactivar y consultar el historial de cambios (25 por página). Crear tipo conserva el formulario existente.

## Comportamiento
- Un tipo utilizado por cualquier evaluación conserva su nombre, incluso si aún no hay notas. Para una categoría diferente, crear otro tipo.
- Inactivar no borra evaluaciones, resultados, publicaciones ni relaciones. Las nuevas evaluaciones solo admiten tipos activos, como ya validaba Notas_Guardar.
- La edición de una definición de evaluación también exige un tipo activo: si su tipo está inactivo, seleccionar otro activo o reactivarlo antes de editar. Capturar notas y consultar resultados existentes no exige que el tipo siga activo.
- Guardar requiere motivo de 10–500 caracteres, versión de 8 bytes y operación única. Un formulario antiguo no sobrescribe cambios. Recargar tipo descarta las entradas del formulario.
- Repetir exactamente la misma operación no duplica historial/auditoría. Reutilizarla con otros datos se rechaza.
- Los cambios toman Liceo.Personal y después Liceo.Planificacion, coordinándose con administración de cuentas y creación/edición de evaluaciones.
- Historial desde la instalación; no reconstruye cambios anteriores ni registra retroactivamente las altas antiguas. Fechas mostradas en UTC.
- Autorización en página y procedimientos: Administrador activo. No concede permisos a Profesor o Cajero.

## Instalación manual en una copia de desarrollo
1. Respaldar la base y actualizar la rama revision-profesor-2026-10-29.
2. Con 021 ya instalada, ejecutar una vez database/migrations/022_TiposEvaluacion.sql en LiceoWeb_Dev. Si informa instalación completa/parcial, revisar antes de repetir.
3. Ejecutar completos database/procedures/TipoEvaluacion_Consultar.sql y database/procedures/TipoEvaluacion_Guardar.sql.
4. Compilar y reiniciar la aplicación actualizada. No necesita otra migración Identity ni reinstalar las migraciones anteriores.
5. Ejecutar database/verification/023_VerificarTiposEvaluacion.sql en la copia de desarrollo. Comprueba renombrado sin uso, reintento, inactivación, reactivación y conteo del historial; revierte los datos. Identidades y rowversion pueden avanzar.

## Verificación pendiente de ejecución
En esta entrega se revisó el código, pero no fue posible ejecutar terminal, compilador ni SQL Server. No se afirma que las pruebas siguientes hayan pasado.

```powershell
dotnet build LiceoWeb.sln -warnaserror
dotnet run --project tests/TiposEvaluacionValidation
dotnet run --project tests/NotasValidation
dotnet run --project tests/EditarEvaluacionValidation
```

Prueba autenticada:
1. Administrador: crear un tipo, abrirlo, renombrarlo sin uso y verificar historial.
2. Crear una evaluación con ese tipo. Intentar renombrarlo mediante POST manipulado: SQL debe rechazarlo, sin cambios ni historial nuevo.
3. Inactivarlo: no debe aparecer al crear otra evaluación; enviar su Id manualmente también debe fallar. Calificar la evaluación existente debe seguir funcionando dentro de las restricciones de período/publicación.
4. Reactivarlo: vuelve a estar disponible.
5. Dos pestañas: guardar en una y luego en la otra; la segunda muestra conflicto sin sobrescribir.
6. Reenviar la misma operación: no duplica historial. Cambiar su contenido conservando operación: rechazo.
7. Profesor y Cajero: GET y POST directos a /Notas/Tipos denegados. Cuenta desactivada: sin acceso.
8. Nombre duplicado, motivo vacío, versión manipulada y operación vacía: rechazo sin escrituras.
9. Provocar un fallo de auditoría únicamente en una base desechable: ni tipo ni historial deben quedar modificados.
10. Con dos sesiones SQL, competir inactivación contra creación/edición de evaluación: la escritura debe serializarse bajo Liceo.Planificacion, sin aceptar un tipo que ya estuviera inactivo al validar.
11. Revisar diseño en móvil, teclado, mensajes y paginación con más de 25 cambios.

No se modifica la normalización del expediente ni el esquema financiero. El siguiente pendiente general sigue siendo la validación integrada de SQL Server, sesiones, concurrencia y recorrido visual.
