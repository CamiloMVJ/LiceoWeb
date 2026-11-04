CREATE OR ALTER PROCEDURE dbo.TipoEvaluacion_Consultar
 @UsuarioId nvarchar(450),@Id int=0,@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND R.Name='Administrador')
 OR EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
 THROW 54601,N'Acceso exclusivo de administración activa.',1;
 IF @Id<0 OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54602,N'Consulta inválida.',1;
 SELECT T.Id,T.Nombre,T.Activo,CONVERT(varchar(18),CONVERT(binary(8),T.Version),1) Version,
 CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.TipoId=T.Id) THEN 1 ELSE 0 END) Utilizado
 FROM dbo.TipoEvaluacion T ORDER BY T.Nombre,T.Id;
 SELECT COUNT_BIG(*) Total FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id;
 SELECT Id,Fecha,UsuarioId,Motivo,NombreAnterior,NombreNuevo,ActivoAnterior,ActivoNuevo
 FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id ORDER BY Id DESC
 OFFSET (@Pagina-1)*25 ROWS FETCH NEXT 25 ROWS ONLY;
END;
GO
