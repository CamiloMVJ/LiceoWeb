-- Solo copia de desarrollo, sin actividad concurrente. Todos los datos se revierten.
-- Requiere 019 y los tres procedimientos Planificacion_Cambio*.sql; corte ya aplicado.
-- Los contadores identity/rowversion/secuencia pueden avanzar aunque se haga rollback.
SET NOCOUNT ON;SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54320,N'Use desarrollo sin transacciones abiertas.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 54320,N'Esta prueba requiere una copia con corte aplicado; no lo aplica automáticamente.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
DECLARE @Prof1 nvarchar(450)=(SELECT TOP(1) U.Id FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE R.Name='Profesor' AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles X JOIN dbo.AspNetRoles Y ON Y.Id=X.RoleId WHERE X.UserId=U.Id AND Y.Name='Administrador'));
DECLARE @Prof2 nvarchar(450)=(SELECT TOP(1) U.Id FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE R.Name='Profesor' AND U.Id<>@Prof1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()));
IF @Admin IS NULL OR @Prof1 IS NULL OR @Prof2 IS NULL THROW 54320,N'Requiere Administrador y dos Profesores habilitados; el primero sin rol Administrador.',1;
DECLARE @Caso int=1,@Esperado int,@Recibido int,@Etiqueta nvarchar(30),@Anio int=2098,@A int,@M int,@T int,@Aula1 int,@Aula2 int,@P int,@N int,@S int,@G1 int,@G2 int,@D1 int,@D2 int,@H int,@Arancel int,@Tarifa int,@Cargo bigint,@TipoEval int,@Eval int,@Registro nvarchar(10),@Version varchar(18),@HorarioVersion binary(8),@Op uniqueidentifier,@Actor nvarchar(450),@Tipo nvarchar(20),@Origen int,@Docente nvarchar(450),@Destino int,@Reg nvarchar(10);
DECLARE @Salida TABLE(Registro nvarchar(10));
WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@Anio) SET @Anio-=1;
DECLARE @Antes int=(SELECT COUNT(*) FROM dbo.CambioPlanificacion),@AntesAlumnos int=(SELECT COUNT(*) FROM dbo.Estudiantes);
WHILE @Caso<=13
BEGIN
 SET @Esperado=CASE @Caso WHEN 1 THEN 0 WHEN 2 THEN 54309 WHEN 3 THEN 54307 WHEN 4 THEN 54307 WHEN 5 THEN 54306 WHEN 6 THEN 0 WHEN 7 THEN 54312 WHEN 8 THEN 54311 WHEN 9 THEN 54307 WHEN 10 THEN 54310 WHEN 11 THEN 54301 WHEN 12 THEN 54306 WHEN 13 THEN 54304 END;
 SET @Recibido=0;SET @Etiqueta=N'TEST-'+LEFT(CONVERT(nvarchar(36),NEWID()),8);SET @Op=NEWID();DELETE @Salida;
 BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.AnioLectivo(Anio) VALUES(@Anio);SET @A=SCOPE_IDENTITY();
 SET @M=NULL;
 SELECT @M=Id FROM dbo.ModalidadAcademica WHERE Nombre='Primaria';
 IF @M IS NULL BEGIN INSERT dbo.ModalidadAcademica(Nombre) VALUES('Primaria');SET @M=SCOPE_IDENTITY();END;
 UPDATE dbo.ModalidadAcademica SET Activo=1 WHERE Id=@M;
 INSERT dbo.TurnoAcademico(Nombre) VALUES(@Etiqueta);SET @T=SCOPE_IDENTITY();
 INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(@Etiqueta+'A','Prueba',5);SET @Aula1=SCOPE_IDENTITY();
 INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(@Etiqueta+'B','Prueba',1);SET @Aula2=SCOPE_IDENTITY();
 INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin) VALUES(@A,@Etiqueta,DATEFROMPARTS(@Anio,1,1),DATEFROMPARTS(@Anio,6,30));SET @P=SCOPE_IDENTITY();
 INSERT dbo.Pensum(AnioId,ModalidadId,Nivel) VALUES(@A,@M,'1er Grado');SET @N=SCOPE_IDENTITY();
 INSERT dbo.Asignatura(Codigo,Nombre) VALUES(@Etiqueta,@Etiqueta);SET @S=SCOPE_IDENTITY();
 INSERT dbo.PensumAsignatura(PensumId,AsignaturaId) VALUES(@N,@S);
 INSERT dbo.GrupoAcademico(PensumId,PeriodoId,TurnoId,AulaId,Seccion) VALUES(@N,@P,@T,@Aula1,'A');SET @G1=SCOPE_IDENTITY();
 INSERT dbo.GrupoAcademico(PensumId,PeriodoId,TurnoId,AulaId,Seccion) VALUES(@N,@P,@T,@Aula2,'B');SET @G2=SCOPE_IDENTITY();
 INSERT dbo.AsignacionDocente(GrupoId,AsignaturaId,UsuarioId) VALUES(@G1,@S,@Prof1);SET @D1=SCOPE_IDENTITY();
 INSERT dbo.AsignacionDocente(GrupoId,AsignaturaId,UsuarioId) VALUES(@G2,@S,@Prof2);SET @D2=SCOPE_IDENTITY();
 INSERT dbo.HorarioClase(AsignacionId,Dia,Inicio,Fin) VALUES(@D1,1,'09:00','10:00');SET @H=SCOPE_IDENTITY();
 SELECT @HorarioVersion=Version FROM dbo.HorarioClase WHERE Id=@H;
 INSERT dbo.Estudiantes(NombreEstudiante,Modalidad,Grado,FechaNacimiento,Sexo,NombreTutor,Telefono,Direccion)
 OUTPUT inserted.Registro INTO @Salida VALUES(@Etiqueta,'Primaria','1er Grado','20180101','F','Tutor prueba','88888888','Prueba');
 SELECT @Registro=Registro FROM @Salida;
 INSERT dbo.Arancel(Codigo,Nombre) VALUES(@Etiqueta,@Etiqueta);SET @Arancel=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Arancel,@M,@A,1);SET @Tarifa=SCOPE_IDENTITY();
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento) VALUES(@Registro,@Tarifa,'ANUAL',@Etiqueta,1,NULL);SET @Cargo=SCOPE_IDENTITY();
 INSERT dbo.MatriculaAcademica(Registro,Anio,Modalidad,Nivel,CargoId,UsuarioId) VALUES(@Registro,@Anio,'Primaria','1er Grado',@Cargo,@Admin);
 INSERT dbo.GrupoEstudiante(GrupoId,Registro) VALUES(@G1,@Registro);
 SET @Tipo=CASE WHEN @Caso BETWEEN 6 AND 10 OR @Caso=12 THEN 'Estudiante' ELSE 'Docente' END;
 SET @Origen=CASE WHEN @Tipo='Estudiante' THEN @G1 ELSE @D1 END;
 SET @Docente=CASE WHEN @Tipo='Docente' THEN @Prof2 ELSE NULL END;
 SET @Destino=CASE WHEN @Tipo='Estudiante' THEN @G2 ELSE NULL END;
 SET @Reg=CASE WHEN @Tipo='Estudiante' THEN @Registro ELSE NULL END;
 SET @Actor=CASE WHEN @Caso=11 THEN @Prof1 ELSE @Admin END;
 IF @Tipo='Estudiante' SELECT @Version=CONVERT(varchar(18),Version,1) FROM dbo.GrupoEstudiante WHERE GrupoId=@G1 AND Registro=@Registro;
 ELSE SELECT @Version=CONVERT(varchar(18),Version,1) FROM dbo.AsignacionDocente WHERE Id=@D1;
 IF @Caso=2 INSERT dbo.HorarioClase(AsignacionId,Dia,Inicio,Fin) VALUES(@D2,1,'09:30','10:30');
 IF @Caso=3 UPDATE dbo.PeriodoAcademico SET Cerrado=1 WHERE Id=@P;
 IF @Caso=4 INSERT dbo.PublicacionNotas(AsignacionId,UsuarioId) VALUES(@D1,@Admin);
 IF @Caso=5 UPDATE dbo.AsignacionDocente SET UsuarioId=UsuarioId WHERE Id=@D1;
 IF @Caso=7
 BEGIN
  DELETE @Salida;
  INSERT dbo.Estudiantes(NombreEstudiante,Modalidad,Grado,FechaNacimiento,Sexo,NombreTutor,Telefono,Direccion)
  OUTPUT inserted.Registro INTO @Salida VALUES(@Etiqueta+'2','Primaria','1er Grado','20180101','M','Tutor prueba','88888888','Prueba');
  INSERT dbo.GrupoEstudiante(GrupoId,Registro) SELECT @G2,Registro FROM @Salida;
 END;
 IF @Caso IN (1,8)
 BEGIN
  INSERT dbo.TipoEvaluacion(Nombre) VALUES(@Etiqueta);SET @TipoEval=SCOPE_IDENTITY();
  INSERT dbo.Evaluacion(AsignacionId,TipoId,Nombre,Fecha,Maximo,Peso) VALUES(@D1,@TipoEval,@Etiqueta,DATEFROMPARTS(@Anio,1,5),100,100);SET @Eval=SCOPE_IDENTITY();
  INSERT dbo.Calificacion(EvaluacionId,Registro,Nota,UsuarioId) VALUES(@Eval,@Registro,80,@Prof1);
 END;
 IF @Caso=9 INSERT dbo.PublicacionNotas(AsignacionId,UsuarioId) VALUES(@D2,@Admin);
 IF @Caso=10
 BEGIN
  INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin) VALUES(@A,@Etiqueta+'2',DATEFROMPARTS(@Anio,7,1),DATEFROMPARTS(@Anio,12,31));
  UPDATE dbo.GrupoAcademico SET PeriodoId=SCOPE_IDENTITY() WHERE Id=@G2;
 END;
 IF @Caso=12 UPDATE dbo.GrupoEstudiante SET GrupoId=GrupoId WHERE GrupoId=@G1 AND Registro=@Registro;
 EXEC dbo.Planificacion_Cambiar @Actor,@Tipo,@Origen,@Reg,@Docente,@Destino,@Version,@Op,N'Reorganización académica de prueba';
 IF @Caso=13 EXEC dbo.Planificacion_Cambiar @Actor,@Tipo,@Origen,@Reg,@Docente,@Destino,@Version,@Op,N'Otro motivo para la misma operación';
 IF @Caso IN (1,6)
 BEGIN
  EXEC dbo.Planificacion_Cambiar @Actor,@Tipo,@Origen,@Reg,@Docente,@Destino,@Version,@Op,N'Reorganización académica de prueba';
  IF (SELECT COUNT(*) FROM dbo.CambioPlanificacion WHERE Operacion=@Op)<>1 OR (SELECT COUNT(*) FROM dbo.Auditoria WHERE IdOperacion=@Op)<>1 THROW 54321,N'Falta historial/auditoría o se duplicó el reintento.',1;
  IF @Caso=1 AND (NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE Id=@D1 AND UsuarioId=@Prof2) OR NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Eval AND UsuarioId=@Prof1 AND Nota=80) OR EXISTS(SELECT 1 FROM dbo.HorarioClase WHERE Id=@H AND Version=@HorarioVersion)) THROW 54321,N'No cambió docente, se perdió autoría o no se invalidó confirmación de horario.',1;
  IF @Caso=6 AND (EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@G1 AND Registro=@Registro) OR NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@G2 AND Registro=@Registro) OR (SELECT COUNT(*) FROM dbo.MatriculaAcademica WHERE Registro=@Registro)<>1 OR (SELECT COUNT(*) FROM dbo.CargoEstudiante WHERE Registro=@Registro)<>1) THROW 54321,N'Traslado incorrecto o duplicó matrícula/cargo.',1;
 END;
 ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Recibido=ERROR_NUMBER();IF XACT_STATE()<>0 ROLLBACK;
  IF @Recibido<>@Esperado THROW;
 END CATCH;
 IF @Recibido<>@Esperado THROW 54321,N'No se rechazó el escenario esperado.',1;
 IF (SELECT COUNT(*) FROM dbo.CambioPlanificacion)<>@Antes OR (SELECT COUNT(*) FROM dbo.Estudiantes)<>@AntesAlumnos THROW 54321,N'Quedaron datos de prueba.',1;
 SELECT @Caso Caso,N'APROBADO: DATOS REVERTIDOS' Resultado;
 SET @Caso+=1;
END;
