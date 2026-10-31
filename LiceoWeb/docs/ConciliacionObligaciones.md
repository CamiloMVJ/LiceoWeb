# Revisión de obligaciones: backend de conciliación
Estado: procedimientos SQL implementados, sin ejecución de pruebas en este turno. La pantalla /Finanzas/Conciliacion está conectada a los procedimientos y es exclusiva de Administración. No genera cargos, pagos ni saldos iniciales; no activa cobros nuevos.

## Instalar en copia de desarrollo
1. Tener instalada la migración 008 y Aranceles.sql.
2. Ejecutar migrations/009_RevisionObligaciones.sql una sola vez en LiceoWeb_Dev.
3. Ejecutar procedures/Conciliacion.sql completo, incluidos GO.
4. No aplicar a producción sin ejecutar las pruebas siguientes.

## Contrato de la interfaz
Conciliacion_Revisar recibe UsuarioId de la sesión (nunca un campo libre del navegador), Origen/OrigenId de una obligación capturada, TarifaId, Decision, Motivo y RevisionAnterior.
Decision: Deuda, SinDeuda o Rechazada.
RevisionAnterior es 0 para la primera revisión; después, el Id de la última revisión conocida. Un valor antiguo se rechaza sin sobrescribir decisiones.
La tarifa debe corresponder al arancel, año y nombre de modalidad originales. El precio actual no reemplaza el importe de la deuda histórica. Se permiten referencias históricas inactivas, pues esto no genera un cargo nuevo.
Deuda exige pendiente/vencido, importe positivo y ningún comprobante. SinDeuda exige cancelación o importe cero. Una beca sin recibo requiere revisión documental y motivo; no se da por comprobada automáticamente.
Se rechaza origen ausente o modificado desde la captura. Todavía no existe una operación para recapturar diferencias con historial.
Conciliacion_Consultar devuelve 200 revisiones por página, ordenadas por Id. Enviar el último Id como DespuesDeRevision para la siguiente página. UltimaRevision distingue decisiones anteriores. COINCIDE_CON_ORIGEN no significa autorización para migrar: falta el corte y la conciliación de pagos/saldos.

## Pruebas obligatorias, aún no ejecutadas
En copia descartable y con datos de prueba:
- Administrador revisa deuda pendiente positiva con tarifa del año/modalidad correctos; se registra revisión y auditoría, no cargo ni pago.
- Repetir con RevisionAnterior=0 después del alta: error 53003; permanece una revisión.
- Revisión posterior con Id correcto: agrega historia sin borrar la anterior.
- Profesor/Cajero: error 53001.
- Tarifa de otro año, modalidad o concepto: error 53005.
- Pendiente positivo declarado SinDeuda: error 53005.
- Deuda cancelada declarada Deuda: error 53005.
- Comprobante de otro estudiante: rechazo.
- Modificar una fuente tras la captura: error 53004. Una revisión antes válida se muestra ORIGEN_CAMBIO.
- Dos revisores sobre la misma revisión: solo uno confirma.
- Verificar rollback completo si falla Registrar_Auditoria.
El procedimiento revierte toda transacción abierta al fallar; no mezclar estas pruebas con trabajo ajeno sin confirmar en SSMS.

## Continuar
Implementar recaptura de discrepancias con historial y conciliación de Abonos/pagos; después corte de escrituras anteriores, cargos, recibos multiconcepto y estado de cuenta. No se deben interpretar estas revisiones como una migración completada.

## Instalar la pantalla
Con 008 y 009 instaladas, volver a ejecutar procedures/Conciliacion.sql completo: añade Conciliacion_Pantalla sin cambiar tablas. Actualizar código y compilar. En el menú administrativo aparece Conciliación de obligaciones.
1. Capturar obligaciones desde Aranceles y preparación.
2. Buscar por código exacto de estudiante o recorrer las páginas de 50 filas.
3. Abrir Revisar, escoger tarifa compatible, decisión y motivo.
4. Guardar y comprobar historial. Ante conflicto recargar; no se actualiza silenciosamente el identificador de revisión enviado.
Las fuentes cambiadas o ausentes requieren resolución posterior; la pantalla no permite recapturarlas automáticamente.
Los Id del listado son las referencias originales de cada tabla, no números de recibo.
Pruebas pendientes de esta continuación: compilación de Razor/C#, autorización GET/POST como Cajero y Profesor, paginación, filtros, alta de decisión, dos pestañas con revisión antigua y fuentes modificadas. No se ejecutaron estas pruebas ni SQL Server en este turno. No dar esta etapa por validada en producción.
