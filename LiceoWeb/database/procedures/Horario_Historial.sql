CREATE OR ALTER PROCEDURE dbo.Horario_Historial @UsuarioId nvarchar(450),@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54201,N'Se requiere administrador.',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54202,N'Página inválida.',1;
 -- Una consulta para el total y la página: conservar la misma instantánea.
 SELECT C.HorarioId,C.Fecha,C.Motivo,U.UserName Responsable,C.Instantanea INTO #Historial
 FROM dbo.CancelacionHorario C LEFT JOIN dbo.AspNetUsers U ON U.Id=C.UsuarioId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT HorarioId,DATEADD(hour,-6,Fecha) FechaLocal,Motivo,Responsable,
 JSON_VALUE(Instantanea,'$.Anio') Anio,JSON_VALUE(Instantanea,'$.Periodo') Periodo,
 JSON_VALUE(Instantanea,'$.Seccion') Seccion,JSON_VALUE(Instantanea,'$.Asignatura') Asignatura,
 JSON_VALUE(Instantanea,'$.Docente') Docente,JSON_VALUE(Instantanea,'$.Aula') Aula,
 JSON_VALUE(Instantanea,'$.Dia') Dia,JSON_VALUE(Instantanea,'$.Inicio') Inicio,JSON_VALUE(Instantanea,'$.Fin') Fin
 FROM #Historial ORDER BY Fecha DESC,HorarioId DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;
GO
