CREATE OR ALTER PROCEDURE dbo.Planificacion_CambiosHistorial @UsuarioId nvarchar(450),@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54301,N'Se requiere administrador.',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54302,N'Página inválida.',1;
 SELECT C.Id,C.Tipo,C.Fecha,C.Motivo,C.AntesJson,C.DespuesJson,U.UserName Responsable INTO #Historial FROM dbo.CambioPlanificacion C LEFT JOIN dbo.AspNetUsers U ON U.Id=C.UsuarioId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT Id,Tipo,DATEADD(hour,-6,Fecha) FechaLocal,Responsable,Motivo,
 CASE WHEN Tipo='Docente' THEN CONCAT(N'Asignación ',JSON_VALUE(AntesJson,'$.AsignacionId'),N' / ',JSON_VALUE(AntesJson,'$.Asignatura')) ELSE CONCAT(JSON_VALUE(AntesJson,'$.Registro'),N' / ',JSON_VALUE(AntesJson,'$.NombreEstudiante')) END Registro,
 CONCAT(JSON_VALUE(AntesJson,'$.Anio'),N' / ',JSON_VALUE(AntesJson,'$.Periodo')) Periodo,
 CASE WHEN Tipo='Docente' THEN JSON_VALUE(AntesJson,'$.Docente') ELSE CONCAT(N'Grupo ',JSON_VALUE(AntesJson,'$.GrupoId'),N' / ',JSON_VALUE(AntesJson,'$.Seccion')) END Anterior,
 CASE WHEN Tipo='Docente' THEN JSON_VALUE(DespuesJson,'$.Docente') ELSE CONCAT(N'Grupo ',JSON_VALUE(DespuesJson,'$.GrupoId'),N' / ',JSON_VALUE(DespuesJson,'$.Seccion')) END Nuevo
 FROM #Historial ORDER BY Fecha DESC,Id DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;
GO
