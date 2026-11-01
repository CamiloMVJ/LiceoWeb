# Actualizar la base desde la etapa 015

Este instalador resuelve la ausencia de Cargos_ConfigurarMatricula, Mensualidades_GenerarLote y ReporteFinanciero_Consultar. Los archivos ya existían en el repositorio: actualizar Git no los ejecuta en SQL Server.

1. Detener el sistema y respaldar LiceoWeb_Dev. Guardar los cambios locales de Git.
2. `git fetch origin --prune`, `git switch revision-profesor-2026-10-29` y `git pull --ff-only origin revision-profesor-2026-10-29`. Si hay divergencia o cambios locales, resolverlos antes; no usar reset --hard.
3. Abrir en SSMS `database/install/ActualizarDesde015.sql`. Activar **Consulta > Modo SQLCMD**. Ejecutar el archivo completo, sin seleccionar un fragmento.
4. Ajustar `DatabaseRoot` al directorio database de este mismo clon actualizado. Por defecto está configurado para la ruta compartida por Camilo.
5. Ejecutar con permisos de modificación de esquema en la instancia que usa la aplicación. El script selecciona explícitamente LiceoWeb_Dev, verifica requisitos, instala 016/017 solo si faltan y actualiza GeneracionCargos, LoteMensualidades, Planificacion y ReporteFinanciero en ese orden. Conserva el esquema y los datos existentes; no repite las etapas 001–015, semillas o conciliaciones y no aplica el corte.
6. Revisar todos los resultados: los seis procedimientos y tres tablas deben decir INSTALADO; ambos parámetros ACTUALIZADO. Si aparece un error, no reiniciar todavía la aplicación. SQLCMD detiene el archivo; si SSMS conserva una transacción abierta, ejecutar `IF @@TRANCOUNT > 0 ROLLBACK;` en esa misma conexión antes de corregir/reintentar. 016/017 ya completadas se conservan y se omiten al reintentar. Una instalación parcial anterior se debe revisar, no borrar tablas.
7. `dotnet build .\LiceoWeb\LiceoWeb.csproj`; iniciar y recargar con Ctrl+F5. Identity y secretos existentes se conservan.
8. Como Administrador: abrir Generar cargos y Cobros y devoluciones. La configuración de matrícula debe aparecer; la generación por rango requiere una matrícula académica compatible. El reporte y los cobros nuevos requieren corte aplicado; si el verificador dice que no está aplicado, seguir docs/CorteFinanciero.md primero, sin aplicarlo automáticamente por este diagnóstico.
9. Probar CSV con rango vacío, cobro, devolución, más de 100 filas, tildes y nombres con comas. Comparar importes con el reporte sin actividad concurrente. Cajero/Profesor no deben poder descargarlo.

El verificador también puede ejecutarse por separado en SSMS normal sobre la base correcta. Comprueba presencia y parámetros concretos, no demuestra que todas las migraciones se hayan ejecutado ni valida cifras. No hay conexión desde este entorno de desarrollo a la base local del usuario.

Validación disponible: análisis sintáctico SQL y compilación de la aplicación. Ejecución real del instalador, SQL Server y pruebas con usuarios autenticados siguen pendientes.
