CREATE OR ALTER PROCEDURE dbo.Evaluacion_ConsultarEdicion @UsuarioId nvarchar(450),@EvaluacionId int,@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId
 WHERE E.Id=@EvaluacionId AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND (R.Name='Administrador' OR (R.Name='Profesor' AND D.UsuarioId=@UsuarioId)))) THROW 54401,N'Evaluación no disponible para tu cuenta.',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54402,N'Página inválida.',1;
 SELECT E.Id,E.AsignacionId,E.TipoId,E.Nombre,E.Fecha,E.Modo,E.Maximo,E.Peso,CONVERT(varchar(18),CONVERT(binary(8),E.Version),1) Version,
 CONVERT(bit,CASE WHEN P.Cerrado=1 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=E.AsignacionId)
 OR EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=E.Id) OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion WHERE EvaluacionId=E.Id) THEN 1 ELSE 0 END) Bloqueada
 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE E.Id=@EvaluacionId;
 SELECT T.Id,T.Nombre Etiqueta FROM dbo.TipoEvaluacion T WHERE T.Activo=1 ORDER BY T.Nombre;
 SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId ORDER BY Valor;
 SELECT H.Id,H.Fecha,H.Motivo,H.AntesJson,H.DespuesJson,U.UserName Responsable INTO #Historial FROM dbo.HistorialEvaluacion H LEFT JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId WHERE H.EvaluacionId=@EvaluacionId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT DATEADD(hour,-6,Fecha) FechaLocal,Motivo,AntesJson,DespuesJson,Responsable FROM #Historial ORDER BY Id DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;
GO
