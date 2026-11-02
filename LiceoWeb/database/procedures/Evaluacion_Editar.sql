CREATE OR ALTER PROCEDURE dbo.Evaluacion_Editar @UsuarioId nvarchar(450),@EvaluacionId int,@Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max),@Datos nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 OR @Datos IS NULL THROW 54402,N'Definición inválida.',1;
 SET @Motivo=NULLIF(TRIM(@Motivo),N'');
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000' OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>'0x' OR TRY_CONVERT(binary(8),@Version,1) IS NULL THROW 54402,N'Indica operación, versión y motivo de 10 a 500 caracteres.',1;
 DECLARE @Tipo int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.TipoId')),@Nombre nvarchar(max)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Nombre')),''),
 @Fecha date=TRY_CONVERT(date,JSON_VALUE(@Datos,'$.Fecha')),@Modo nvarchar(20)=JSON_VALUE(@Datos,'$.Modo'),
 @Maximo decimal(28,10)=TRY_CONVERT(decimal(28,10),JSON_VALUE(@Datos,'$.Maximo')),@Peso decimal(28,10)=TRY_CONVERT(decimal(28,10),JSON_VALUE(@Datos,'$.Peso')),
 @Valores nvarchar(max)=JSON_QUERY(@Datos,'$.Valores'),@Lock int,@Asignacion int,@Actual binary(8),@Antes nvarchar(max),@Despues nvarchar(max);
 IF @Nombre IS NULL OR LEN(@Nombre)>100 OR @Fecha IS NULL OR @Tipo IS NULL OR @Modo IS NULL OR @Modo NOT IN ('Cuantitativa','Cualitativa') THROW 54402,N'Revisa nombre, tipo, fecha y modalidad.',1;
 IF @Modo='Cuantitativa'
 BEGIN
  IF @Maximo IS NULL OR @Maximo<=0 OR @Maximo>99999.99 OR ROUND(@Maximo,2)<>@Maximo OR @Peso IS NULL OR @Peso<=0 OR @Peso>100 OR ROUND(@Peso,2)<>@Peso THROW 54402,N'Puntos y peso positivos, con hasta dos decimales; peso máximo 100%.',1;
  SET @Valores=N'[]';
 END
 ELSE
 BEGIN
  SET @Maximo=1;SET @Peso=0;
  IF @Valores IS NULL OR LEFT(LTRIM(@Valores),1)<>'[' THROW 54402,N'Define la escala cualitativa.',1;
  IF (SELECT COUNT(*) FROM OPENJSON(@Valores)) NOT BETWEEN 2 AND 20 OR EXISTS(SELECT 1 FROM OPENJSON(@Valores) WHERE type<>1 OR LEN(TRIM(value)) NOT BETWEEN 1 AND 100)
   OR EXISTS(SELECT TRIM(value) FROM OPENJSON(@Valores) GROUP BY TRIM(value) HAVING COUNT(*)>1) THROW 54402,N'Define de 2 a 20 resultados diferentes de hasta 100 caracteres.',1;
 END;
 DECLARE @Solicitud nvarchar(max)=(SELECT @EvaluacionId EvaluacionId,@Tipo TipoId,@Nombre Nombre,@Fecha Fecha,@Modo Modo,@Maximo Maximo,@Peso Peso,JSON_QUERY(@Valores) Valores,@Version Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54403,N'La planificación está ocupada. Reintenta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId
 WHERE E.Id=@EvaluacionId AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND (R.Name='Administrador' OR (R.Name='Profesor' AND D.UsuarioId=@UsuarioId)))) THROW 54401,N'Evaluación no disponible para tu cuenta.',1;
 IF EXISTS(SELECT 1 FROM dbo.HistorialEvaluacion WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.HistorialEvaluacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 54404,N'La operación ya se utilizó con otros datos.',1;
  COMMIT;RETURN;
 END;
 SELECT @Asignacion=AsignacionId,@Actual=Version FROM dbo.Evaluacion WITH(UPDLOCK,HOLDLOCK) WHERE Id=@EvaluacionId;
 IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54405,N'Otra persona cambió la evaluación. Recarga antes de guardar.',1;
 IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND P.Cerrado=1)
 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion) THROW 54406,N'No se puede editar una definición de un período cerrado o una asignatura con publicaciones.',1;
 IF EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@EvaluacionId) OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion WHERE EvaluacionId=@EvaluacionId) THROW 54407,N'La evaluación tiene registros de calificaciones. Se conserva su definición.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Tipo AND Activo=1) THROW 54402,N'Selecciona un tipo de evaluación activo.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND @Fecha BETWEEN P.Inicio AND P.Fin) THROW 54402,N'La fecha debe estar dentro del período.',1;
 IF @Modo='Cuantitativa' AND @Peso+ISNULL((SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Id<>@EvaluacionId AND Modo='Cuantitativa'),0)>100 THROW 54408,N'Los pesos de la asignatura no pueden superar 100%.',1;
 SET @Antes=(SELECT E.Nombre,T.Nombre Tipo,E.TipoId,E.Fecha,E.Modo,E.Maximo,E.Peso,
 JSON_QUERY((SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=E.Id ORDER BY Valor FOR JSON PATH)) Valores
 FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.Id=@EvaluacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 UPDATE dbo.Evaluacion SET TipoId=@Tipo,Nombre=@Nombre,Fecha=@Fecha,Modo=@Modo,Maximo=@Maximo,Peso=@Peso WHERE Id=@EvaluacionId;
 DELETE dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId;
 IF @Modo='Cualitativa' INSERT dbo.OpcionEvaluacion(EvaluacionId,Valor) SELECT @EvaluacionId,TRIM(value) FROM OPENJSON(@Valores);
 SET @Despues=(SELECT E.Nombre,T.Nombre Tipo,E.TipoId,E.Fecha,E.Modo,E.Maximo,E.Peso,
 JSON_QUERY((SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=E.Id ORDER BY Valor FOR JSON PATH)) Valores
 FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.Id=@EvaluacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT dbo.HistorialEvaluacion(EvaluacionId,Operacion,SolicitudHash,UsuarioId,Motivo,AntesJson,DespuesJson) VALUES(@EvaluacionId,@Operacion,@Hash,@UsuarioId,@Motivo,@Antes,@Despues);
 DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@EvaluacionId);
 EXEC dbo.Registrar_Auditoria @UsuarioId,N'EditarEvaluacion',N'Evaluacion',@Id,@Operacion,@Antes,@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
