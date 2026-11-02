# Validación de recorridos — 2026-11-02

Base revisada: a59297b. Resultado: validación parcial; no certifica operación real.

## Ejecutado
- Los 15 proyectos C# de tests pasan (entradas, reglas aisladas y dobles de Identity).
- NavigationScroll: 10 pruebas pasan. UiNavigation: comprobaciones del menú pasan.
- La aplicación y Razor compilan durante la ejecución de los proyectos que referencian la aplicación; persisten 40 advertencias previas de nulabilidad.
- Siete procedimientos corregidos pasan el análisis sintáctico ScriptDom.
- No se ejecutaron recorridos autenticados contra SQL Server ni pruebas de concurrencia real. No hay una instancia SQL Server disponible en este entorno.

## Hallazgo y actualización necesaria
El patrón de conversión directa de rowversion a varchar, que falló en aranceles, también estaba en expedientes, notas, cierre, horarios, cambios de planificación y tarifas para generación de cargos. Se agregó conversión intermedia a binary(8), preservando el control de concurrencia. No se modificaron conversiones de variables ya declaradas binary(8).

Después de actualizar el código, ejecutar completos en SSMS, sobre la copia de desarrollo ya actualizada hasta 021:
1. database/procedures/Expediente.sql
2. database/procedures/GeneracionCargos.sql
3. database/procedures/Horario_Consultar.sql
4. database/procedures/Planificacion_CambioConsultar.sql
5. database/procedures/Notas.sql
6. database/procedures/Evaluacion_ConsultarEdicion.sql
7. database/procedures/CierreAcademico.sql

No hay migración nueva. Mantener también Aranceles_Consultar.sql de la corrección anterior. Detenerse ante un error SQL; no repetir migraciones ya instaladas.

## Pruebas de aceptación todavía pendientes
Usar una copia respaldada, cuentas de prueba Administrador/Profesor/Cajero y un estudiante ficticio. No habilitar el corte financiero sobre datos reales solo para probar.

| Recorrido | Evidencia requerida para aprobar |
| --- | --- |
| Estudiante | Alta visible en listado; edición persistida; otra pestaña con versión anterior rechazada; baja conserva historial. |
| Matrícula | Inscripción del año/modalidad/nivel correcto; segundo intento no duplica matrícula; asignación al grupo compatible. |
| Cargo y cobro | Cargo por tarifa vigente; deuda inicial exacta; pago parcial reduce saldo; pago restante deja cero; repetición de operación no duplica recibo. |
| Recibo y anulación | Detalle e impresión coinciden con importes; anulación con motivo restaura obligaciones según reglas y conserva recibo/historial; segunda anulación rechazada. |
| Planificación y notas | Docente titular ve su grupo; otro docente no accede; cruce horario rechazado; nota fuera de escala rechazada; captura, publicación y cierre coherentes. |
| Roles | Cajero sin administración de cuentas/notas; Profesor sin finanzas; usuario anónimo redirigido; baja/cambio de rol invalida sesión en siguiente solicitud. |
| Concurrencia | Dos cobros sobre el mismo saldo, dos matrículas y dos ediciones simultáneas no duplican ni sobrescriben silenciosamente. |

Registrar por caso: usuario/rol, pasos, identificadores de prueba, resultado esperado, resultado observado, captura o error completo. Una prueba C# de entrada aprobada no acredita el recorrido SQL correspondiente.
