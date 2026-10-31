CREATE OR ALTER PROCEDURE dbo.CierreAcademico_Guardar @UsuarioId nvarchar(450),@Accion nvarchar(30),@PeriodoId int,@AsignacionId int=0,@Version varchar(18),@Motivo nvarchar(500)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52601,N'Solo administración puede realizar esta operación.',1;
 IF @Accion IS NULL OR @Accion NOT IN ('CerrarPeriodo','ReabrirPeriodo','ReabrirAsignacion') OR NULLIF(TRIM(@Motivo),'') IS NULL THROW 52600,N'Operación o motivo inválido.',1;
 DECLARE @Token binary(8)=TRY_CONVERT(binary(8),@Version,1),@Lock int,@Foto nvarchar(max),@Operacion uniqueidentifier=NEWID(),@RegistroId nvarchar(100)=CONCAT(@PeriodoId,':',@AsignacionId);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 52602,N'Hay otra operación académica en curso; vuelve a intentarlo.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId) THROW 52600,N'Período inexistente.',1;
 IF @Accion='ReabrirAsignacion'
 BEGIN
  IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=1) THROW 52603,N'Primero reabre el período.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.PublicacionNotas N JOIN dbo.AsignacionDocente A ON A.Id=N.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId WHERE A.Id=@AsignacionId AND G.PeriodoId=@PeriodoId AND N.Vigente=1 AND N.Version=@Token)
   THROW 52604,N'La publicación cambió o ya no está vigente. Recarga la página.',1;
  UPDATE dbo.PublicacionNotas SET Vigente=0 WHERE AsignacionId=@AsignacionId;
 END
 ELSE
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Version=@Token) THROW 52604,N'El período cambió. Recarga la página.',1;
  IF @Accion='ReabrirPeriodo'
  BEGIN
   IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=0) THROW 52603,N'El período ya está abierto.',1;
   UPDATE dbo.PeriodoAcademico SET Cerrado=0 WHERE Id=@PeriodoId;
  END
  ELSE
  BEGIN
   IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=1) THROW 52603,N'El período ya está cerrado.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PeriodoId=@PeriodoId) THROW 52605,N'El período no tiene grupos.',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico G WHERE G.PeriodoId=@PeriodoId AND (NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante GE WHERE GE.GrupoId=G.Id) OR NOT EXISTS(SELECT 1 FROM dbo.PensumAsignatura PA WHERE PA.PensumId=G.PensumId))) THROW 52605,N'Hay grupos sin estudiantes o sin materias.',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PensumAsignatura PA ON PA.PensumId=G.PensumId LEFT JOIN dbo.AsignacionDocente A ON A.GrupoId=G.Id AND A.AsignaturaId=PA.AsignaturaId WHERE G.PeriodoId=@PeriodoId AND A.Id IS NULL) THROW 52605,N'Faltan docentes asignados a materias del pensum.',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId LEFT JOIN dbo.PublicacionNotas N ON N.AsignacionId=A.Id AND N.Vigente=1 WHERE G.PeriodoId=@PeriodoId AND N.AsignacionId IS NULL) THROW 52605,N'Hay asignaturas sin publicación vigente.',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId WHERE G.PeriodoId=@PeriodoId AND (NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id) OR (EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id AND E.Modo='Cuantitativa') AND (SELECT SUM(E.Peso) FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id AND E.Modo='Cuantitativa')<>100))) THROW 52605,N'Hay evaluaciones o pesos incompletos.',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.GrupoEstudiante GE ON GE.GrupoId=G.Id JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=GE.Registro WHERE G.PeriodoId=@PeriodoId AND ((E.Modo='Cuantitativa' AND (C.Nota IS NULL OR C.Nota<0 OR C.Nota>E.Maximo)) OR (E.Modo='Cualitativa' AND (C.Resultado IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.OpcionEvaluacion O WHERE O.EvaluacionId=E.Id AND O.Valor=C.Resultado))))) THROW 52605,N'Hay calificaciones pendientes o inválidas.',1;
   UPDATE dbo.PeriodoAcademico SET Cerrado=1 WHERE Id=@PeriodoId;
  END;
 END;
 -- Instantánea de resultados que permite revisar cada cierre/reapertura sin depender del estado posterior.
 SET @Foto=(SELECT A.Id AsignacionId,E.Id EvaluacionId,E.Nombre,E.Modo,E.Maximo,E.Peso,C.Registro,C.Nota,C.Resultado,C.Observacion
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id
 WHERE G.PeriodoId=@PeriodoId AND (@Accion<>'ReabrirAsignacion' OR A.Id=@AsignacionId) FOR JSON PATH,INCLUDE_NULL_VALUES);
 INSERT dbo.EventoAcademico(PeriodoId,AsignacionId,Accion,UsuarioId,Motivo,Instantanea) VALUES(@PeriodoId,CASE WHEN @Accion='ReabrirAsignacion' THEN @AsignacionId END,@Accion,@UsuarioId,TRIM(@Motivo),@Foto);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@Accion,@Entidad=N'PeriodoAcademico',@RegistroId=@RegistroId,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CierreAcademico_Consultar @UsuarioId nvarchar(450),@PeriodoId int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52601,N'Solo administración puede consultar este historial.',1;
 SELECT P.Id,CONCAT(A.Anio,' / ',P.Nombre) Etiqueta,P.Cerrado,CONVERT(varchar(18),P.Version,1) Version FROM dbo.PeriodoAcademico P JOIN dbo.AnioLectivo A ON A.Id=P.AnioId ORDER BY A.Anio DESC,P.Inicio;
 SELECT A.Id,CONCAT(P.Nivel,' ',G.Seccion,' / ',S.Nombre) Etiqueta,ISNULL(N.Vigente,0) Publicado,CONVERT(varchar(18),N.Version,1) Version
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.Asignatura S ON S.Id=A.AsignaturaId LEFT JOIN dbo.PublicacionNotas N ON N.AsignacionId=A.Id WHERE G.PeriodoId=@PeriodoId ORDER BY P.Nivel,G.Seccion,S.Nombre;
 SELECT TOP(200) H.Id,H.Fecha,E.Nombre Evaluacion,H.Registro,H.NotaAnterior,H.NotaNueva,H.ResultadoAnterior,H.ResultadoNuevo,H.ObservacionAnterior,H.ObservacionNueva,H.Motivo,U.UserName Responsable FROM dbo.HistorialCalificacion H JOIN dbo.Evaluacion E ON E.Id=H.EvaluacionId JOIN dbo.AsignacionDocente A ON A.Id=E.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId WHERE G.PeriodoId=@PeriodoId ORDER BY H.Id DESC;
 SELECT TOP(200) E.Id,E.Fecha,E.AsignacionId,E.Accion,E.Motivo,U.UserName Responsable FROM dbo.EventoAcademico E JOIN dbo.AspNetUsers U ON U.Id=E.UsuarioId WHERE E.PeriodoId=@PeriodoId ORDER BY E.Id DESC;
END;
GO
