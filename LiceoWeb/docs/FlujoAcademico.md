> Actualización 025: se retiró el traslado del escritorio y sus conciliaciones. Las referencias a ese flujo en el historial de este documento ya no se aplican. Consultar [RetiroConciliaciones.md](RetiroConciliaciones.md).

# Organización académica y calificaciones

## Qué cambió y por qué

Antes se navegaba entre catálogos, planificación y notas con selectores globales y tablas técnicas. Las dependencias no eran visibles, y después de guardar se perdían el año, plan y grupo en los que se trabajaba.

Ahora **Organización académica** es el punto de preparación. Conserva el contexto en la URL y en los formularios; muestra solo opciones relacionadas y permite crear catálogos dentro del mismo espacio. Los enlaces antiguos de Catálogos académicos llevan al paso de preparación. Calificaciones sigue siendo una pantalla de trabajo separada para los docentes, conectada directamente con la clase y con un enlace de vuelta al grupo para el administrador.

No hay cambios de tablas ni migración nueva. Se conservan permisos, auditoría, control de concurrencia de notas, matrículas, cruces de horario, cierres y publicaciones. Las consultas históricas mantienen sus accesos. Los datos de demostración usados en las pruebas no se insertan en el proyecto ni en la base.

## Actualización desde la rama anterior

1. Detener la aplicación. Guardar los cambios locales antes de cambiar o actualizar la rama.
2. Desde la raíz del repositorio:

   ```powershell
   git fetch origin
   git switch ajustes-verificacion-vistas
   git pull --ff-only origin ajustes-verificacion-vistas
   ```

3. En **SSMS**, seleccionar la base que usa `ConnectionStrings:DefaultConnection`. Ejecutar completos, incluyendo todos sus `GO`, estos dos archivos de la rama actual:
   - `LiceoWeb/database/procedures/Planificacion.sql`
   - `LiceoWeb/database/procedures/Notas.sql`
4. Recompilar y reiniciar la aplicación. No ejecutar migraciones antiguas ni recrear la base para este cambio.

Estos archivos actualizan cinco procedimientos con `CREATE OR ALTER`. Los tres procedimientos de escritura ahora devuelven un parámetro opcional `@ResultadoId OUTPUT`, que permite abrir el registro que acaba de guardarse sin buscar por `MAX(Id)`. Los procedimientos de consulta agregan los identificadores de relación y el nombre del estudiante necesarios para el nuevo flujo. Los llamadores SQL anteriores pueden omitir el parámetro opcional. Actualizar los scripts **antes** de usar el código nuevo.

Si la base todavía devuelve el contrato anterior, las pantallas muestran un mensaje de instalación pendiente en lugar de intentar dibujar columnas inexistentes.

## Recorrido del administrador

### 1. Preparar año

- Crear el año lectivo; queda seleccionado al guardar.
- Abrir Períodos, seleccionar ese año y registrar nombre, inicio y fin.
- Revisar modalidades: `Preescolar`, `Primaria` y `Secundaria`, según la oferta real del colegio.
- Los turnos, aulas y asignaturas son reutilizables. Crear solo los que falten; también pueden agregarse desde el paso que los necesita.
- El listado permite editar e inactivar conservando las restricciones históricas. Inactivos y períodos cerrados no se ofrecen para nuevas selecciones.

### 2. Plan de estudios

- Elegir el año arriba, seleccionar la modalidad y luego uno de sus grados.
- Solo aparecen modalidades escolares activas y sus grados correspondientes. El servidor rechaza combinaciones incompatibles.
- Guardar y continuar selecciona el plan recién creado y abre sus materias.
- Si el plan ya existe, elegirlo en el selector superior y continuar. No crear otro para cada sección.

### 3. Materias del plan

- Agregar cada asignatura que cursará ese grado.
- «Agregar asignatura aquí» permite crear la que falte y regresar al mismo contexto.
- «Guardar y agregar otro» mantiene este paso; «Guardar y continuar» abre la creación de grupos.
- Solo aparecen asignaturas activas que todavía no están incluidas.
- Completar el plan antes de crear el primer grupo. Después conserva su composición histórica, como ocurría anteriormente.

### 4. Crear grupos

- El plan ya está seleccionado. Elegir período de ese mismo año, turno y aula. La base asigna un nombre automático (Grupo 1, Grupo 2, etc.) dentro del plan y período, y conserva los nombres de los grupos existentes.
- Si falta período, turno o aula, crearlo desde los accesos del paso.
- Guardar selecciona el grupo nuevo. Se pueden crear varias secciones del mismo plan.
- Para trabajar en un grupo existente, elegirlo arriba o usar «Organizar» en el listado.

### 5. Asignar docentes

- Elegir una materia pendiente del plan y una cuenta habilitada con rol Profesor.
- Guardar y repetir hasta cubrir las materias.
- La cuenta del profesor se crea desde Cuentas del personal: sigue siendo una tarea exclusiva del administrador, no un registro público.
- Una asignación existente se modifica con «Cambiar docente», conservando motivo e historial. Una asignación con docente inactivo no se duplica; se corrige por ese mecanismo.

### 6. Organizar horarios

- El tablero muestra lunes a domingo con los bloques reales de ese grupo y los espacios libres entre clases. Cada día admite su propio número de clases y duraciones.
- Pulsa «Agregar bloque» en el día correspondiente y elige la clase y las horas. El sistema comprueba cruces de grupo, aula y docente.
- «Reprogramar» permite cambiar el día y las horas de un bloque. Indica un motivo. El bloque anterior solo se cancela si el nuevo se puede guardar; ambas operaciones se registran y el original sigue en el historial.
- «Cancelar bloque» abre la confirmación existente. El docente puede consultar su semana por período en **Mi horario**.
- Para instalar la reprogramación, la base debe tener la etapa 018 de cancelación y el procedimiento `Horario_Cancelar.sql`, además de la versión actual de `Planificacion.sql`.

### 7. Inscribir estudiantes

- El grupo ya está seleccionado. Buscar por nombre, elegir el estudiante y guardar.
- Se conserva el requisito existente de respaldo de matrícula del año, modalidad y grado. Después del corte financiero debe existir el cargo anual correspondiente, salvo matrícula histórica reconocida; no se exige que el cargo esté pagado.
- La capacidad, la inscripción duplicada y los bloqueos por publicación continúan comprobándose en SQL.
- Las operaciones financieras no se ejecutan automáticamente al avanzar de paso.

### 8. Ir a calificaciones

- Revisar los conteos de materias, docentes, horarios y estudiantes del grupo.
- Abrir «Calificaciones» en la materia correspondiente. El sistema conserva la clase elegida.
- Los conteos son orientación, no certifican que el grupo esté completo. Una clase puede abrirse para preparar evaluaciones antes de tener todos los estudiantes.

## Recorrido para calificar

1. **Preparar evaluaciones:** elegir la clase si no se llegó desde el grupo; registrar nombre, tipo, fecha y modalidad. Los campos numéricos y cualitativos se muestran según la modalidad. Si falta un tipo, el administrador puede crearlo aquí antes de completar el formulario; el profesor utiliza los tipos disponibles.
2. **Registrar resultados:** crear la evaluación abre directamente su lista. Elegir un estudiante y registrar su resultado. «Guardar y siguiente pendiente» abre otro pendiente de la misma evaluación. Un valor vacío sigue siendo pendiente; cero sí es una calificación. Cambiar una nota existente sigue exigiendo motivo y versión.
3. **Revisar y publicar:** consultar estudiantes, evaluaciones, pendientes y peso configurado. El botón se habilita cuando hay estudiantes y evaluaciones, no faltan resultados y, si hay evaluaciones numéricas, suman 100 %. SQL vuelve a verificarlo al guardar. Publicar sigue bloqueando la edición; el procedimiento de cierre/reapertura no cambia.

El administrador puede volver desde la clase al mismo grupo. El profesor conserva acceso únicamente a sus asignaciones. Editar tipos conserva también el enlace de vuelta a la clase.

## Detalles de navegación

- Cambiar año limpia plan/grupo incompatibles; cambiar plan limpia grupo. Sin JavaScript se puede usar «Aplicar selección».
- Guardar es explícito: cambiar de contexto o abrir un catálogo no guarda un formulario en curso. Crear primero la opción que falte y luego completar el formulario principal.
- «Continuar» solo navega; no guarda ni declara completo un paso.
- Se puede regresar a pasos anteriores sin repetir datos ya registrados.
- Las listas de mantenimiento muestran inactivos para poder reactivarlos; los selectores de nuevas operaciones los excluyen.

## Validación realizada y límites

- Compilación de la solución con advertencias como errores.
- Pruebas existentes de planificación, notas, cambios académicos, cancelación de horario, edición de evaluaciones, cierre y tipos.
- `tests/FlujoAcademico`: 14 escenarios de filtrado y conservación/limpieza del contexto, incluida base vacía e inactivos.
- `tests/FlujoAcademicoForms`: validación MVC de los formularios independientes y condiciones para ofrecer la publicación.
- `tests/FlujoAcademicoJs/test.cjs`: limpieza de selectores dependientes y campos según modalidad de evaluación.
- Renderizado Razor de los ocho pasos, los seis catálogos y las tres etapas de calificaciones con datos sintéticos, comprobando formularios no anidados y tokens antifalsificación.
- Análisis sintáctico de los dos archivos SQL con ScriptDom.

No se ejecutaron escrituras contra un SQL Server real. La prueba visual en Chromium no pudo ejecutarse por restricciones del entorno; el renderizado HTML no equivale a una prueba visual ni de persistencia.

## Comprobación en tu instalación

Usar una base de pruebas con las migraciones y procedimientos anteriores instalados, más los dos scripts indicados arriba.

1. Crear un año, un período, las modalidades y los recursos necesarios; comprobar que no pide campos de otro formulario.
2. Crear un plan con dos materias y un grupo. Confirmar que año/plan/grupo quedan seleccionados al guardar.
3. Crear otro año/plan/grupo y alternar entre ellos: no deben mezclarse períodos, materias, horarios o estudiantes.
4. Asignar dos profesores. La materia ya asignada debe salir del selector de nuevas asignaciones.
5. Agregar un horario válido; intentar uno cruzado y comprobar el mensaje de rechazo sin duplicados.
6. Inscribir dos estudiantes con respaldo de matrícula. Probar también uno sin respaldo y confirmar rechazo controlado.
7. Abrir una clase desde el grupo. Crear una evaluación; debe abrir sus resultados sin buscarla nuevamente.
8. Guardar una nota y pasar al siguiente pendiente. Confirmar que muestra la misma evaluación y conserva la nota anterior al recargar.
9. Verificar que no permite publicar con pendientes o peso numérico inferior a 100 %. Completar los datos y publicar solo en esta base de pruebas.
10. Iniciar sesión como Profesor: debe ver solo sus clases y no poder crear catálogos ni tipos. Confirmar también que Cajero no entra a Organización académica.
11. Revisar a 390 px y en escritorio: formularios legibles, navegación accesible y tablas desplazables.
