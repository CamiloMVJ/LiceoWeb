CREATE OR ALTER PROCEDURE dbo.Notas_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52400,N'Datos inválidos.',1;
 DECLARE @Admin bit=0,@Profesor bit=0;
 SELECT @Admin=MAX(CASE WHEN R.Name='Administrador' THEN 1 ELSE 0 END),@Profesor=MAX(CASE WHEN R.Name='Profesor' THEN 1 ELSE 0 END)
 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId;
 IF ISNULL(@Admin,0)=0 AND ISNULL(@Profesor,0)=0 THROW 52401,N'Acceso académico denegado.',1;
 DECLARE @Accion nvarchar(20)=JSON_VALUE(@Datos,'$.Accion'),@Asignacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AsignacionId')),
 @Evaluacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.EvaluacionId')),@Tipo int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.TipoId')),
 @Nombre nvarchar(100)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Nombre')),''),@Fecha date=TRY_CONVERT(date,JSON_VALUE(@Datos,'$.Fecha')),
 @Modo nvarchar(20)=JSON_VALUE(@Datos,'$.Modo'),@Maximo decimal(7,2)=TRY_CONVERT(decimal(7,2),JSON_VALUE(@Datos,'$.Maximo')),
 @Peso decimal(5,2)=TRY_CONVERT(decimal(5,2),JSON_VALUE(@Datos,'$.Peso')),@Registro nvarchar(10)=JSON_VALUE(@Datos,'$.Registro'),
 @Nota decimal(7,2)=TRY_CONVERT(decimal(7,2),JSON_VALUE(@Datos,'$.Nota')),@Resultado nvarchar(100)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Resultado')),''),
 @Observacion nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Observacion')),''),@Version binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,'$.Version'),1),
 @Motivo nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Motivo')),''),@Grupo int,@Periodo int,@Lock int,@Operacion uniqueidentifier=NEWID();
 IF @Accion IS NULL OR @Accion NOT IN ('Tipo','Evaluacion','Nota','Publicar') THROW 52400,N'Operación inválida.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Orden único con Planificacion_Guardar: evita inscripción durante publicación.
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 52402,N'La planificación está ocupada; vuelve a intentarlo.',1;
 IF @Accion='Tipo'
 BEGIN
  IF ISNULL(@Admin,0)=0 THROW 52401,N'Solo administración puede crear tipos.',1;
  IF @Nombre IS NULL THROW 52400,N'Escribe el nombre del tipo.',1;
  INSERT dbo.TipoEvaluacion(Nombre) VALUES(@Nombre);
 END
 ELSE
 BEGIN
  SELECT @Grupo=A.GrupoId,@Periodo=G.PeriodoId FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId
  WHERE A.Id=@Asignacion AND (@Admin=1 OR A.UsuarioId=@UsuarioId);
  IF @Grupo IS NULL THROW 52401,N'Asignación no disponible para tu cuenta.',1;
  IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Periodo AND Cerrado=1) THROW 52403,N'El período está cerrado.',1;
  IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion AND Vigente=1) THROW 52403,N'Las notas ya fueron publicadas; no se pueden modificar.',1;
  IF @Accion='Evaluacion'
  BEGIN
   IF @Nombre IS NULL OR @Modo IS NULL OR @Modo NOT IN ('Cuantitativa','Cualitativa') OR NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Tipo AND Activo=1) THROW 52400,N'Nombre, modalidad o tipo inválido.',1;
   IF @Fecha IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Periodo AND @Fecha BETWEEN Inicio AND Fin) THROW 52404,N'La fecha debe pertenecer al período.',1;
   IF @Modo='Cuantitativa'
   BEGIN
    IF @Maximo IS NULL OR @Maximo<=0 OR @Peso IS NULL OR @Peso<=0 OR @Peso>100 THROW 52405,N'Máximo o peso inválido.',1;
    IF @Peso+ISNULL((SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo='Cuantitativa'),0)>100 THROW 52405,N'Los pesos no pueden superar 100 %.',1;
   END
   ELSE BEGIN SET @Maximo=1;SET @Peso=0;END;
   INSERT dbo.Evaluacion(AsignacionId,TipoId,Nombre,Fecha,Maximo,Peso,Modo) VALUES(@Asignacion,@Tipo,@Nombre,@Fecha,@Maximo,@Peso,@Modo);
   SET @Evaluacion=SCOPE_IDENTITY();
   IF @Modo='Cualitativa'
   BEGIN
    DECLARE @Opciones nvarchar(max)=JSON_QUERY(@Datos,'$.Valores');
    IF @Opciones IS NULL OR LEFT(LTRIM(@Opciones),1)<>'[' THROW 52406,N'Define la escala cualitativa.',1;
    IF (SELECT COUNT(*) FROM OPENJSON(@Opciones)) NOT BETWEEN 2 AND 20 OR EXISTS(SELECT 1 FROM OPENJSON(@Opciones) WHERE type<>1 OR LEN(TRIM(value)) NOT BETWEEN 1 AND 100)
     THROW 52406,N'Define entre 2 y 20 resultados válidos.',1;
    IF EXISTS(SELECT TRIM(value) FROM OPENJSON(@Opciones) GROUP BY TRIM(value) HAVING COUNT(*)>1) THROW 52406,N'Los resultados de la escala deben ser diferentes.',1;
    INSERT dbo.OpcionEvaluacion(EvaluacionId,Valor) SELECT @Evaluacion,TRIM(value) FROM OPENJSON(@Opciones);
   END;
  END;
  IF @Accion='Nota'
  BEGIN
   SET @Modo=NULL;
   SELECT @Modo=Modo,@Maximo=Maximo FROM dbo.Evaluacion WHERE Id=@Evaluacion AND AsignacionId=@Asignacion;
   IF @Modo IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo AND Registro=@Registro) THROW 52401,N'Evaluación o estudiante ajeno al grupo.',1;
   IF @Modo='Cuantitativa' AND (@Resultado IS NOT NULL OR @Nota<0 OR @Nota>@Maximo) THROW 52407,N'La nota debe estar entre cero y el máximo de la evaluación.',1;
   IF JSON_VALUE(@Datos,'$.Nota') IS NOT NULL AND @Nota IS NULL THROW 52407,N'Nota numérica inválida.',1;
   IF @Modo='Cualitativa' AND (@Nota IS NOT NULL OR (@Resultado IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@Evaluacion AND Valor=@Resultado))) THROW 52407,N'El resultado no pertenece a la escala cualitativa.',1;
   IF EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro)
   BEGIN
    IF @Version IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro AND Version=@Version) THROW 52408,N'Otra persona modificó esta nota. Recarga antes de guardar.',1;
    IF @Motivo IS NULL THROW 52400,N'Indica el motivo de la modificación.',1;
    INSERT dbo.HistorialCalificacion(EvaluacionId,Registro,NotaAnterior,NotaNueva,ResultadoAnterior,ResultadoNuevo,ObservacionAnterior,ObservacionNueva,UsuarioId,Motivo)
     SELECT EvaluacionId,Registro,Nota,@Nota,Resultado,@Resultado,Observacion,@Observacion,@UsuarioId,@Motivo FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro;
    UPDATE dbo.Calificacion SET Nota=@Nota,Resultado=@Resultado,Observacion=@Observacion,UsuarioId=@UsuarioId WHERE EvaluacionId=@Evaluacion AND Registro=@Registro;
   END
   ELSE
   BEGIN
    IF @Version IS NOT NULL THROW 52408,N'La nota cambió. Recarga antes de guardar.',1;
    INSERT dbo.HistorialCalificacion(EvaluacionId,Registro,NotaNueva,ResultadoNuevo,ObservacionNueva,UsuarioId,Motivo)
     VALUES(@Evaluacion,@Registro,@Nota,@Resultado,@Observacion,@UsuarioId,N'Registro inicial');
    INSERT dbo.Calificacion(EvaluacionId,Registro,Nota,Resultado,Observacion,UsuarioId) VALUES(@Evaluacion,@Registro,@Nota,@Resultado,@Observacion,@UsuarioId);
   END;
  END;
  IF @Accion='Publicar'
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion) OR NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo) THROW 52409,N'Agrega evaluaciones y estudiantes antes de publicar.',1;
   IF EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo='Cuantitativa') AND (SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo='Cuantitativa')<>100 THROW 52409,N'Los pesos numéricos deben sumar exactamente 100 %.',1;
   IF EXISTS(SELECT 1 FROM dbo.Evaluacion E CROSS JOIN dbo.GrupoEstudiante G LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=G.Registro
    WHERE E.AsignacionId=@Asignacion AND G.GrupoId=@Grupo AND ((E.Modo='Cuantitativa' AND C.Nota IS NULL) OR (E.Modo='Cualitativa' AND C.Resultado IS NULL))) THROW 52409,N'Hay resultados pendientes. No se publicaron las notas.',1;
   IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion)
    UPDATE dbo.PublicacionNotas SET Vigente=1,Fecha=SYSUTCDATETIME(),UsuarioId=@UsuarioId WHERE AsignacionId=@Asignacion;
   ELSE INSERT dbo.PublicacionNotas(AsignacionId,UsuarioId) VALUES(@Asignacion,@UsuarioId);
   DECLARE @Foto nvarchar(max)=(SELECT E.Id,E.Nombre,E.Modo,E.Maximo,E.Peso,C.Registro,C.Nota,C.Resultado,C.Observacion FROM dbo.Evaluacion E JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id WHERE E.AsignacionId=@Asignacion FOR JSON PATH,INCLUDE_NULL_VALUES);
   INSERT dbo.EventoAcademico(PeriodoId,AsignacionId,Accion,UsuarioId,Motivo,Instantanea) VALUES(@Periodo,@Asignacion,N'Publicar',@UsuarioId,N'Publicación de resultados completos',@Foto);
  END;
 END;
 DECLARE @AccionAudit nvarchar(100)=N'Notas_'+@Accion,@Id nvarchar(100)=CONCAT(@Asignacion,':',@Evaluacion,':',@Registro);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N'Calificaciones',@RegistroId=@Id,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Notas_Consultar @UsuarioId nvarchar(450),@AsignacionId int=0,@EvaluacionId int=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Admin bit=0,@Profesor bit=0;
 SELECT @Admin=MAX(CASE WHEN R.Name='Administrador' THEN 1 ELSE 0 END),@Profesor=MAX(CASE WHEN R.Name='Profesor' THEN 1 ELSE 0 END)
 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId;
 IF ISNULL(@Admin,0)=0 AND ISNULL(@Profesor,0)=0 THROW 52401,N'Acceso académico denegado.',1;
 IF @AsignacionId<>0 AND NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE Id=@AsignacionId AND (@Admin=1 OR UsuarioId=@UsuarioId)) THROW 52401,N'Asignación no disponible para tu cuenta.',1;
 IF @EvaluacionId<>0 AND NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE Id=@EvaluacionId AND AsignacionId=@AsignacionId) THROW 52401,N'Evaluación ajena a la asignación.',1;
 SELECT A.Id,CONCAT(Y.Anio,' / ',P.Nombre,' / ',PS.Nivel,' ',G.Seccion,' / ',S.Nombre) Etiqueta,P.Cerrado,
 CONVERT(bit,CASE WHEN PN.AsignacionId IS NULL THEN 0 ELSE 1 END) Publicado
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId
 JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.Pensum PS ON PS.Id=G.PensumId JOIN dbo.Asignatura S ON S.Id=A.AsignaturaId
 LEFT JOIN dbo.PublicacionNotas PN ON PN.AsignacionId=A.Id AND PN.Vigente=1 WHERE @Admin=1 OR A.UsuarioId=@UsuarioId ORDER BY Y.Anio DESC,P.Nombre,PS.Nivel,G.Seccion,S.Nombre;
 SELECT Id,Nombre Etiqueta FROM dbo.TipoEvaluacion WHERE Activo=1 ORDER BY Nombre;
 SELECT E.Id,E.Nombre,E.Fecha,T.Nombre Tipo,E.Modo,E.Maximo,E.Peso FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.AsignacionId=@AsignacionId ORDER BY E.Fecha,E.Id;
 SELECT G.Registro,S.NombreEstudiante,C.Nota,C.Resultado,C.Observacion,CONVERT(varchar(18),C.Version,1) Version
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoEstudiante G ON G.GrupoId=A.GrupoId
 JOIN dbo.Estudiantes S ON S.Registro=G.Registro LEFT JOIN dbo.Calificacion C ON C.Registro=G.Registro AND C.EvaluacionId=@EvaluacionId WHERE A.Id=@AsignacionId AND @EvaluacionId<>0 ORDER BY G.Registro;
 SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId ORDER BY Valor;
 -- Pendientes se muestran explícitamente; el acumulado parcial no es una nota final.
 SELECT G.Registro,COUNT(E.Id) Evaluaciones,SUM(CASE WHEN E.Id IS NOT NULL AND ((E.Modo='Cuantitativa' AND C.Nota IS NULL) OR (E.Modo='Cualitativa' AND C.Resultado IS NULL)) THEN 1 ELSE 0 END) Pendientes,
 CAST(SUM(CASE WHEN E.Modo='Cuantitativa' THEN C.Nota/NULLIF(E.Maximo,0)*E.Peso END) AS decimal(7,2)) AcumuladoNumerico,
 SUM(CASE WHEN E.Modo='Cuantitativa' THEN E.Peso ELSE 0 END) PesoConfigurado
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoEstudiante G ON G.GrupoId=A.GrupoId LEFT JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id
 LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=G.Registro WHERE A.Id=@AsignacionId GROUP BY G.Registro ORDER BY G.Registro;
END;
GO
