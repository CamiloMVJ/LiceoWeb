CREATE OR ALTER PROCEDURE dbo.Personal_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 54500,N'Se requiere una transacción.',1;
 DECLARE @Resultado int;
 EXEC @Resultado=sys.sp_getapplock @Resource=N'Liceo.Personal',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Resultado<0 THROW 54502,N'Personal ocupado; vuelva a intentar.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U
 JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
 LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE U.Id=@UsuarioId AND R.Name=N'Administrador' AND ISNULL(E.Activa,1)=1
 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
 THROW 54501,N'Acceso denegado.',1;
END;
GO
