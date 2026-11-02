CREATE OR ALTER PROCEDURE dbo.Personal_Consultar
 @UsuarioId nvarchar(450), @CuentaId nvarchar(450)=NULL, @Pagina int=1, @Busqueda nvarchar(100)=N''
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U
 JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
 LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE U.Id=@UsuarioId AND R.Name=N'Administrador' AND ISNULL(E.Activa,1)=1
 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
 THROW 54501,N'Acceso denegado.',1;
 IF @Pagina<1 OR @Pagina>100000 THROW 54503,N'Página inválida.',1;
 SELECT COUNT_BIG(*) Total FROM dbo.AspNetUsers U WHERE CHARINDEX(@Busqueda,ISNULL(U.Email,N''))>0 OR @Busqueda=N'';
 SELECT U.Id,U.Email,U.EmailConfirmed,U.ConcurrencyStamp Version,ISNULL(E.Activa,1) Activa,
  CASE WHEN U.LockoutEnabled=1 AND U.LockoutEnd>SYSUTCDATETIME() THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END Bloqueada,
  (SELECT STRING_AGG(CONVERT(nvarchar(max),R.Name),N', ') FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id) Roles
 FROM dbo.AspNetUsers U LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE CHARINDEX(@Busqueda,ISNULL(U.Email,N''))>0 OR @Busqueda=N''
 ORDER BY U.Email,U.Id OFFSET (@Pagina-1)*50 ROWS FETCH NEXT 50 ROWS ONLY;
 SELECT U.Id,U.Email,U.ConcurrencyStamp Version,ISNULL(E.Activa,1) Activa,
  (SELECT STRING_AGG(CONVERT(nvarchar(max),R.Name),N', ') FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id) Roles
 FROM dbo.AspNetUsers U LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@CuentaId;
 SELECT TOP(50) H.Fecha,H.Motivo,U.UserName Responsable,H.AntesJson,H.DespuesJson
 FROM dbo.HistorialCuentaPersonal H JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId
 WHERE H.CuentaId=@CuentaId ORDER BY H.Id DESC;
END;
GO
