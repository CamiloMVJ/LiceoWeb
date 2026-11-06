CREATE OR ALTER PROCEDURE dbo.Planificacion_Cambiar
 @UsuarioId nvarchar(450),@Tipo nvarchar(20),@OrigenId int,@Registro nvarchar(10)=NULL,
 @DocenteId nvarchar(450)=NULL,@GrupoDestino int=NULL,@Version varchar(max)=NULL,
 @Operacion uniqueidentifier=NULL,@Motivo nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54301,N'Se requiere administrador.',1;
 SET @Motivo=NULLIF(LTRIM(RTRIM(@Motivo)),N'');
 IF @Tipo IS NULL OR @Tipo NOT IN ('Docente','Estudiante') OR @OrigenId IS NULL OR @OrigenId<=0
 OR @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>'0x' OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54302,N'Complete la operación, versión y motivo de 10 a 500 caracteres.',1;
 IF (@Tipo='Docente' AND (@DocenteId IS NULL OR @Registro IS NOT NULL OR @GrupoDestino IS NOT NULL))
 OR (@Tipo='Estudiante' AND (@Registro IS NULL OR @GrupoDestino IS NULL OR @GrupoDestino<=0 OR @DocenteId IS NOT NULL))
 THROW 54302,N'Datos de destino inválidos.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @Tipo Tipo,@OrigenId OrigenId,@Registro Registro,@DocenteId DocenteId,@GrupoDestino GrupoDestino,CONVERT(varchar(18),CONVERT(binary(8),@Version,1),1) Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Lock int,@Actual binary(8),@Periodo int,@Pensum int,@Cerrado bit,@Antes nvarchar(max),@Despues nvarchar(max);
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @Tipo='Estudiante'
  BEGIN
   EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
   IF @Lock<0 THROW 54303,N'Finanzas ocupada. Intente nuevamente.',1;
  END;
  EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Lock<0 THROW 54303,N'Planificación ocupada. Intente nuevamente.',1;
  IF EXISTS(SELECT 1 FROM dbo.CambioPlanificacion WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.CambioPlanificacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 54304,N'La operación ya se utilizó con otros datos.',1;
   COMMIT;RETURN;
  END;
  IF @Tipo='Docente'
  BEGIN
   DECLARE @AnteriorDocente nvarchar(450);
   SELECT @Actual=D.Version,@AnteriorDocente=D.UsuarioId,@Periodo=G.PeriodoId,@Cerrado=P.Cerrado
   FROM dbo.AsignacionDocente D WITH(UPDLOCK,HOLDLOCK) JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@OrigenId;
   IF @Actual IS NULL THROW 54305,N'La asignación no existe.',1;
   IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54306,N'La asignación cambió. Recargue antes de confirmar.',1;
   IF @Cerrado=1 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@OrigenId) THROW 54307,N'No se permite cambiar docente en períodos cerrados o asignaturas con publicaciones.',1;
   IF @AnteriorDocente=@DocenteId THROW 54302,N'Seleccione un docente diferente.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE U.Id=@DocenteId AND R.Name='Profesor' AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND U.EmailConfirmed=1 AND NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0)) THROW 54308,N'El destino debe ser una cuenta Profesor habilitada.',1;
   DECLARE @CruceNuevoDocente nvarchar(1000);
   SELECT TOP(1) @CruceNuevoDocente=CONCAT(CHOOSE(X.Dia,N'lunes',N'martes',N'miércoles',N'jueves',N'viernes',N'sábado',N'domingo'),
       N' ',CONVERT(char(5),X.Inicio,108),N'–',CONVERT(char(5),X.Fin,108),N' · ',S.Nombre,N' · ',N.Nivel,N' ',G.Seccion,N' · ',P.Nombre)
    FROM dbo.HorarioClaseVigente H JOIN dbo.HorarioClaseVigente X
     ON X.AsignacionId<>H.AsignacionId AND X.Dia=H.Dia AND X.Inicio<H.Fin AND H.Inicio<X.Fin
    JOIN dbo.AsignacionDocente D ON D.Id=X.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Pensum N ON N.Id=G.PensumId
    JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
    JOIN dbo.AsignacionDocente A ON A.Id=H.AsignacionId JOIN dbo.GrupoAcademico GA ON GA.Id=A.GrupoId
    JOIN dbo.PeriodoAcademico O ON O.Id=GA.PeriodoId
    WHERE H.AsignacionId=@OrigenId AND D.UsuarioId=@DocenteId AND P.Inicio<=O.Fin AND O.Inicio<=P.Fin
    ORDER BY X.Dia,X.Inicio,X.Id;
   IF @CruceNuevoDocente IS NOT NULL
   BEGIN
    DECLARE @MensajeCruceDocente nvarchar(2048)=CONCAT(N'No se puede asignar al docente: ya tiene clase el ',@CruceNuevoDocente,N'.');
    THROW 54309,@MensajeCruceDocente,1;
   END;
   SELECT @Antes=(SELECT D.Id AsignacionId,D.GrupoId,S.Nombre Asignatura,G.Seccion,D.UsuarioId DocenteId,U.UserName Docente,P.Nombre Periodo,Y.Anio
    FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE D.Id=@OrigenId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   UPDATE dbo.AsignacionDocente SET UsuarioId=@DocenteId WHERE Id=@OrigenId;
   -- Invalidar confirmaciones de cancelación abiertas con el docente anterior.
   UPDATE H SET AsignacionId=H.AsignacionId FROM dbo.HorarioClase H WHERE H.AsignacionId=@OrigenId AND NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario C WHERE C.HorarioId=H.Id);
   SET @Despues=JSON_MODIFY(JSON_MODIFY(@Antes,'$.DocenteId',@DocenteId),'$.Docente',(SELECT UserName FROM dbo.AspNetUsers WHERE Id=@DocenteId));
  END
  ELSE
  BEGIN
   SELECT @Actual=E.Version,@Periodo=G.PeriodoId,@Pensum=G.PensumId,@Cerrado=P.Cerrado FROM dbo.GrupoEstudiante E WITH(UPDLOCK,HOLDLOCK)
    JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro;
   IF @Actual IS NULL THROW 54305,N'El estudiante ya no pertenece al grupo de origen.',1;
   IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54306,N'La inscripción cambió. Recargue antes de confirmar.',1;
   IF @Cerrado=1 THROW 54307,N'El período está cerrado.',1;
   IF @GrupoDestino=@OrigenId THROW 54302,N'Seleccione otro grupo.',1;
   DECLARE @Capacidad int,@Anio int,@Modalidad nvarchar(80),@Nivel nvarchar(50);
   SELECT @Capacidad=A.Capacidad,@Anio=Y.Anio,@Modalidad=M.Nombre,@Nivel=N.Nivel FROM dbo.GrupoAcademico G
    JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=N.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=N.ModalidadId JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico T ON T.Id=G.TurnoId
    WHERE G.Id=@GrupoDestino AND G.PeriodoId=@Periodo AND G.PensumId=@Pensum AND Y.Activo=1 AND M.Activo=1 AND A.Activo=1 AND T.Activo=1;
   IF @Capacidad IS NULL THROW 54310,N'El destino debe tener el mismo pensum y período y catálogos activos.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro AND Estado='Activo' AND Modalidad=@Modalidad AND Grado=@Nivel) THROW 54310,N'Revise el estado, modalidad y nivel del expediente.',1;
   IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
   BEGIN
    IF NOT EXISTS(SELECT 1 FROM dbo.MatriculaAcademica WHERE Registro=@Registro AND Anio=@Anio AND Modalidad=@Modalidad AND Nivel=@Nivel) THROW 54310,N'Falta la matrícula académica compatible del año.',1;
   END
   ELSE IF NOT EXISTS(SELECT 1 FROM dbo.Matriculas WHERE Registro_Estudiante=@Registro AND Anio=@Anio AND Modalidad=@Modalidad AND Grado=@Nivel) THROW 54310,N'Falta la matrícula histórica compatible del año.',1;
   IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas P JOIN dbo.AsignacionDocente D ON D.Id=P.AsignacionId WHERE D.GrupoId IN (@OrigenId,@GrupoDestino)) THROW 54307,N'Uno de los grupos tiene publicaciones. Requiere revisión académica; no se trasladará automáticamente.',1;
   IF EXISTS(SELECT 1 FROM dbo.Calificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId WHERE C.Registro=@Registro AND D.GrupoId IN (@OrigenId,@GrupoDestino))
    OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId WHERE C.Registro=@Registro AND D.GrupoId IN (@OrigenId,@GrupoDestino))
    THROW 54311,N'El estudiante tiene registros de calificaciones en origen o destino. No se moverán ni borrarán sus notas.',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoEstudiante E JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId WHERE E.Registro=@Registro AND G.PeriodoId=@Periodo AND E.GrupoId<>@OrigenId) THROW 54310,N'El estudiante ya tiene otra inscripción en este período.',1;
   IF (SELECT COUNT(*) FROM dbo.GrupoEstudiante WHERE GrupoId=@GrupoDestino)>=@Capacidad THROW 54312,N'El grupo de destino no tiene cupo disponible.',1;
   SELECT @Antes=(SELECT E.Registro,S.NombreEstudiante,E.GrupoId,G.Seccion,P.Nombre Periodo,Y.Anio FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro
    JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   UPDATE dbo.GrupoEstudiante SET GrupoId=@GrupoDestino WHERE GrupoId=@OrigenId AND Registro=@Registro;
   SET @Despues=JSON_MODIFY(JSON_MODIFY(@Antes,'$.GrupoId',@GrupoDestino),'$.Seccion',(SELECT Seccion FROM dbo.GrupoAcademico WHERE Id=@GrupoDestino));
  END;
  INSERT dbo.CambioPlanificacion(Operacion,SolicitudHash,Tipo,OrigenId,UsuarioId,Motivo,AntesJson,DespuesJson) VALUES(@Operacion,@Hash,@Tipo,@OrigenId,@UsuarioId,@Motivo,@Antes,@Despues);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),SCOPE_IDENTITY()),@Accion nvarchar(50)=CASE WHEN @Tipo='Docente' THEN N'ReasignarDocente' ELSE N'TrasladarEstudiante' END;
  EXEC dbo.Registrar_Auditoria @UsuarioId,@Accion,N'CambioPlanificacion',@Id,@Operacion,@Antes,@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
