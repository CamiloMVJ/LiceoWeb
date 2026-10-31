-- SOLO base de desarrollo sin actividad concurrente. Cada escenario revierte sus datos.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 52500,N'Use desarrollo, sin transacciones abiertas.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
DECLARE @Docente nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Profesor');
DECLARE @Registro nvarchar(10)=(SELECT TOP(1) Registro FROM dbo.Estudiantes ORDER BY Registro);
IF @Admin IS NULL OR @Docente IS NULL OR @Registro IS NULL THROW 52500,N'Requiere administrador, profesor y un estudiante existente de prueba.',1;
DECLARE @Caso int=1,@Esperado int,@Error int,@Json nvarchar(max),@A int,@M int,@T int,@S int,@Aula int,@P int,@Pensum int,@Grupo int,@Asignacion int,@Tipo int,@Eval int,@Version varchar(18);
DECLARE @Antes int=(SELECT COUNT(*) FROM dbo.Evaluacion);
WHILE @Caso<=7
BEGIN
 DECLARE @Etiqueta nvarchar(30)=N'NOTAS-'+LEFT(CONVERT(nvarchar(36),NEWID()),8),@AnioNumero int=2098;
 WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@AnioNumero) SET @AnioNumero=@AnioNumero-1;
 SET @Esperado=CASE @Caso WHEN 1 THEN 0 WHEN 2 THEN 52407 WHEN 3 THEN 52405 WHEN 4 THEN 52408 WHEN 5 THEN 52409 WHEN 6 THEN 52403 WHEN 7 THEN 52407 END;
 SET @Error=0;
 BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.AnioLectivo(Anio) VALUES(@AnioNumero);SET @A=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.ModalidadAcademica(Nombre) VALUES(@Etiqueta);SET @M=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.TurnoAcademico(Nombre) VALUES(@Etiqueta);SET @T=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(@Etiqueta,N'Prueba',20);SET @Aula=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.Asignatura(Codigo,Nombre) VALUES(@Etiqueta,@Etiqueta);SET @S=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin) VALUES(@A,@Etiqueta,DATEFROMPARTS(@AnioNumero,1,1),DATEFROMPARTS(@AnioNumero,6,30));SET @P=CONVERT(int,SCOPE_IDENTITY());
 SET @Json=(SELECT 'Pensum' Accion,@A AnioId,@M ModalidadId,'1er Grado' Nivel FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 SELECT @Pensum=Id FROM dbo.Pensum WHERE AnioId=@A AND ModalidadId=@M;
 SET @Json=(SELECT 'Materia' Accion,@Pensum PensumId,@S AsignaturaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 SET @Json=(SELECT 'Grupo' Accion,@Pensum PensumId,@P PeriodoId,@T TurnoId,@Aula AulaId,'A' Seccion FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 SELECT @Grupo=Id FROM dbo.GrupoAcademico WHERE PensumId=@Pensum;
 SET @Json=(SELECT 'Docente' Accion,@Grupo GrupoId,@S AsignaturaId,@Docente DocenteId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 SELECT @Asignacion=Id FROM dbo.AsignacionDocente WHERE GrupoId=@Grupo;

 INSERT dbo.GrupoEstudiante(GrupoId,Registro) VALUES(@Grupo,@Registro);
 INSERT dbo.TipoEvaluacion(Nombre) VALUES(@Etiqueta);SET @Tipo=CONVERT(int,SCOPE_IDENTITY());
 SET @Json=(SELECT 'Evaluacion' Accion,@Asignacion AsignacionId,@Tipo TipoId,@Etiqueta Nombre,DATEFROMPARTS(@AnioNumero,3,1) Fecha,'Cuantitativa' Modo,30 Maximo,100 Peso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Notas_Guardar @Json,@Docente;
 SELECT @Eval=Id FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion;
 IF @Caso=3 EXEC dbo.Notas_Guardar @Json,@Docente; -- Peso acumulado 200, debe fallar.
 IF @Caso=5
 BEGIN
  SET @Json=(SELECT 'Publicar' Accion,@Asignacion AsignacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Notas_Guardar @Json,@Docente; -- Falta resultado.
 END;
 SET @Json=(SELECT 'Nota' Accion,@Asignacion AsignacionId,@Eval EvaluacionId,@Registro Registro,CASE WHEN @Caso=2 THEN 31 ELSE 0 END Nota FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Notas_Guardar @Json,@Docente;
 IF NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Eval AND Registro=@Registro AND Nota=0) THROW 52501,N'No se guardó cero.',1;
 SELECT @Version=CONVERT(varchar(18),Version,1) FROM dbo.Calificacion WHERE EvaluacionId=@Eval AND Registro=@Registro;
 IF @Caso=4 EXEC dbo.Notas_Guardar @Json,@Docente; -- Token ausente sobre nota existente.
 SET @Json=JSON_MODIFY(JSON_MODIFY(@Json,'$.Version',@Version),'$.Nota',15);
 EXEC dbo.Notas_Guardar @Json,@Docente;
 IF (SELECT C.Nota/E.Maximo*E.Peso FROM dbo.Calificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId WHERE E.Id=@Eval AND C.Registro=@Registro)<>50 THROW 52501,N'Cálculo ponderado incorrecto.',1;
 IF @Caso IN (1,7)
 BEGIN
  SET @Json=(SELECT 'Evaluacion' Accion,@Asignacion AsignacionId,@Tipo TipoId,'Desempeño' Nombre,DATEFROMPARTS(@AnioNumero,3,1) Fecha,'Cualitativa' Modo,JSON_QUERY(N'["Logrado","En proceso"]') Valores FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Notas_Guardar @Json,@Docente;
  SELECT @Eval=Id FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo='Cualitativa';
  SET @Json=(SELECT 'Nota' Accion,@Asignacion AsignacionId,@Eval EvaluacionId,@Registro Registro,CASE WHEN @Caso=7 THEN 'Ajeno' ELSE 'Logrado' END Resultado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Notas_Guardar @Json,@Docente;
 END;
 SET @Json=(SELECT 'Publicar' Accion,@Asignacion AsignacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Notas_Guardar @Json,@Docente;
 IF NOT EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion) THROW 52501,N'Publicación ausente.',1;
 IF @Caso=6 EXEC dbo.Notas_Guardar @Json,@Docente; -- Publicación ya bloqueada.
 ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Error=ERROR_NUMBER();
  IF XACT_STATE()<>0 ROLLBACK;
  IF @Error<>@Esperado THROW;
 END CATCH;
 IF @Error<>@Esperado THROW 52501,N'No se rechazó un caso inválido.',1;
 IF (SELECT COUNT(*) FROM dbo.Evaluacion)<>@Antes THROW 52501,N'La prueba no revirtió sus datos.',1;
 SELECT @Caso Caso,N'Correcto; datos revertidos' Resultado;
 SET @Caso+=1;
END;
