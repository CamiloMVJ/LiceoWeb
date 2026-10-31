# Catálogo financiero y preparación de obligaciones

## Estado
Pantalla administrativa implementada: aranceles, tarifas por año/modalidad, historial de precios, correspondencias de conceptos y captura repetible de obligaciones antiguas. Todavía NO habilita cobros nuevos, recibos multiconcepto ni un estado de cuenta definitivo. Las pantallas antiguas siguen utilizando sus tablas de costos anteriores.

## Instalación
1. Actualizar revision-profesor-2026-10-29. Usar una copia respaldada de desarrollo con las migraciones anteriores e Identity.
2. Ejecutar una sola vez `database/migrations/008_CatalogoFinanciero.sql` completo en LiceoWeb_Dev.
3. Ejecutar `database/procedures/Aranceles.sql` completo en SSMS, incluidos los GO. Crea una vista y dos procedimientos; puede actualizarse con CREATE OR ALTER.
4. Compilar y ejecutar. Entrar como Administrador y abrir **Aranceles y preparación** (`/Finanzas/Aranceles`). Profesor y Cajero no están autorizados a configurar ni consultar esta pantalla.
5. No confundir la migración 008 con `verification/008_DiagnosticoFinanciero.sql`: el segundo solo consulta datos.

## Uso
1. Crear los años y modalidades en Catálogos académicos.
2. Crear los aranceles reales del colegio con código y nombre. Los importes no están en el código. No se insertan tarifas de demostración.
3. Crear una tarifa para cada arancel/año/modalidad. Admite cero y dos decimales. No hay dos tarifas para la misma combinación.
4. Para cambiar importe o estado, pulsar Editar y escribir el motivo. Se conserva importe anterior/nuevo, estado, usuario y fecha UTC. Las referencias de una tarifa no cambian: para otra modalidad o año crear otra combinación.
5. Arancel usado en tarifas o correspondencias conserva código/nombre; admite inactivación. No hay eliminación. Los cargos existentes conservan su propio importe histórico, aunque cambie la tarifa.
6. En Vincular conceptos, relacionar los cinco orígenes Matriculas, Mensualidades, Mantenimientos, EvBoTaS y Promociones con sus aranceles. No se deduce por parecido de nombres. La misma relación puede repetirse sin duplicarla; cambiar una correspondencia ya creada no se permite todavía.
7. En Preparar obligaciones, indicar motivo y capturar. Guarda una fila por origen/Id sin generar pagos ni cargos cobrables. Repetir solo incorpora registros nuevos. No sobrescribe capturas previas.
8. Revisar FuentesCambiadas y el diagnóstico 008. ORIGEN_CAMBIO/ORIGEN_AUSENTE requieren investigación antes de migrar. CAPTURADO_SIN_CONCILIAR NO equivale a aprobado.

## Qué se conserva
PreparacionObligacion guarda origen/Id, estudiante, año, modalidad, importe histórico, estado, comprobante y arancel. CargoId queda NULL: reserva la referencia única para la futura migración. No se interpreta una matrícula pagada como deuda pendiente. No se importan aún los saldos de Abonos ni se convierten pagos antiguos en ingresos nuevos.
La captura usa una transacción y lectura con HOLDLOCK; puede bloquear temporalmente cobros antiguos, por lo que se debe hacer sin actividad concurrente en desarrollo. No implementa el corte de operación. Después de la captura, cambios en las tablas antiguas se muestran como discrepancias; las consultas de seguimiento no son una instantánea transaccional completa.

## Archivos
- `008_CatalogoFinanciero.sql`: versiones de concurrencia, historial de tarifas y tablas de correspondencias/preparación.
- `Aranceles.sql`: vista de obligaciones, validación/autorización SQL, auditoría, guardado transaccional y consultas.
- `ArancelInput.cs`: campos y validaciones de importes, acciones, versión y motivos.
- `ArancelRepository.cs`: acceso parametrizado y validación antes de SQL.
- `Pages/Finanzas/Aranceles.cshtml(.cs)`: formularios y listados; cuenta tomada de la sesión, POST con antifalsificación y NoStore.
- `009_VerificarCatalogoFinanciero.sql`: cuatro escenarios con rollback: alta/edición/historial y captura repetida; tarifa duplicada; versión antigua; origen inválido.

## Verificación y límites
Dieciséis pruebas C# de entradas pasan. Solución y Razor compilan con 0 errores y 40 advertencias anteriores. Sintaxis de SQL validada con ScriptDom; no se ejecutaron procedimientos en SQL Server.
Prueba HTTP sin sesión: portada 200; /Finanzas/Aranceles y su operación Preparar redirigen al login (302); registro público 404. Falta autorización autenticada entre roles.
La prueba SQL requiere Administrador y al menos una obligación existente de prueba; no ejecutarla con cobros concurrentes. No añadir datos reales solo para satisfacer la prueba. Las identidades pueden avanzar pese al rollback.
Probar como Profesor/Cajero el acceso directo y POST; como dos administradores editar una tarifa desde dos pestañas y comprobar rechazo de la segunda; repetir captura y modificar una fuente para verificar la alerta.
Se muestran hasta 200 filas de preparación/historial; el resumen cuenta todos los registros. Falta paginación/exportación. Tarifas existentes antes de 008 no tienen un historial reconstruido: la primera modificación captura su importe anterior.

## Próximo bloque
Resolver discrepancias, aprobar conciliación, mapear modalidad/año/tarifa de cada obligación y preparar el saldo inicial. Implementar el corte que impide escrituras antiguas antes de generar cargos nuevos. Después: cobro multiconcepto idempotente, reversos y estado de cuenta. No habilitar el nuevo libro mediante inserciones manuales.
