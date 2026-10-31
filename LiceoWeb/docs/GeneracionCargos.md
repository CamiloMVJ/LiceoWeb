# Generación de cargos desde tarifas

Nueva pantalla `/Finanzas/Cargos`, exclusiva de Administración. El cajero conserva acceso al cobro y al estado de cuenta, pero no puede crear deuda. No hay generación masiva ni automática al matricular en esta etapa.

## Instalar y probar
1. Actualiza `revision-profesor-2026-10-29` después de guardar tus cambios locales.
2. En una copia de `LiceoWeb_Dev`, completa las migraciones anteriores hasta 013 y sus procedimientos. No repitas migraciones instaladas.
3. Ejecuta `database/migrations/014_GeneracionCargos.sql` una vez.
4. Ejecuta todo `database/procedures/GeneracionCargos.sql` (con los GO). Es reinstalable.
5. Abre **Administración → Generar cargos**. Puedes revisar la configuración antes del corte. Para generar deuda, el corte 012 debe estar aplicado y validado en esa copia; consulta `CorteFinanciero.md`.
6. En **Periodicidad de los aranceles**, configura los conceptos que aún no tienen periodicidad. Los mapeados desde mensualidades se inicializan como mensuales; los otros conceptos históricos como anuales, únicamente si todos los mapeos del arancel coinciden. Mapeos contradictorios bloquean la configuración: requieren revisión, no se adivina una frecuencia.
7. Busca el estudiante por código. Debe estar activo. La tarifa debe estar activa, ser positiva, pertenecer a un año activo y coincidir con la modalidad del estudiante. Configura las tarifas faltantes en **Aranceles y preparación**.
8. Selecciona la tarifa en la tabla. Revisa concepto, año e importe antes de confirmar.
9. Según periodicidad: anual no requiere período adicional; mensual requiere mes 1–12; eventual requiere un código de evento de hasta 30 caracteres, con letras, números, guion o guion bajo. Usa siempre el mismo código para el mismo evento (ejemplo `EXCURSION_01`). Códigos distintos representan obligaciones distintas.
10. Indica opcionalmente vencimiento dentro del año de la tarifa. Una fecha vacía permanece desconocida; no se inventa mora.
11. Confirma. El nuevo cargo aparece en **Estado de cuenta y cobros** y puede pagarse parcial o totalmente con el módulo 013.
12. Ejecuta `database/verification/013_VerificarGeneracionCargos.sql` después de probar.

## Qué garantiza
- El navegador no decide el precio: se toma de TarifaArancel en la transacción.
- Se conserva una instantánea del concepto, período, importe y vencimiento. Modificar una tarifa posteriormente no cambia deudas generadas.
- Una tarifa modificada desde que abriste el formulario exige volver a consultar. No se cobra silenciosamente otro precio.
- El GUID del formulario permite reintentar la misma solicitud sin crear otro cargo. Reutilizarlo con otros datos se rechaza. El GUID se conserva tras errores.
- Para nuevas obligaciones, se evita repetir estudiante + arancel + año + período/evento, incluso si cambió la modalidad o el cargo fue anulado. Anulaciones/reemisiones todavía no están implementadas.
- Se revisan también obligaciones migradas, incluidas las ya pagadas que no generaron cargo durante el corte. Los meses existentes no se vuelven a facturar. Ante un origen histórico ambiguo, se bloquea la generación para revisarlo.
- La configuración de periodicidad es fija en esta etapa. Cambiarla requiere una futura operación con análisis del historial; no editarla manualmente.
- El cargo, identificador de reintento y auditoría se guardan en una sola transacción. La numeración de recibos no cambia al crear deuda.

## Archivos
| Archivo | Responsabilidad |
|---|---|
| `014_GeneracionCargos.sql` | Configuración de periodicidad y registro de operaciones de generación |
| `GeneracionCargos.sql` | Permisos, configuración, consulta, precio desde tarifa, duplicados, historial y transacción |
| `Cargos.cshtml.cs` | Parámetros tipados, validación de entrada, identidad de sesión y conservación del GUID |
| `Cargos.cshtml` | Selección de estudiante/tarifa y formulario sin JavaScript de negocio |
| `Cuenta.cshtml` / `_NavigationPartial.cshtml` | Enlaces para Administración |
| `tests/GeneracionCargosValidation` | Pruebas de entrada en C#, sin base de datos |
| `013_VerificarGeneracionCargos.sql` | Comprobación de auditoría e inexistencia de períodos duplicados |

## Pruebas integradas pendientes en SQL Server
En una copia de desarrollo con el corte aplicado:
- Generar cargo anual, mensual y eventual; comprobar importe y cuenta del estudiante.
- Reenviar la misma operación: mismo CargoId, una fila y una auditoría.
- Enviar dos operaciones distintas para el mismo período a la vez: una debe rechazarse.
- Cambiar importe de tarifa después de abrir el formulario: debe rechazarse; al reabrir muestra el nuevo importe. El cargo anterior no cambia.
- Intentar generar el mismo período histórico cancelado o pendiente: debe rechazarse.
- Probar cambio de modalidad: no permite duplicar el mismo arancel/año/período ya generado.
- Probar estudiante inactivo, modalidad incompatible, tarifa inactiva/cero, vencimiento de otro año, mes fuera de rango y evento inválido: rechazo sin escrituras.
- Forzar fallo de auditoría en copia: ninguna escritura parcial. El procedimiento no admite transacción externa para pruebas.
- Acceso directo y POST como Cajero/Profesor: denegados; Administrador permitido.

## Continuar más tarde
Siguiente bloque: anulaciones de recibos con contrapartida y devolución documentada, retirada de formularios antiguos tras el corte e impresión dedicada. Falta ejecutar pruebas financieras integradas y conectarlas al flujo de matrícula definitivo. No usar la generación manual como sustituto de una matrícula académica: crear una deuda no inscribe al estudiante en un grupo.

## Verificación realizada
Compilación C#/Razor completada al ejecutar las pruebas; 13 validaciones aprobadas. Los tres scripts pasan el análisis sintáctico de ScriptDom. Inicio público responde 200 y acceso anónimo a Cargos/Cuenta redirige a login. No se ejecutó ningún procedimiento contra SQL Server ni se probó acceso con sesiones reales; esas pruebas siguen pendientes.
