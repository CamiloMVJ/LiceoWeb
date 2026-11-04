-- Desarrollo exclusivamente. Revierte datos; las identidades/rowversion pueden avanzar.
-- Requiere 022 y los dos procedimientos TipoEvaluacion instalados.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54600,N'Use desarrollo sin transacciones abiertas.',1;
DECLARE @Usuario nvarchar(450)=(
 SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE R.Name='Administrador' AND NOT EXISTS(
 SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.UserId AND E.Activa=0)
 ORDER BY U.UserId);
IF @Usuario IS NULL THROW 54600,N'Se requiere una cuenta administrativa activa de prueba.',1;
DECLARE @Nombre nvarchar(100)=N'Prueba tipo '+CONVERT(nvarchar(36),NEWID()),
 @Nuevo nvarchar(100),@Id int,@Version varchar(18),@Operacion uniqueidentifier=NEWID();
SET @Nuevo=@Nombre+N' editado';
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.TipoEvaluacion(Nombre) VALUES(@Nombre);
 SET @Id=SCOPE_IDENTITY();
 SELECT @Version=CONVERT(varchar(18),CONVERT(binary(8),Version),1) FROM dbo.TipoEvaluacion WHERE Id=@Id;
 EXEC dbo.TipoEvaluacion_Guardar @Usuario,@Id,@Nuevo,1,@Version,@Operacion,N'Renombrado de prueba sin evaluaciones';
 IF NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Id AND Nombre=@Nuevo AND Activo=1)
 THROW 54600,N'Falló cambio de nombre.',1;
 -- Reintento con versión anterior: devuelve éxito sin repetir historial.
 EXEC dbo.TipoEvaluacion_Guardar @Usuario,@Id,@Nuevo,1,@Version,@Operacion,N'Renombrado de prueba sin evaluaciones';
 IF (SELECT COUNT(*) FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id)<>1
 THROW 54600,N'Falló idempotencia.',1;
 SELECT @Version=CONVERT(varchar(18),CONVERT(binary(8),Version),1) FROM dbo.TipoEvaluacion WHERE Id=@Id;
 SET @Operacion=NEWID();
 EXEC dbo.TipoEvaluacion_Guardar @Usuario,@Id,@Nuevo,0,@Version,@Operacion,N'Inactivación de prueba del catálogo';
 IF EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Id AND Activo=1)
 THROW 54600,N'Falló inactivación.',1;
 SELECT @Version=CONVERT(varchar(18),CONVERT(binary(8),Version),1) FROM dbo.TipoEvaluacion WHERE Id=@Id;
 SET @Operacion=NEWID();
 EXEC dbo.TipoEvaluacion_Guardar @Usuario,@Id,@Nuevo,1,@Version,@Operacion,N'Reactivación de prueba del catálogo';
 IF NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Id AND Activo=1)
 OR (SELECT COUNT(*) FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id)<>3
 THROW 54600,N'Falló reactivación o historial.',1;
 EXEC dbo.TipoEvaluacion_Consultar @Usuario,@Id,1;
 ROLLBACK;
 SELECT N'SIMULACION_REVERTIDA' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
