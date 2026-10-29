-- Ejecutar COMPLETO en LiceoWeb_Dev. No modifica los pagos existentes.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 51000, N'Seleccione LiceoWeb_Dev.', 1;
IF OBJECT_ID(N'dbo.Pagos', N'U') IS NULL OR OBJECT_ID(N'dbo.AspNetUsers', N'U') IS NULL
    THROW 51001, N'Faltan las tablas del negocio o las migraciones de Identity.', 1;
IF OBJECT_ID(N'dbo.Historial_Comprobantes', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.Auditoria', N'U') IS NOT NULL
   OR OBJECT_ID(N'dbo.Secuencia_Comprobantes', N'SO') IS NOT NULL
    THROW 51002, N'La etapa 8 ya existe total o parcialmente. No repetir sin revisar.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Se inicia despues de cualquier comprobante RC-n preexistente.
    DECLARE @Maximo bigint = ISNULL((
        SELECT MAX(TRY_CONVERT(bigint, SUBSTRING(Id_Comprobante, 4, 22)))
        FROM dbo.Pagos WHERE Id_Comprobante LIKE N'RC-%'), 0);
    IF @Maximo >= 9223372036854775807
        THROW 51003, N'Se agoto la numeracion disponible.', 1;
    DECLARE @Inicio bigint = CASE WHEN @Maximo < 1 THEN 1 ELSE @Maximo + 1 END;
    DECLARE @Sql nvarchar(max) =
        N'CREATE SEQUENCE dbo.Secuencia_Comprobantes AS bigint START WITH '
        + CONVERT(nvarchar(20), @Inicio)
        + N' INCREMENT BY 1 MINVALUE 1 NO MAXVALUE NO CYCLE;';
    EXEC sys.sp_executesql @Sql;

    CREATE TABLE dbo.Historial_Comprobantes (
        Id_Comprobante nvarchar(25) NOT NULL
            CONSTRAINT PK_Historial_Comprobantes PRIMARY KEY,
        IdOperacion uniqueidentifier NOT NULL
            CONSTRAINT UQ_Historial_Comprobantes_Operacion UNIQUE,
        UsuarioId nvarchar(450) NOT NULL,
        UsuarioNombre nvarchar(256) NOT NULL,
        NombreEstudiante nvarchar(100) NOT NULL,
        Modalidad nvarchar(20) NOT NULL,
        Grado nvarchar(50) NOT NULL,
        DineroRecibido decimal(18,2) NOT NULL,
        SaldoAnterior decimal(18,2) NOT NULL,
        SaldoUtilizado decimal(18,2) NOT NULL,
        DeudaCancelada decimal(18,2) NOT NULL,
        CambioDevuelto decimal(18,2) NOT NULL,
        SaldoFinal decimal(18,2) NOT NULL,
        CONSTRAINT FK_Historial_Comprobantes_Pago
            FOREIGN KEY (Id_Comprobante) REFERENCES dbo.Pagos(Id_Comprobante),
        CONSTRAINT FK_Historial_Comprobantes_Usuario
            FOREIGN KEY (UsuarioId) REFERENCES dbo.AspNetUsers(Id),
        CONSTRAINT CK_Historial_Comprobantes_Importes CHECK (
            DineroRecibido >= 0 AND SaldoAnterior >= 0 AND SaldoUtilizado >= 0
            AND DeudaCancelada >= 0 AND CambioDevuelto >= 0 AND SaldoFinal >= 0
            AND SaldoUtilizado <= SaldoAnterior AND SaldoUtilizado <= DeudaCancelada
            AND CambioDevuelto <= DineroRecibido
            AND DeudaCancelada - SaldoUtilizado <= DineroRecibido - CambioDevuelto
            AND SaldoAnterior + DineroRecibido = DeudaCancelada + CambioDevuelto + SaldoFinal)
    );

    CREATE TABLE dbo.Auditoria (
        Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Auditoria PRIMARY KEY,
        Fecha datetime2(3) NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT (
            CONVERT(datetime2(3), SYSUTCDATETIME()
                AT TIME ZONE 'UTC' AT TIME ZONE 'Central America Standard Time')),
        UsuarioId nvarchar(450) NOT NULL,
        UsuarioNombre nvarchar(256) NOT NULL,
        Accion nvarchar(50) NOT NULL,
        Entidad nvarchar(80) NOT NULL,
        RegistroId nvarchar(100) NOT NULL,
        IdOperacion uniqueidentifier NOT NULL,
        AntesJson nvarchar(max) NULL,
        DespuesJson nvarchar(max) NULL,
        CONSTRAINT FK_Auditoria_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.AspNetUsers(Id),
        CONSTRAINT CK_Auditoria_AntesJson CHECK (AntesJson IS NULL OR ISJSON(AntesJson) = 1),
        CONSTRAINT CK_Auditoria_DespuesJson CHECK (DespuesJson IS NULL OR ISJSON(DespuesJson) = 1)
    );
    CREATE INDEX IX_Auditoria_Entidad_Registro ON dbo.Auditoria(Entidad, RegistroId, Fecha);
    CREATE INDEX IX_Auditoria_Operacion ON dbo.Auditoria(IdOperacion);
    CREATE INDEX IX_Auditoria_Usuario_Fecha ON dbo.Auditoria(UsuarioId, Fecha);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
