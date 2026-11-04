CREATE OR ALTER PROCEDURE dbo.TipoEvaluacion_Guardar
 @UsuarioId nvarchar(450),@Id int,@Nombre nvarchar(max),@Activo bit,
 @Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SET @Nombre=NULLIF(TRIM(@Nombre),N'');SET @Motivo=NULLIF(TRIM(@Motivo),N'');
 IF @Id IS NULL OR @Id<=0 OR @Nombre IS NULL OR LEN(@Nombre)>100 OR @Activo IS NULL
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
 OR @Version IS NULL OR DATALENGTH(@Version)<>18 OR LEFT(@Version,2)<>'0x'
 OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54602,N'Revisa nombre, versión, operación y motivo de 10 a 500 caracteres.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @Id Id,@Nombre Nombre,@Activo Activo,@Version Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Lock int,
 @Actual binary(8),@NombreAnterior nvarchar(100),@ActivoAnterior bit;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Mismo orden que administración de personal; serializa revocación y autorización.
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Personal',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54603,N'Administración ocupada. Reintenta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND R.Name='Administrador')
 OR EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
 THROW 54601,N'Acceso exclusivo de administración activa.',1;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54603,N'Planificación ocupada. Reintenta.',1;
 IF EXISTS(SELECT 1 FROM dbo.HistorialTipoEvaluacion WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.HistorialTipoEvaluacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId)
   THROW 54604,N'La operación ya se utilizó con otros datos.',1;
  COMMIT;RETURN;
 END;
 SELECT @Actual=Version,@NombreAnterior=Nombre,@ActivoAnterior=Activo
 FROM dbo.TipoEvaluacion WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id;
 IF @Actual IS NULL THROW 54602,N'El tipo no existe.',1;
 IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54605,N'Otra persona modificó el tipo. Recarga antes de guardar.',1;
 -- Comparación binaria: incluso un cambio de mayúsculas altera el nombre histórico.
 IF CONVERT(varbinary(max),@Nombre)<>CONVERT(varbinary(max),@NombreAnterior)
 AND EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE TipoId=@Id)
 THROW 54606,N'El tipo ya tiene evaluaciones: conserva su nombre. Puedes cambiar su estado.',1;
 IF EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Nombre=@Nombre AND Id<>@Id)
 THROW 54607,N'Ya existe un tipo con ese nombre.',1;
 IF CONVERT(varbinary(max),@Nombre)=CONVERT(varbinary(max),@NombreAnterior) AND @Activo=@ActivoAnterior
 THROW 54602,N'No hay cambios para guardar.',1;
 UPDATE dbo.TipoEvaluacion SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
 INSERT dbo.HistorialTipoEvaluacion(TipoId,Operacion,SolicitudHash,UsuarioId,Motivo,NombreAnterior,NombreNuevo,ActivoAnterior,ActivoNuevo)
 VALUES(@Id,@Operacion,@Hash,@UsuarioId,@Motivo,@NombreAnterior,@Nombre,@ActivoAnterior,@Activo);
 DECLARE @Registro nvarchar(100)=CONVERT(nvarchar(100),@Id);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'TipoEvaluacion_Editar',
 @Entidad=N'TipoEvaluacion',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
