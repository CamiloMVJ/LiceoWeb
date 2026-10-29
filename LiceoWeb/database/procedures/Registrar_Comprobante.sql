CREATE OR ALTER PROCEDURE dbo.Registrar_Comprobante
    @Registro nvarchar(10),
    @Concepto nvarchar(35),
    @MetodoPago nvarchar(15),
    @Referencia nvarchar(100),
    @Descripcion nvarchar(100),
    @UsuarioId nvarchar(450),
    @IdOperacion uniqueidentifier,
    @Modalidad nvarchar(20),
    @Grado nvarchar(50),
    @DineroRecibido decimal(18,2),
    @SaldoAnterior decimal(18,2),
    @SaldoUtilizado decimal(18,2),
    @DeudaCancelada decimal(18,2),
    @CambioDevuelto decimal(18,2),
    @SaldoFinal decimal(18,2),
    @IdComprobante nvarchar(25) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @IdComprobante = NULL;
    IF DB_NAME() <> N'LiceoWeb_Dev'
        THROW 51200, N'Base incorrecta.', 1;
    IF @@TRANCOUNT = 0 OR XACT_STATE() <> 1
        THROW 51201, N'El comprobante debe formar parte de la transaccion del cobro.', 1;

    IF @IdOperacion IS NULL OR @UsuarioId IS NULL
        THROW 51202, N'Faltan usuario u operacion.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Historial_Comprobantes WHERE IdOperacion = @IdOperacion)
        THROW 51203, N'Operacion ya registrada. No repetir el cobro.', 1;

    IF @DineroRecibido IS NULL OR @SaldoAnterior IS NULL OR @SaldoUtilizado IS NULL
       OR @DeudaCancelada IS NULL OR @CambioDevuelto IS NULL OR @SaldoFinal IS NULL
        THROW 51204, N'Faltan importes del cobro.', 1;
    IF @DineroRecibido < 0 OR @SaldoAnterior < 0 OR @SaldoUtilizado < 0
       OR @DeudaCancelada < 0 OR @CambioDevuelto < 0 OR @SaldoFinal < 0
       OR @SaldoUtilizado > @SaldoAnterior OR @SaldoUtilizado > @DeudaCancelada
       OR @CambioDevuelto > @DineroRecibido
       OR @DeudaCancelada - @SaldoUtilizado > @DineroRecibido - @CambioDevuelto
       OR @SaldoAnterior + @DineroRecibido <> @DeudaCancelada + @CambioDevuelto + @SaldoFinal
        THROW 51205, N'Los importes no cumplen el balance del cobro.', 1;
    IF @DineroRecibido = 0 AND @SaldoUtilizado = 0
        THROW 51206, N'No hay dinero ni saldo aplicado.', 1;

    IF @MetodoPago IS NULL OR @MetodoPago NOT IN (N'Efectivo', N'Transferencia', N'Saldo')
        THROW 51207, N'Metodo de pago invalido.', 1;
    IF @MetodoPago = N'Transferencia' AND NULLIF(LTRIM(RTRIM(@Referencia)), N'') IS NULL
        THROW 51208, N'La transferencia necesita referencia.', 1;
    IF (@MetodoPago = N'Saldo' AND (@DineroRecibido <> 0 OR @SaldoUtilizado <= 0))
       OR (@MetodoPago <> N'Saldo' AND @DineroRecibido <= 0)
        THROW 51209, N'El metodo no coincide con los importes.', 1;
    IF @Concepto IS NULL OR @Concepto NOT IN (
        N'Matrícula', N'Mensualidad', N'Promoción', N'Mantenimiento',
        N'Evaluaciones, Boletín y Tarjeta', N'Uso de Saldo')
        THROW 51210, N'Concepto invalido.', 1;
    IF @Modalidad IS NULL OR @Modalidad NOT IN (N'Preescolar', N'Primaria', N'Secundaria')
       OR NULLIF(LTRIM(RTRIM(@Grado)), N'') IS NULL
        THROW 51211, N'Falta modalidad o grado valido de la operacion.', 1;

    DECLARE @Nombre nvarchar(100), @UsuarioNombre nvarchar(256);
    SELECT @Nombre = NombreEstudiante FROM dbo.Estudiantes WHERE Registro = @Registro;
    SELECT @UsuarioNombre = UserName FROM dbo.AspNetUsers WHERE Id = @UsuarioId;
    IF @Nombre IS NULL OR @UsuarioNombre IS NULL
        THROW 51212, N'Estudiante o usuario inexistente.', 1;

    DECLARE @Numero bigint = NEXT VALUE FOR dbo.Secuencia_Comprobantes;
    SET @IdComprobante = N'RC-' + CONVERT(nvarchar(20), @Numero);
    DECLARE @Fecha datetime = CONVERT(datetime,
        SYSUTCDATETIME() AT TIME ZONE 'UTC'
            AT TIME ZONE 'Central America Standard Time');

    -- Monto representa ingreso NUEVO NETO para los cobros de este procedimiento.
    INSERT dbo.Pagos (
        Id_Comprobante, Registro_Estudiante, Fecha_Pago, Concepto,
        Monto, Metodo_Pago, Referencia_Transaccion, Descripcion)
    VALUES (
        @IdComprobante, @Registro, @Fecha, @Concepto,
        @DineroRecibido - @CambioDevuelto, @MetodoPago,
        CASE WHEN @MetodoPago = N'Transferencia' THEN @Referencia ELSE NULL END,
        @Descripcion);

    INSERT dbo.Historial_Comprobantes (
        Id_Comprobante, IdOperacion, UsuarioId, UsuarioNombre,
        NombreEstudiante, Modalidad, Grado, DineroRecibido,
        SaldoAnterior, SaldoUtilizado, DeudaCancelada, CambioDevuelto, SaldoFinal)
    VALUES (
        @IdComprobante, @IdOperacion, @UsuarioId, @UsuarioNombre,
        @Nombre, @Modalidad, @Grado, @DineroRecibido,
        @SaldoAnterior, @SaldoUtilizado, @DeudaCancelada, @CambioDevuelto, @SaldoFinal);

    DECLARE @Despues nvarchar(max) = (
        SELECT @IdComprobante AS IdComprobante, @Registro AS Estudiante,
            @Concepto AS Concepto, @DineroRecibido AS DineroRecibido,
            @SaldoAnterior AS SaldoAnterior, @SaldoUtilizado AS SaldoUtilizado,
            @DeudaCancelada AS DeudaCancelada, @CambioDevuelto AS CambioDevuelto,
            @SaldoFinal AS SaldoFinal
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    EXEC dbo.Registrar_Auditoria
        @UsuarioId = @UsuarioId, @Accion = N'RegistrarCobro',
        @Entidad = N'Pagos', @RegistroId = @IdComprobante,
        @IdOperacion = @IdOperacion, @DespuesJson = @Despues;

    -- El llamador actualiza deudas y saldo y hace COMMIT.
    -- No hay COMMIT, ROLLBACK ni SELECT de resultados en este procedimiento.
END;
