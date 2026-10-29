CREATE OR ALTER PROCEDURE dbo.Registrar_Auditoria
    @UsuarioId nvarchar(450),
    @Accion nvarchar(50),
    @Entidad nvarchar(80),
    @RegistroId nvarchar(100),
    @IdOperacion uniqueidentifier,
    @AntesJson nvarchar(max) = NULL,
    @DespuesJson nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF DB_NAME() <> N'LiceoWeb_Dev'
        THROW 51100, N'Base incorrecta.', 1;
    IF @@TRANCOUNT = 0 OR XACT_STATE() <> 1
        THROW 51101, N'La auditoria debe registrarse dentro de la transaccion del negocio.', 1;
    IF @IdOperacion IS NULL OR NULLIF(LTRIM(RTRIM(@Accion)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Entidad)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@RegistroId)), N'') IS NULL
        THROW 51102, N'Faltan datos de auditoria.', 1;

    DECLARE @UsuarioNombre nvarchar(256);
    SELECT @UsuarioNombre = UserName FROM dbo.AspNetUsers WHERE Id = @UsuarioId;
    IF @UsuarioNombre IS NULL
        THROW 51103, N'Usuario de Identity inexistente.', 1;
    IF (@AntesJson IS NOT NULL AND ISJSON(@AntesJson) <> 1)
       OR (@DespuesJson IS NOT NULL AND ISJSON(@DespuesJson) <> 1)
        THROW 51104, N'La auditoria requiere JSON valido.', 1;

    INSERT dbo.Auditoria (
        UsuarioId, UsuarioNombre, Accion, Entidad, RegistroId,
        IdOperacion, AntesJson, DespuesJson)
    VALUES (
        @UsuarioId, @UsuarioNombre, @Accion, @Entidad, @RegistroId,
        @IdOperacion, @AntesJson, @DespuesJson);
END;
