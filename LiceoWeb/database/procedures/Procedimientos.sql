/* ==========================================================================================
MÓDULO PAO: MENSUALIDADES, VENCIMIENTOS, SALDOS, ARREGLOS Y PRECIOS
Base de datos: Registro_Pagos
Incluye:

Ajustes estructurales previos (Migración para tablas de este módulo)

Los 13 procedimientos asignados a Pao (con las mejoras y correcciones requeridas)

Los 2 procedimientos auxiliares nuevos (Actualizar_Estados_Vencidos y Buscar_Estudiantes_Mensualidad)
========================================================================================== */

USE Registro_Pagos;
GO


-- 0.1 Asegurar clave primaria en Mensualidades
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Mensualidades'))
ALTER TABLE Mensualidades ADD CONSTRAINT PK_Mensualidades PRIMARY KEY (Id);
GO

-- 0.2 Garantizar una sola fila de saldo por estudiante en Abonos
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Abonos_Estudiante' AND object_id = OBJECT_ID('Abonos'))
ALTER TABLE Abonos ADD CONSTRAINT UQ_Abonos_Estudiante UNIQUE (Registro_Estudiante);
GO

-- 0.3 Añadir Anio y Usuario_Responsable a Arreglos_Pago para evitar afectar otros años y auditar
IF COL_LENGTH('Arreglos_Pago', 'Anio') IS NULL
ALTER TABLE Arreglos_Pago ADD Anio INT NOT NULL DEFAULT YEAR(GETDATE());
GO

IF COL_LENGTH('Arreglos_Pago', 'Usuario_Responsable') IS NULL
ALTER TABLE Arreglos_Pago ADD Usuario_Responsable NVARCHAR(100) NULL;
GO

-- 0.4 Permitir el método 'Saldo' en el CHECK de la tabla Pagos cuando se paga exclusivamente con saldo
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Pagos') AND definition LIKE '%Metodo_pago%';

IF @ConstraintName IS NOT NULL
EXEC('ALTER TABLE Pagos DROP CONSTRAINT ' + @ConstraintName);
GO

ALTER TABLE Pagos ADD CONSTRAINT CK_Pagos_Metodo_Pago
CHECK (Metodo_Pago IN ('Efectivo', 'Transferencia', 'Saldo'));
GO

/* ==========================================================================================

PRECIOS DE MENSUALIDAD
========================================================================================== */

-- 1.1 Mostrar_Costo_Mensualidad (Igual al original, con alias claros)
CREATE OR ALTER PROCEDURE Mostrar_Costo_Mensualidad
AS
BEGIN
SET NOCOUNT ON;

SELECT 
    Mensualidad_Modalidad, 
    Costo_Actual 
FROM Costo_Mensualidad
ORDER BY Mensualidad_Modalidad;


END
GO

-- 1.2 Actualizar_Costo_Mensualidad (Con validación de monto positivo en el servidor)
CREATE OR ALTER PROCEDURE Actualizar_Costo_Mensualidad
@Modalidad NVARCHAR(20),
@CostoNuevo INT
AS
BEGIN
SET NOCOUNT ON;

IF (@CostoNuevo <= 0)
BEGIN
    RAISERROR('El nuevo costo de la mensualidad debe ser mayor a cero.', 16, 1);
    RETURN;
END

UPDATE Costo_Mensualidad 
SET Costo_Actual = @CostoNuevo 
WHERE Mensualidad_Modalidad = @Modalidad;


END
GO

/* ==========================================================================================
2. VENCIMIENTOS Y MORA (CORTE DÍA 17)
========================================================================================== */

-- 2.1 [NUEVO AUXILIAR] Actualizar_Estados_Vencidos
-- Unifica la regla de vencimiento (día 17) para llamarla antes de cualquier consulta o cobro
CREATE OR ALTER PROCEDURE Actualizar_Estados_Vencidos
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Dia_Corte INT = 17;
DECLARE @Fecha_Actual DATETIME = GETDATE();
DECLARE @Anio_Actual INT = YEAR(@Fecha_Actual);
DECLARE @Mes_Actual INT = MONTH(@Fecha_Actual);
DECLARE @Dia_Actual INT = DAY(@Fecha_Actual);

UPDATE Mensualidades 
SET Estado = 'Vencido'
WHERE Estado = 'Pendiente' 
  AND (
      (Anio < @Anio_Actual) OR 
      (Anio = @Anio_Actual AND Numero_Mes < @Mes_Actual) OR 
      (Anio = @Anio_Actual AND Numero_Mes = @Mes_Actual AND @Dia_Actual > @Dia_Corte)
  );


END
GO

-- 2.2 Actualizar_Visualizar_Mora (Mejorado: Usa la regla unificada y permite filtrar por año)
CREATE OR ALTER PROCEDURE Actualizar_Visualizar_Mora
@Mes_Visualizar INT = NULL,
@Anio_Visualizar INT = NULL
AS
BEGIN
SET NOCOUNT ON;

-- Actualiza primero cualquier cuota vencida al corte del día 17
EXEC Actualizar_Estados_Vencidos;

SELECT 
    E.Registro, 
    E.NombreEstudiante AS [Nombre],
    M.Modalidad, 
    E.Grado,
    M.Mes, 
    M.Numero_Mes,
    M.Anio, 
    M.Costo_Mensualidad, 
    M.Estado
FROM Mensualidades M
INNER JOIN Estudiantes E ON M.Registro_Estudiante = E.Registro
WHERE M.Estado = 'Vencido'
  AND (@Mes_Visualizar IS NULL OR M.Numero_Mes = @Mes_Visualizar)
  AND (@Anio_Visualizar IS NULL OR M.Anio = @Anio_Visualizar)
ORDER BY M.Anio ASC, M.Numero_Mes ASC, E.NombreEstudiante ASC;


END
GO

/* ==========================================================================================
3. CONSULTAS DE MENSUALIDADES, SALDOS Y PAGOS REALIZADOS
========================================================================================== */

-- 3.1 [NUEVO AUXILIAR] Buscar_Estudiantes_Mensualidad
-- Devuelve TODAS las coincidencias para que el usuario elija al estudiante correcto (sin TOP 1)
CREATE OR ALTER PROCEDURE Buscar_Estudiantes_Mensualidad
@TextoBusqueda NVARCHAR(100) = ''
AS
BEGIN
SET NOCOUNT ON;

SELECT 
    E.Registro,
    E.CodigoEstudiante,
    E.NombreEstudiante,
    E.Modalidad,
    E.Grado,
    E.Estado,
    ISNULL(A.Abono_Disponible, 0) AS SaldoFavor
FROM Estudiantes E
LEFT JOIN Abonos A ON E.Registro = A.Registro_Estudiante
WHERE (@TextoBusqueda IS NULL OR @TextoBusqueda = ''
       OR E.NombreEstudiante LIKE '%' + @TextoBusqueda + '%'
       OR E.Registro LIKE '%' + @TextoBusqueda + '%'
       OR E.CodigoEstudiante LIKE '%' + @TextoBusqueda + '%')
ORDER BY E.NombreEstudiante ASC;


END
GO

-- 3.2 Ver_Estado_Mensualidad_Cuenta (Mejorado: Permite buscar por Registro exacto y actualiza mora)
CREATE OR ALTER PROCEDURE Ver_Estado_Mensualidad_Cuenta
@TextoBusqueda NVARCHAR(100)
AS
BEGIN
SET NOCOUNT ON;

-- Aseguramos que las cuotas vencidas estén al día
EXEC Actualizar_Estados_Vencidos;

DECLARE @Registro NVARCHAR(10);

-- Si se recibe el Registro exacto seleccionado en la lista (ej. 'E_0000001')
IF EXISTS (SELECT 1 FROM Estudiantes WHERE Registro = @TextoBusqueda)
BEGIN
    SET @Registro = @TextoBusqueda;
END
ELSE
BEGIN
    -- Respaldo por compatibilidad si se pasa un nombre directamente
    SELECT TOP 1 @Registro = Registro 
    FROM Estudiantes 
    WHERE NombreEstudiante LIKE '%' + @TextoBusqueda + '%' 
    ORDER BY CASE WHEN Estado = 'Activo' THEN 0 ELSE 1 END, Registro ASC;
END

IF (@Registro IS NOT NULL)
BEGIN
    SELECT 
        M.Id,
        E.Registro,
        E.NombreEstudiante,
        M.Modalidad,
        E.Grado,
        M.Mes,
        M.Numero_Mes,
        M.Anio,
        M.Estado,
        M.Costo_Mensualidad,
        ISNULL(A.Abono_Disponible, 0) AS SaldoFavor 
    FROM Mensualidades M
    INNER JOIN Estudiantes E ON M.Registro_Estudiante = E.Registro
    LEFT JOIN Abonos A ON E.Registro = A.Registro_Estudiante
    WHERE E.Registro = @Registro
      AND M.Estado IN ('Pendiente', 'Vencido')
    ORDER BY M.Anio ASC, M.Numero_Mes ASC;
END


END
GO

-- 3.3 Filtrar_Mensualidades_Consultas (Mejorado: Permite consultar años anteriores con @Anio)
CREATE OR ALTER PROCEDURE Filtrar_Mensualidades_Consultas
@NombreEstudiante NVARCHAR(100) = '',
@Modalidad NVARCHAR(20) = 'Todos',
@Grado NVARCHAR(50) = 'Todos',
@Mes NVARCHAR(20) = 'Todos',
@Estado NVARCHAR(20) = 'Todos',
@Anio INT = NULL -- NULL o 0 permite consultar todos los años (incluyendo años anteriores)
AS
BEGIN
SET NOCOUNT ON;

EXEC Actualizar_Estados_Vencidos;

SELECT 
    M.Id,
    E.Registro,
    E.NombreEstudiante,
    E.Grado,
    M.Modalidad,
    M.Anio,
    M.Mes,
    M.Numero_Mes,
    M.Costo_Mensualidad AS Monto,
    M.Estado,
    ISNULL(A.Abono_Disponible, 0) AS SaldoDisponible
FROM Mensualidades M
INNER JOIN Estudiantes E ON M.Registro_Estudiante = E.Registro
LEFT JOIN Abonos A ON E.Registro = A.Registro_Estudiante
WHERE 
    (@Anio IS NULL OR @Anio = 0 OR M.Anio = @Anio)
    AND (@NombreEstudiante IS NULL OR @NombreEstudiante = '' 
         OR E.NombreEstudiante LIKE '%' + @NombreEstudiante + '%'
         OR E.Registro LIKE '%' + @NombreEstudiante + '%')
    AND (@Modalidad = 'Todos' OR M.Modalidad = @Modalidad)
    AND (@Grado = 'Todos' OR E.Grado = @Grado)
    AND (@Mes = 'Todos' OR M.Mes = @Mes)
    AND (@Estado = 'Todos' OR M.Estado = @Estado)
ORDER BY M.Anio DESC, M.Numero_Mes ASC, E.NombreEstudiante ASC;


END
GO

-- 3.4 Listar_Abonos_Activos (Mejorado: Incluye Registro y Grado además del Saldo a Favor)
CREATE OR ALTER PROCEDURE Listar_Abonos_Activos
@Busqueda NVARCHAR(100) = ''
AS
BEGIN
SET NOCOUNT ON;

SELECT 
    E.Registro,
    E.NombreEstudiante AS [Estudiante],
    E.Modalidad,
    E.Grado,
    A.Abono_Disponible AS [Saldo a Favor]
FROM Abonos A
INNER JOIN Estudiantes E ON A.Registro_Estudiante = E.Registro
WHERE 
    (@Busqueda IS NULL OR @Busqueda = '' 
     OR E.NombreEstudiante LIKE '%' + @Busqueda + '%'
     OR E.Registro LIKE '%' + @Busqueda + '%')
    AND A.Abono_Disponible > 0
ORDER BY E.NombreEstudiante ASC;


END
GO

-- 3.5 Ver_Pagos_Realizados (Mejorado: Permite filtrar opcionalmente por año)
CREATE OR ALTER PROCEDURE Ver_Pagos_Realizados
@Mes_Visualizar INT = NULL,
@Anio_Visualizar INT = NULL
AS
BEGIN
SET NOCOUNT ON;

SELECT 
    E.Registro AS [ID Estudiante], 
    E.NombreEstudiante AS [Nombre del Estudiante],
    M.Modalidad, 
    M.Mes AS [Mes Pagado], 
    M.Anio AS [Año], 
    M.Costo_Mensualidad AS [Monto Pagado],
    P.Fecha_Pago AS [Fecha de Pago], 
    M.Id_Comprobante AS [N° Recibo]
FROM Mensualidades M
INNER JOIN Estudiantes E ON M.Registro_Estudiante = E.Registro
INNER JOIN Pagos P ON M.Id_Comprobante = P.Id_Comprobante 
WHERE M.Estado = 'Cancelado'
  AND (@Mes_Visualizar IS NULL OR M.Numero_Mes = @Mes_Visualizar)
  AND (@Anio_Visualizar IS NULL OR M.Anio = @Anio_Visualizar)
ORDER BY M.Anio DESC, M.Numero_Mes DESC, P.Fecha_Pago DESC;


END
GO

/* ==========================================================================================
4. ARREGLOS DE PAGO Y BECAS
========================================================================================== */

-- 4.1 Buscar_Estudiante_Arreglo (Mejorado: Considera cuotas Pendientes y Vencidas del año)
CREATE OR ALTER PROCEDURE Buscar_Estudiante_Arreglo
@Texto NVARCHAR(100),
@Anio INT = NULL
AS
BEGIN
SET NOCOUNT ON;

EXEC Actualizar_Estados_Vencidos;

IF @Anio IS NULL SET @Anio = YEAR(GETDATE());

SELECT 
    E.Registro,
    E.NombreEstudiante,
    E.Modalidad,
    E.Grado,
    CM.Costo_Actual,
    @Anio AS Anio,
    ISNULL((
        SELECT SUM(M.Costo_Mensualidad)
        FROM Mensualidades M
        WHERE M.Registro_Estudiante = E.Registro
          AND M.Anio = @Anio
          AND M.Estado IN ('Pendiente', 'Vencido')
    ), 0) AS DeudaAnio,
    ISNULL((
        SELECT TOP 1 Numero_Mes 
        FROM Mensualidades M 
        WHERE M.Registro_Estudiante = E.Registro 
          AND M.Anio = @Anio
          AND M.Estado IN ('Pendiente', 'Vencido')
        ORDER BY Numero_Mes ASC
    ), 1) AS MesNumero,
    CASE ISNULL((
        SELECT TOP 1 Numero_Mes 
        FROM Mensualidades M 
        WHERE M.Registro_Estudiante = E.Registro 
          AND M.Anio = @Anio
          AND M.Estado IN ('Pendiente', 'Vencido')
        ORDER BY Numero_Mes ASC
    ), 1)
        WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
        ELSE 'N/A'
    END AS MesNombre
FROM Estudiantes E
INNER JOIN Costo_Mensualidad CM ON E.Modalidad = CM.Mensualidad_Modalidad
WHERE 
    (E.Registro LIKE '%' + @Texto + '%') OR 
    (E.NombreEstudiante LIKE '%' + @Texto + '%')
ORDER BY E.NombreEstudiante ASC;


END
GO

-- 4.2 Verificar_Arreglo_Previo (Mejorado: Permite verificar en general o por año específico)
CREATE OR ALTER PROCEDURE Verificar_Arreglo_Previo
@Registro NVARCHAR(10),
@Anio INT = NULL
AS
BEGIN
SET NOCOUNT ON;

SELECT COUNT(*) AS TotalArreglos
FROM Arreglos_Pago 
WHERE Registro_Estudiante = @Registro
  AND (@Anio IS NULL OR Anio = @Anio);


END
GO

-- 4.3 Crear_Arreglo_Pago (Mejorado: Filtra por @Anio para no afectar otros años y registra Usuario)
CREATE OR ALTER PROCEDURE Crear_Arreglo_Pago
@Registro NVARCHAR(10),
@Nuevo_Monto INT,
@Descripcion_Motivo NVARCHAR(200),
@Aplicar_Desde_Mes INT,
@Anio INT = NULL,
@Usuario_Responsable NVARCHAR(100) = 'Administrador'
AS
BEGIN
SET NOCOUNT ON;

IF @Anio IS NULL SET @Anio = YEAR(GETDATE());

IF (@Nuevo_Monto < 0)
BEGIN
    RAISERROR('El nuevo monto del arreglo no puede ser negativo.', 16, 1);
    RETURN;
END

IF (@Aplicar_Desde_Mes NOT BETWEEN 1 AND 12)
BEGIN
    RAISERROR('El mes de inicio debe estar entre 1 y 12.', 16, 1);
    RETURN;
END

IF (LTRIM(RTRIM(ISNULL(@Descripcion_Motivo, ''))) = '')
BEGIN
    RAISERROR('Debe ingresar el motivo del arreglo de pago o beca.', 16, 1);
    RETURN;
END

DECLARE @monto_anterior INT;

-- Obtenemos el monto anterior dentro del año y período seleccionado
SELECT TOP 1 @monto_anterior = Costo_Mensualidad 
FROM Mensualidades 
WHERE Registro_Estudiante = @Registro 
  AND Anio = @Anio
  AND Estado IN ('Pendiente', 'Vencido') 
  AND Numero_Mes >= @Aplicar_Desde_Mes
ORDER BY Numero_Mes ASC;

IF @monto_anterior IS NULL
BEGIN
    RAISERROR('No existen mensualidades pendientes o vencidas desde ese mes para el año %d.', 16, 1, @Anio);
    RETURN;
END

BEGIN TRAN
    -- CASO A: BECA COMPLETA (Monto 0) -> Cancela la deuda del año y período seleccionado
    IF (@Nuevo_Monto = 0)
    BEGIN
        UPDATE Mensualidades 
        SET Costo_Mensualidad = 0,
            Estado = 'Cancelado'
        WHERE Registro_Estudiante = @Registro 
          AND Anio = @Anio
          AND Estado IN ('Pendiente', 'Vencido')
          AND Numero_Mes >= @Aplicar_Desde_Mes;
    END
    -- CASO B: ARREGLO DE PAGO (Monto > 0) -> Actualiza el precio sin tocar las ya pagadas
    ELSE
    BEGIN
        UPDATE Mensualidades 
        SET Costo_Mensualidad = @Nuevo_Monto
        WHERE Registro_Estudiante = @Registro 
          AND Anio = @Anio
          AND Estado IN ('Pendiente', 'Vencido') 
          AND Numero_Mes >= @Aplicar_Desde_Mes;
    END

    -- Guardar en Historial incluyendo Año y Usuario Responsable
    INSERT INTO Arreglos_Pago (
        Registro_Estudiante, Fecha_Registro, Monto_Anterior, 
        Monto_Nuevo, Mes_Inicio, Motivo, Anio, Usuario_Responsable
    )
    VALUES (
        @Registro, GETDATE(), @monto_anterior, 
        @Nuevo_Monto, @Aplicar_Desde_Mes, @Descripcion_Motivo, @Anio, @Usuario_Responsable
    );
COMMIT TRAN


END
GO

-- 4.4 Listar_Historial_Arreglos (Mejorado: Muestra Año y Usuario Responsable)
CREATE OR ALTER PROCEDURE Listar_Historial_Arreglos
@Busqueda NVARCHAR(100) = ''
AS
BEGIN
SET NOCOUNT ON;

SELECT 
    A.Id,
    A.Fecha_Registro AS Fecha,
    E.Registro,
    E.NombreEstudiante AS Estudiante,
    E.Modalidad,
    E.Grado,
    A.Anio AS [Año],
    A.Monto_Anterior,
    A.Monto_Nuevo AS [Monto Acordado],
    A.Mes_Inicio AS [Aplica desde Mes #],
    A.Motivo,
    ISNULL(A.Usuario_Responsable, 'Administrador') AS UsuarioResponsable
FROM Arreglos_Pago A
INNER JOIN Estudiantes E ON A.Registro_Estudiante = E.Registro
WHERE 
    (@Busqueda IS NULL OR @Busqueda = '') 
    OR (E.NombreEstudiante LIKE '%' + @Busqueda + '%')
    OR (E.Registro LIKE '%' + @Busqueda + '%')
ORDER BY A.Fecha_Registro DESC;


END
GO

/* ==========================================================================================
5. CÁLCULO Y COBRO DE MENSUALIDADES
========================================================================================== */

-- 5.1 Calcular_Total_Pagar (Actualiza estados vencidos antes de sumar)
CREATE OR ALTER PROCEDURE Calcular_Total_Pagar
@Registro NVARCHAR(10),
@Numero_Mes_Limite INT,
@Anio INT
AS
BEGIN
SET NOCOUNT ON;

EXEC Actualizar_Estados_Vencidos;

SELECT ISNULL(SUM(Costo_Mensualidad), 0) AS Total_A_Pagar
FROM Mensualidades
WHERE Registro_Estudiante = @Registro
  AND Estado IN ('Pendiente', 'Vencido')
  AND (
      (Anio < @Anio) 
      OR 
      (Anio = @Anio AND Numero_Mes <= @Numero_Mes_Limite) 
  );


END
GO

-- 5.2 Pagar_Mensualidad (Mejorado: Respeta mes/año límite, soporta pago con saldo, bloquea concurrencia y devuelve contrato completo)
CREATE OR ALTER PROCEDURE Pagar_Mensualidad
@Registro NVARCHAR(10),
@Monto INT,
@Descripcion NVARCHAR(100),
@IntegrarSaldo BIT,
@Metodo_Pago NVARCHAR(20),
@Referencia NVARCHAR(50) = NULL,
@Anio_Limite INT = NULL,
@Numero_Mes_Limite INT = NULL,
@Id_Comprobante_Externo NVARCHAR(25) = NULL
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. Validaciones de entrada en el servidor
IF (@Monto IS NULL OR @Monto < 0)
BEGIN
    RAISERROR('El monto recibido no puede ser negativo.', 16, 1);
    RETURN;
END

IF (@Monto > 0 AND @Metodo_Pago NOT IN ('Efectivo', 'Transferencia'))
BEGIN
    RAISERROR('Método de pago inválido. Seleccione Efectivo o Transferencia.', 16, 1);
    RETURN;
END

IF (@Monto > 0 AND @Metodo_Pago = 'Transferencia' AND LTRIM(RTRIM(ISNULL(@Referencia, ''))) = '')
BEGIN
    RAISERROR('La referencia es obligatoria cuando el método de pago es Transferencia.', 16, 1);
    RETURN;
END

-- Si no envían límite explícito, se procesan las deudas pendientes en orden cronológico
IF (@Anio_Limite IS NULL) SET @Anio_Limite = 9999;
IF (@Numero_Mes_Limite IS NULL) SET @Numero_Mes_Limite = 12;

BEGIN TRAN
    -- 2. Leer y bloquear el saldo actual del estudiante para evitar uso duplicado en sesiones simultáneas
    DECLARE @abono_anterior INT = 0;

    SELECT TOP 1 @abono_anterior = Abono_Disponible
    FROM Abonos WITH (UPDLOCK, HOLDLOCK)
    WHERE Registro_Estudiante = @Registro;

    DECLARE @total_dinero_disponible INT = @Monto + @abono_anterior;

    IF (@total_dinero_disponible <= 0)
    BEGIN
        ROLLBACK TRAN;
        RAISERROR('No hay fondos suficientes.', 16, 1);
        RETURN;
    END

    -- Validar que existan cuotas dentro del límite o que se esté guardando como saldo
    IF NOT EXISTS (
        SELECT 1 FROM Mensualidades WITH (UPDLOCK, HOLDLOCK)
        WHERE Registro_Estudiante = @Registro 
          AND Estado IN ('Pendiente', 'Vencido')
          AND ((Anio < @Anio_Limite) OR (Anio = @Anio_Limite AND Numero_Mes <= @Numero_Mes_Limite))
    ) AND @IntegrarSaldo = 0
    BEGIN
        ROLLBACK TRAN;
        RAISERROR('No existen mensualidades pendientes dentro del período seleccionado.', 16, 1);
        RETURN;
    END

    -- 3. Generar identificador de comprobante único (sin colisión por segundo)
    DECLARE @id_comprobante NVARCHAR(25);
    IF (@Id_Comprobante_Externo IS NOT NULL AND @Id_Comprobante_Externo <> '')
        SET @id_comprobante = @Id_Comprobante_Externo;
    ELSE
        SET @id_comprobante = FORMAT(GETDATE(), 'ddMMyyyy_HHmmss') + '_' + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR), 3);

    -- 4. Insertar registro del comprobante en Pagos
    DECLARE @concepto_pago NVARCHAR(35) = CASE WHEN @Monto > 0 THEN 'Mensualidad' ELSE 'Uso de Saldo' END;
    DECLARE @metodo_real NVARCHAR(15)   = CASE WHEN @Monto > 0 THEN @Metodo_Pago ELSE 'Saldo' END;

    INSERT INTO Pagos (
        Id_Comprobante, Registro_Estudiante, Concepto, Monto, 
        Descripcion, Fecha_Pago, Metodo_Pago, Referencia_Transaccion
    )
    VALUES (
        @id_comprobante, @Registro, @concepto_pago, @Monto, 
        @Descripcion, GETDATE(), @metodo_real, @Referencia
    );

    -- 5. Recorrer y cancelar las cuotas más antiguas respetando el límite de Año y Mes
    DECLARE @id_mensualidad INT;
    DECLARE @costo_mensualidad INT;
    DECLARE @gasto_real_mensualidades INT = 0;

    DECLARE cursor_pagos CURSOR LOCAL FAST_FORWARD FOR 
    SELECT Id, Costo_Mensualidad 
    FROM Mensualidades WITH (UPDLOCK, HOLDLOCK)
    WHERE Registro_Estudiante = @Registro 
      AND Estado IN ('Pendiente', 'Vencido')
      AND (
          (Anio < @Anio_Limite) 
          OR 
          (Anio = @Anio_Limite AND Numero_Mes <= @Numero_Mes_Limite)
      )
    ORDER BY Anio ASC, Numero_Mes ASC;

    OPEN cursor_pagos;
    FETCH NEXT FROM cursor_pagos INTO @id_mensualidad, @costo_mensualidad;

    WHILE @@FETCH_STATUS = 0 AND @total_dinero_disponible >= @costo_mensualidad
    BEGIN
        UPDATE Mensualidades 
        SET Estado = 'Cancelado', 
            Id_Comprobante = @id_comprobante 
        WHERE Id = @id_mensualidad;

        SET @total_dinero_disponible = @total_dinero_disponible - @costo_mensualidad;
        SET @gasto_real_mensualidades = @gasto_real_mensualidades + @costo_mensualidad;

        FETCH NEXT FROM cursor_pagos INTO @id_mensualidad, @costo_mensualidad;
    END

    CLOSE cursor_pagos;
    DEALLOCATE cursor_pagos;

    -- Si intentó pagar solo con saldo (@Monto = 0) y no alcanzó para ninguna cuota, revertir
    IF (@Monto = 0 AND @gasto_real_mensualidades = 0)
    BEGIN
        ROLLBACK TRAN;
        RAISERROR('El saldo disponible es insuficiente para cubrir una mensualidad completa.', 16, 1);
        RETURN;
    END

    -- 6. Calcular saldo utilizado, cambio, saldo final e ingreso neto
    DECLARE @saldo_utilizado INT = CASE 
        WHEN @abono_anterior >= @gasto_real_mensualidades THEN @gasto_real_mensualidades 
        ELSE @abono_anterior 
    END;

    DECLARE @cambio_a_devolver INT = 0;
    DECLARE @saldo_final INT = 0;
    DECLARE @monto_corregido INT = 0;

    IF (@IntegrarSaldo = 1)
    BEGIN
        -- El sobrante se guarda como saldo disponible
        SET @saldo_final = @total_dinero_disponible;
        SET @cambio_a_devolver = 0;
        SET @monto_corregido = @Monto;
    END
    ELSE
    BEGIN
        -- El sobrante del dinero nuevo se devuelve como cambio
        DECLARE @efectivo_usado INT = @gasto_real_mensualidades - @saldo_utilizado;
        SET @cambio_a_devolver = @Monto - @efectivo_usado;
        SET @saldo_final = @abono_anterior - @saldo_utilizado;
        SET @monto_corregido = @efectivo_usado;
    END

    -- Actualizar Pagos para que Reporte_Ingresos solo sume dinero nuevo real
    UPDATE Pagos 
    SET Monto = @monto_corregido 
    WHERE Id_Comprobante = @id_comprobante;

    -- Actualizar Abonos con el saldo final
    IF EXISTS (SELECT 1 FROM Abonos WHERE Registro_Estudiante = @Registro)
        UPDATE Abonos SET Abono_Disponible = @saldo_final WHERE Registro_Estudiante = @Registro;
    ELSE
        INSERT INTO Abonos (Registro_Estudiante, Abono_Disponible) VALUES (@Registro, @saldo_final);

    -- 7. Devolver el contrato completo para C#, recibos y conciliación
    SELECT 
        @id_comprobante AS IdComprobante,
        @id_comprobante AS IdRecibo,
        @Monto AS DineroRecibido,
        @saldo_utilizado AS SaldoUtilizado,
        @gasto_real_mensualidades AS DeudaCancelada,
        @cambio_a_devolver AS Cambio,
        @saldo_final AS SaldoFinal;
COMMIT TRAN


END
GO