# Generar cargos

Generar un cargo deja deuda pendiente. El pago y el recibo se registran por separado en **Estado de cuenta y cobros** al recibir el dinero.

## Preparación (solo si falta la tarifa)

1. Crea o activa el concepto en **Aranceles y tarifas**.
2. En **Generar cargos → Preparación → Periodicidad**, indica si el cargo es anual, mensual o eventual.
3. Crea una tarifa activa con importe positivo para el año y la modalidad. El año y la modalidad también deben estar activos.
4. Para generar cargos, el corte financiero tiene que estar aplicado. Configurar el arancel de matrícula es necesario para vincular la matrícula académica, no para generar otros conceptos.

## Un estudiante

Elige **Un estudiante**, busca al alumno activo y selecciona la tarifa. Confirma el año y el importe. Indica el mes si es mensual, o el código si es eventual. El vencimiento es opcional y debe caer dentro del año de la tarifa. Confirma y revisa la cuenta. La opción de rango mensual sigue siendo para un estudiante con matrícula académica.

## Global por modalidad

1. Elige **Global por modalidad**, selecciona la modalidad y pulsa **Ver tarifas**.
2. Elige una tarifa y completa los datos del concepto. Para una mensualidad se genera un mes por operación.
3. Pulsa **Ver vista previa**. Revisa a quién se aplicaría, quién se omitiría, el importe por estudiante y el total.
4. Pulsa **Confirmar cargos**. Se aplican a los expedientes activos de esa modalidad, sin modificar su matrícula. El año seleccionado es el año de la obligación. Se omite a quien ya tenga el cargo, incluso si se anuló, o tenga una obligación histórica equivalente.
5. Verifica la deuda en las cuentas individuales. Si la lista, tarifa o estado de los cargos cambió tras la vista previa, el sistema pide recalcular antes de guardar. Si la confirmación se interrumpe, vuelve a generar la vista previa: los cargos existentes aparecerán omitidos.

## Instalación y verificación

En la base de la aplicación, ejecuta en orden `database/procedures/GeneracionCargos.sql` y `database/procedures/Cargos_GenerarModalidad.sql`. No hay migración de tablas. El modo global reutiliza el procedimiento de cargo individual y su auditoría, dentro de una sola transacción. Requiere la configuración financiera existente.

En una base de pruebas, prepara dos expedientes activos de la misma modalidad (uno con el cargo y otro sin él), un expediente inactivo y uno de otra modalidad. La vista previa debe incluir los dos activos de la modalidad seleccionada y omitir al que ya tiene el cargo. Al confirmar debe crearse solo un cargo y no un recibo. Después comprueba que una nueva vista previa no propone cargos nuevos. Para verificar una lista desactualizada, genera una vista previa, cambia la elegibilidad de un destinatario y confirma: el sistema debe pedir una vista previa nueva sin generar cargos.
