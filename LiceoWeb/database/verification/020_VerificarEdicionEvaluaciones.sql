-- Solo copia de desarrollo sin actividad concurrente. Requiere 020 y Notas.sql actualizado.
-- Cada escenario revierte datos; secuencias/identidades/versiones pueden avanzar.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 52500,N'Use desarrollo, sin transacciones abiertas.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
DECLARE @Docente nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Profesor' AND NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles X JOIN dbo.AspNetRoles Y ON Y.Id=X.RoleId WHERE X.UserId=U.UserId AND Y.Name='Administrador'));
DECLARE @Registro nvarchar(10)=(SELECT TOP(1) Registro FROM dbo.Estudiantes ORDER BY Registro);
IF @Admin IS NULL OR @Docente IS NULL OR @Registro IS NULL THROW 52500,N'Requiere administrador, profesor y un estudiante existente de prueba.',1;
DECLARE @Caso int=1,@Esperado int,@Error int,@Json nvarchar(max),@A int,@M int,@T int,@S int,@Aula int,@P int,@Pensum int,@Grupo int,@Asignacion int,@Tipo int,@Eval int,@Version varchar(18);
DECLARE @Op uniqueidentifier,@Motivo nvarchar(500)=N'Corregir definición de prueba',@Edicion nvarchar(max),@Token varchar(18);
DECLARE @Antes int=(SELECT COUNT(*) FROM dbo.Evaluacion);
WHILE @Caso<=11
BEGIN
 DECLARE @Etiqueta nvarchar(30)=N'EDITAR-'+LEFT(CONVERT(nvarchar(36),NEWID()),8),@AnioNumero int=2098;
 WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@AnioNumero) SET @AnioNumero-=1;
 SET @Esperado=CASE @Caso WHEN 1 THEN 0 WHEN 2 THEN 54407 WHEN 3 THEN 54407 WHEN 4 THEN 54406 WHEN 5 THEN 54406 WHEN 6 THEN 54405 WHEN 7 THEN 54408 WHEN 8 THEN 52408 WHEN 9 THEN 54401 WHEN 10 THEN 0 WHEN 11 THEN 54404 END;
 SET @Error=0;SET @Op=NEWID();
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
 SET @Json=(SELECT 'Evaluacion' Accion,@Asignacion AsignacionId,@Tipo TipoId,@Etiqueta Nombre,DATEFROMPARTS(@AnioNumero,3,1) Fecha,'Cuantitativa' Modo,30 Maximo,60 Peso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Notas_Guardar @Json,@Docente;
 SELECT @Eval=Id FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion;

 SELECT @Token=CONVERT(varchar(18),Version,1) FROM dbo.Evaluacion WHERE Id=@Eval;
 SET @Edicion=(SELECT @Tipo TipoId,N'Examen corregido' Nombre,DATEFROMPARTS(@AnioNumero,3,2) Fecha,N'Cuantitativa' Modo,70 Maximo,70 Peso,JSON_QUERY(N'[]') Valores FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 IF @Caso=2 INSERT dbo.Calificacion(EvaluacionId,Registro,UsuarioId) VALUES(@Eval,@Registro,@Docente);
 IF @Caso=3 INSERT dbo.HistorialCalificacion(EvaluacionId,Registro,UsuarioId,Motivo) VALUES(@Eval,@Registro,@Docente,N'Historial previo de prueba');
 IF @Caso=4 INSERT dbo.PublicacionNotas(AsignacionId,UsuarioId,Vigente) VALUES(@Asignacion,@Docente,0);
 IF @Caso=5 UPDATE dbo.PeriodoAcademico SET Cerrado=1 WHERE Id=@P;
 IF @Caso=6 UPDATE dbo.Evaluacion SET Nombre=Nombre WHERE Id=@Eval;
 IF @Caso=7 INSERT dbo.Evaluacion(AsignacionId,TipoId,Nombre,Fecha,Maximo,Peso) VALUES(@Asignacion,@Tipo,N'Otra evaluación',DATEFROMPARTS(@AnioNumero,3,1),100,40);
 IF @Caso=9 UPDATE dbo.AsignacionDocente SET UsuarioId=@Admin WHERE Id=@Asignacion; -- Docente ya no es titular.
 IF @Caso=10 SET @Edicion=(SELECT @Tipo TipoId,N'Desempeño corregido' Nombre,DATEFROMPARTS(@AnioNumero,3,2) Fecha,N'Cualitativa' Modo,JSON_QUERY(N'["Logrado","En proceso"]') Valores FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Evaluacion_Editar @Docente,@Eval,@Token,@Op,@Motivo,@Edicion;
 IF @Caso=8
 BEGIN
  SET @Json=(SELECT 'Nota' Accion,@Asignacion AsignacionId,@Eval EvaluacionId,@Registro Registro,@Token VersionEvaluacion,20 Nota FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Notas_Guardar @Json,@Docente; -- Formulario abierto antes del cambio: rechazar aunque 20 quepa en ambos máximos.
 END;
 IF @Caso=11 EXEC dbo.Evaluacion_Editar @Docente,@Eval,@Token,@Op,N'Motivo diferente de prueba',@Edicion;
 IF @Caso IN (1,10)
 BEGIN
  EXEC dbo.Evaluacion_Editar @Docente,@Eval,@Token,@Op,@Motivo,@Edicion;
  IF (SELECT COUNT(*) FROM dbo.HistorialEvaluacion WHERE Operacion=@Op)<>1 OR (SELECT COUNT(*) FROM dbo.Auditoria WHERE IdOperacion=@Op)<>1 THROW 54420,N'Falta historial/auditoría o se duplicó el reintento.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.HistorialEvaluacion WHERE Operacion=@Op AND JSON_VALUE(AntesJson,'$.Nombre')=@Etiqueta) THROW 54420,N'No se conservó la definición anterior.',1;
  IF @Caso=1 AND NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE Id=@Eval AND Maximo=70 AND Peso=70 AND Version<>CONVERT(binary(8),@Token,1)) THROW 54420,N'No se actualizó la definición/version.',1;
  IF @Caso=10 AND ((SELECT COUNT(*) FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@Eval)<>2 OR NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE Id=@Eval AND Modo='Cualitativa' AND Maximo=1 AND Peso=0)) THROW 54420,N'Escala cualitativa incorrecta.',1;
 END;
 ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Error=ERROR_NUMBER();IF XACT_STATE()<>0 ROLLBACK;
  IF @Error<>@Esperado THROW;
 END CATCH;
 IF @Error<>@Esperado THROW 54420,N'No se rechazó el escenario esperado.',1;
 IF (SELECT COUNT(*) FROM dbo.Evaluacion)<>@Antes THROW 54420,N'Quedaron datos de prueba.',1;
 SELECT @Caso Caso,N'APROBADO: DATOS REVERTIDOS' Resultado;
 SET @Caso+=1;
END;
