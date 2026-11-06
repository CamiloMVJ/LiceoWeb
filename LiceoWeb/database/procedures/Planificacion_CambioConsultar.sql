CREATE OR ALTER PROCEDURE dbo.Planificacion_CambioConsultar @UsuarioId nvarchar(450),@Tipo nvarchar(20),@OrigenId int,@Registro nvarchar(10)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54301,N'Se requiere administrador.',1;
 IF @Tipo IS NULL OR @Tipo NOT IN ('Docente','Estudiante') THROW 54302,N'Tipo de cambio inválido.',1;
 IF @Tipo='Docente'
 BEGIN
  SELECT D.Id,CONVERT(varchar(18),CONVERT(binary(8),D.Version),1) Version,CONCAT(Y.Anio,' / ',P.Nombre,' / ',N.Nivel,' ',G.Seccion,' / ',S.Nombre,' / ',U.UserName) Descripcion
   FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId WHERE D.Id=@OrigenId;
  SELECT U.Id,U.UserName Etiqueta,C.Detalle Conflicto FROM dbo.AspNetUsers U
   OUTER APPLY (
    SELECT TOP(1) CONCAT(CHOOSE(X.Dia,N'lunes',N'martes',N'miércoles',N'jueves',N'viernes',N'sábado',N'domingo'),
       N' ',CONVERT(char(5),X.Inicio,108),N'–',CONVERT(char(5),X.Fin,108),N' · ',S.Nombre,N' · ',N.Nivel,N' ',G.Seccion,N' · ',P.Nombre) Detalle
    FROM dbo.HorarioClaseVigente H JOIN dbo.HorarioClaseVigente X
     ON X.AsignacionId<>H.AsignacionId AND X.Dia=H.Dia AND X.Inicio<H.Fin AND H.Inicio<X.Fin
    JOIN dbo.AsignacionDocente D ON D.Id=X.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Pensum N ON N.Id=G.PensumId
    JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
    JOIN dbo.AsignacionDocente A ON A.Id=H.AsignacionId JOIN dbo.GrupoAcademico GA ON GA.Id=A.GrupoId
    JOIN dbo.PeriodoAcademico O ON O.Id=GA.PeriodoId
    WHERE H.AsignacionId=@OrigenId AND D.UsuarioId=U.Id AND P.Inicio<=O.Fin AND O.Inicio<=P.Fin
    ORDER BY X.Dia,X.Inicio,X.Id
   ) C
   WHERE (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND U.EmailConfirmed=1 AND NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0)
   AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id AND R.Name='Profesor')
   AND NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente D WHERE D.Id=@OrigenId AND D.UsuarioId=U.Id) ORDER BY U.UserName;
 END
 ELSE
 BEGIN
  SELECT E.GrupoId Id,CONVERT(varchar(18),CONVERT(binary(8),E.Version),1) Version,CONCAT(E.Registro,' / ',S.NombreEstudiante,' / ',Y.Anio,' / ',P.Nombre,' / ',N.Nivel,' ',G.Seccion) Descripcion
   FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro;
  SELECT G.Id,CONCAT(G.Id,' / sección ',G.Seccion,' / ',T.Nombre,' / aula ',A.Nombre,' / ocupación ',(SELECT COUNT(*) FROM dbo.GrupoEstudiante E WHERE E.GrupoId=G.Id),' de ',A.Capacidad) Etiqueta
   FROM dbo.GrupoAcademico G JOIN dbo.GrupoAcademico O ON O.Id=@OrigenId AND G.PeriodoId=O.PeriodoId AND G.PensumId=O.PensumId
   JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico T ON T.Id=G.TurnoId WHERE G.Id<>O.Id AND A.Activo=1 AND T.Activo=1 ORDER BY G.Seccion,G.Id;
 END;
END;
GO
