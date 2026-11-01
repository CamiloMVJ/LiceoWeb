CREATE OR ALTER PROCEDURE dbo.Horario_Consultar @UsuarioId nvarchar(450),@HorarioId int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54201,N'Se requiere administrador.',1;
 SELECT H.Id,CONVERT(varchar(18),H.Version,1) Version,Y.Anio,P.Nombre Periodo,P.Cerrado,G.Seccion,
 S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin,
 CONVERT(bit,CASE WHEN C.HorarioId IS NULL THEN 0 ELSE 1 END) Cancelado
 FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId
 JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId
 LEFT JOIN dbo.CancelacionHorario C ON C.HorarioId=H.Id WHERE H.Id=@HorarioId;
END;
GO
