CREATE OR ALTER PROCEDURE dbo.Personal_Guardar
 @UsuarioId nvarchar(450),@CuentaId nvarchar(450),@Version nvarchar(max),
 @Rol nvarchar(max),@Activa bit,@Motivo nvarchar(max),@Operacion uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @CuentaId IS NULL OR @CuentaId=@UsuarioId THROW 54504,N'No puede modificar su propia cuenta.',1;
 IF @Rol IS NULL OR @Rol COLLATE Latin1_General_100_BIN2 NOT IN(N'Administrador',N'Profesor',N'Cajero') OR DATALENGTH(@Rol)>26 OR DATALENGTH(@Rol)<>DATALENGTH(RTRIM(@Rol))
  OR @Activa IS NULL OR @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
  OR @Version IS NULL OR LEN(@Version)=0 OR DATALENGTH(@Version)>256
  OR @Motivo IS NULL OR LEN(LTRIM(RTRIM(@Motivo)))<10 OR DATALENGTH(@Motivo)>1000
  THROW 54503,N'Datos inválidos; indique rol, versión y motivo de 10 a 500 caracteres.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  EXEC dbo.Personal_Autorizar @UsuarioId;
  -- Mismo orden siempre: Personal, Planificacion, filas de Identity.
  DECLARE @Resultado int;
  EXEC @Resultado=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Resultado<0 THROW 54502,N'Planificación ocupada; vuelva a intentar.',1;
  DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@CuentaId CuentaId,@Version Version,@Rol Rol,@Activa Activa,LTRIM(RTRIM(@Motivo)) Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud);
  IF EXISTS(SELECT 1 FROM dbo.HistorialCuentaPersonal WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.HistorialCuentaPersonal WHERE Operacion=@Operacion AND SolicitudHash=@Hash)
    THROW 54505,N'La operación ya fue usada con otros datos.',1;
   COMMIT; RETURN;
  END;
  DECLARE @VersionActual nvarchar(max),@RolAnterior nvarchar(256),@ActivaAnterior bit;
  SELECT @VersionActual=U.ConcurrencyStamp,@ActivaAnterior=ISNULL(E.Activa,1)
  FROM dbo.AspNetUsers U WITH(UPDLOCK,HOLDLOCK) LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@CuentaId;
  IF @VersionActual IS NULL THROW 54506,N'Cuenta inexistente o sin versión; requiere revisión técnica.',1;
  IF @VersionActual COLLATE Latin1_General_100_BIN2<>@Version COLLATE Latin1_General_100_BIN2
   THROW 54507,N'La cuenta cambió. Recargue antes de confirmar.',1;
  IF (SELECT COUNT(*) FROM dbo.AspNetUserRoles WHERE UserId=@CuentaId)<>1
   THROW 54508,N'Esta cuenta no tiene un único rol. Requiere revisión técnica.',1;
  SELECT @RolAnterior=R.Name FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@CuentaId;
  IF @RolAnterior NOT IN(N'Administrador',N'Profesor',N'Cajero') THROW 54508,N'Rol existente no administrable desde esta pantalla.',1;
  DECLARE @RolId nvarchar(450)=(SELECT Id FROM dbo.AspNetRoles WHERE Name=@Rol);
  IF @RolId IS NULL THROW 54508,N'El rol solicitado no existe.',1;
  IF @RolAnterior=@Rol AND @ActivaAnterior=@Activa THROW 54509,N'No hay cambios para guardar.',1;
  IF (@Activa=0 OR @Rol<>N'Profesor') AND EXISTS(
   SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
   JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.UsuarioId=@CuentaId AND P.Cerrado=0)
   THROW 54510,N'Reasigne primero las clases de los períodos abiertos de esta cuenta.',1;
  IF @RolAnterior=N'Administrador' AND (@Rol<>N'Administrador' OR @Activa=0) AND NOT EXISTS(
   SELECT 1 FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
   LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
   WHERE U.Id<>@CuentaId AND R.Name=N'Administrador' AND ISNULL(E.Activa,1)=1 AND U.EmailConfirmed=1
   AND U.PasswordHash IS NOT NULL AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
   THROW 54511,N'Debe conservar al menos un administrador habilitado con contraseña y correo confirmado.',1;
  DECLARE @Antes nvarchar(max)=(SELECT @RolAnterior Rol,@ActivaAnterior Activa FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @Despues nvarchar(max)=(SELECT @Rol Rol,@Activa Activa FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  IF @RolAnterior<>@Rol
  BEGIN
   DELETE FROM dbo.AspNetUserRoles WHERE UserId=@CuentaId;
   INSERT dbo.AspNetUserRoles(UserId,RoleId) VALUES(@CuentaId,@RolId);
  END;
  UPDATE dbo.EstadoCuentaPersonal SET Activa=@Activa WHERE UsuarioId=@CuentaId;
  IF @@ROWCOUNT=0 INSERT dbo.EstadoCuentaPersonal(UsuarioId,Activa) VALUES(@CuentaId,@Activa);
  UPDATE dbo.AspNetUsers SET SecurityStamp=CONVERT(nvarchar(36),NEWID()),ConcurrencyStamp=CONVERT(nvarchar(36),NEWID()) WHERE Id=@CuentaId;
  INSERT dbo.HistorialCuentaPersonal(CuentaId,UsuarioId,Operacion,SolicitudHash,Motivo,AntesJson,DespuesJson)
   VALUES(@CuentaId,@UsuarioId,@Operacion,@Hash,LTRIM(RTRIM(@Motivo)),@Antes,@Despues);
  EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'AdministrarCuentaPersonal',@Entidad=N'AspNetUsers',@RegistroId=@CuentaId,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
