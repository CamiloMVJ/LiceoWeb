CREATE OR ALTER PROCEDURE dbo.CatalogoAcademico_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52300,N'Datos inválidos.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52301,N'Se requiere administrador.',1;
 DECLARE @Tipo nvarchar(30)=JSON_VALUE(@Datos,'$.Tipo'),@Id int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.Id')),
 @Nombre nvarchar(100)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@Datos,'$.Nombre'))),''),@Codigo nvarchar(30)=NULLIF(JSON_VALUE(@Datos,'$.Codigo'),''),
 @Ubicacion nvarchar(200)=NULLIF(JSON_VALUE(@Datos,'$.Ubicacion'),''),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.Anio')),
 @AnioId int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AnioId')),@Capacidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.Capacidad')),
 @Inicio date=TRY_CONVERT(date,JSON_VALUE(@Datos,'$.Inicio')),@Fin date=TRY_CONVERT(date,JSON_VALUE(@Datos,'$.Fin')),
 @Activo bit=CASE WHEN JSON_VALUE(@Datos,'$.Activo')='true' THEN 1 ELSE 0 END,
 @SoloEstado bit=CASE WHEN JSON_VALUE(@Datos,'$.SoloEstado')='true' THEN 1 ELSE 0 END;
 IF @Id IS NULL OR @Id<0 OR @Tipo IS NULL OR @Tipo NOT IN ('Anios','Periodos','Modalidades','Turnos','Aulas','Asignaturas') THROW 52302,N'Catálogo inválido.',1;
 IF @SoloEstado=1 AND (@Id=0 OR @Tipo='Periodos') THROW 52302,N'Operación de estado inválida.',1;
 IF @SoloEstado=0 AND @Tipo<>'Anios' AND (@Nombre IS NULL OR (@Tipo<>'Asignaturas' AND LEN(@Nombre)>80)) THROW 52302,N'Nombre inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 52303,N'Planificación ocupada. Intente nuevamente.',1;
 IF @Tipo='Anios'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  IF @SoloEstado=1 UPDATE dbo.AnioLectivo SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Anio IS NULL OR @Anio NOT BETWEEN 1900 AND 9999 THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE AnioId=@Id) OR EXISTS(SELECT 1 FROM dbo.Pensum WHERE AnioId=@Id) OR EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE AnioId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.AnioLectivo(Anio,Activo) VALUES(@Anio,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.AnioLectivo SET Anio=@Anio,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo='Periodos'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  BEGIN
   IF @Inicio IS NULL OR @Fin IS NULL OR @Fin<@Inicio OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@AnioId AND Activo=1 AND YEAR(@Inicio)=Anio AND YEAR(@Fin)=Anio) THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PeriodoId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin) VALUES(@AnioId,@Nombre,@Inicio,@Fin);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.PeriodoAcademico SET AnioId=@AnioId,Nombre=@Nombre,Inicio=@Inicio,Fin=@Fin WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo='Modalidades'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  IF @SoloEstado=1 UPDATE dbo.ModalidadAcademica SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF 1=0 THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.Pensum WHERE ModalidadId=@Id) OR EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE ModalidadId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.ModalidadAcademica(Nombre,Activo) VALUES(@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.ModalidadAcademica SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo='Turnos'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.TurnoAcademico WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  IF @SoloEstado=1 UPDATE dbo.TurnoAcademico SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF 1=0 THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE TurnoId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.TurnoAcademico(Nombre,Activo) VALUES(@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.TurnoAcademico SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo='Aulas'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.Aula WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  IF @SoloEstado=1 UPDATE dbo.Aula SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Capacidad IS NULL OR @Capacidad<=0 OR @Ubicacion IS NULL THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE AulaId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.Aula(Nombre,Ubicacion,Capacidad,Activo) VALUES(@Nombre,@Ubicacion,@Capacidad,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.Aula SET Nombre=@Nombre,Ubicacion=@Ubicacion,Capacidad=@Capacidad,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo='Asignaturas'
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.Asignatura WHERE Id=@Id) THROW 52304,N'Registro inexistente.',1;
  IF @SoloEstado=1 UPDATE dbo.Asignatura SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Codigo IS NULL THROW 52302,N'Revise los campos del catálogo.',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.PensumAsignatura WHERE AsignaturaId=@Id) OR EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE AsignaturaId=@Id)) THROW 52305,N'El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.',1;
   IF @Id=0 BEGIN INSERT dbo.Asignatura(Codigo,Nombre,Activo) VALUES(@Codigo,@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.Asignatura SET Codigo=@Codigo,Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 DECLARE @Operacion uniqueidentifier=NEWID(),@Registro nvarchar(100)=CONVERT(nvarchar(100),@Id);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'GuardarCatalogoAcademico',@Entidad=@Tipo,@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Planificacion_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52300,N'Datos inválidos.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52301,N'Se requiere administrador.',1;
 DECLARE @Accion nvarchar(30)=JSON_VALUE(@Datos,'$.Accion'),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AnioId')),
 @Modalidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.ModalidadId')),@Nivel nvarchar(50)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@Datos,'$.Nivel'))),''),
 @Pensum int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.PensumId')),@Asignatura int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AsignaturaId')),
 @Periodo int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.PeriodoId')),@Turno int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.TurnoId')),
 @Aula int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AulaId')),@Seccion nvarchar(30)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@Datos,'$.Seccion'))),''),
 @Grupo int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.GrupoId')),@Docente nvarchar(450)=JSON_VALUE(@Datos,'$.DocenteId'),
 @Asignacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AsignacionId')),@Dia int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.Dia')),
 @Inicio time=TRY_CONVERT(time,JSON_VALUE(@Datos,'$.Inicio')),@Fin time=TRY_CONVERT(time,JSON_VALUE(@Datos,'$.Fin')),
 @Estudiante nvarchar(10)=JSON_VALUE(@Datos,'$.Registro');
 IF @Accion IS NULL OR @Accion NOT IN ('Pensum','Materia','Grupo','Docente','Horario','Estudiante') THROW 52302,N'Operación inválida.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Resultado int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 52303,N'Planificación ocupada. Intente nuevamente.',1;
 IF @Accion='Pensum'
 BEGIN
  IF @Nivel IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Anio AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Modalidad AND Activo=1) THROW 52306,N'Revise año, modalidad y nivel.',1;
  INSERT dbo.Pensum(AnioId,ModalidadId,Nivel) VALUES(@Anio,@Modalidad,@Nivel);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion='Materia'
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Pensum P JOIN dbo.AnioLectivo A ON A.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE P.Id=@Pensum AND A.Activo=1 AND M.Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.Asignatura WHERE Id=@Asignatura AND Activo=1) THROW 52306,N'Pensum o asignatura no disponible.',1;
  IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PensumId=@Pensum) THROW 52307,N'El pensum ya tiene grupos. No cambie el plan histórico.',1;
  INSERT dbo.PensumAsignatura(PensumId,AsignaturaId) VALUES(@Pensum,@Asignatura);SET @Resultado=@Pensum;
 END;
 IF @Accion='Grupo'
 BEGIN
  IF @Seccion IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Pensum P JOIN dbo.PeriodoAcademico T ON T.AnioId=P.AnioId JOIN dbo.AnioLectivo A ON A.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE P.Id=@Pensum AND T.Id=@Periodo AND T.Cerrado=0 AND A.Activo=1 AND M.Activo=1)
  OR NOT EXISTS(SELECT 1 FROM dbo.PensumAsignatura WHERE PensumId=@Pensum)
  OR NOT EXISTS(SELECT 1 FROM dbo.Aula WHERE Id=@Aula AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.TurnoAcademico WHERE Id=@Turno AND Activo=1) THROW 52308,N'Revise período, pensum con materias, turno y aula activos.',1;
  INSERT dbo.GrupoAcademico(PensumId,PeriodoId,TurnoId,AulaId,Seccion) VALUES(@Pensum,@Periodo,@Turno,@Aula,@Seccion);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion IN ('Docente','Estudiante')
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE G.Id=@Grupo AND P.Cerrado=0) THROW 52309,N'Grupo inexistente o período cerrado.',1;
 END;
 IF @Accion='Docente'
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@Docente AND R.Name='Profesor') THROW 52310,N'La cuenta no tiene rol Profesor.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PensumAsignatura P ON P.PensumId=G.PensumId JOIN dbo.Asignatura A ON A.Id=P.AsignaturaId WHERE G.Id=@Grupo AND P.AsignaturaId=@Asignatura AND A.Activo=1) THROW 52311,N'La asignatura no pertenece al pensum del grupo.',1;
  INSERT dbo.AsignacionDocente(GrupoId,AsignaturaId,UsuarioId) VALUES(@Grupo,@Asignatura,@Docente);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion='Horario'
 BEGIN
  DECLARE @Desde date,@Hasta date;
  SELECT @Grupo=G.Id,@Aula=G.AulaId,@Docente=D.UsuarioId,@Desde=P.Inicio,@Hasta=P.Fin FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND P.Cerrado=0;
  IF @Desde IS NULL OR @Dia IS NULL OR @Dia NOT BETWEEN 1 AND 7 OR @Inicio IS NULL OR @Fin IS NULL OR @Fin<=@Inicio THROW 52312,N'Asignación u horario inválido.',1;
  IF EXISTS(SELECT 1 FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId
   WHERE H.Dia=@Dia AND H.Inicio<@Fin AND @Inicio<H.Fin AND P.Inicio<=@Hasta AND @Desde<=P.Fin AND (G.Id=@Grupo OR G.AulaId=@Aula OR D.UsuarioId=@Docente)) THROW 52313,N'El horario se cruza con otra clase del docente, aula o grupo.',1;
  INSERT dbo.HorarioClase(AsignacionId,Dia,Inicio,Fin) VALUES(@Asignacion,@Dia,@Inicio,@Fin);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion='Estudiante'
 BEGIN
  -- Bloqueo compartido con el contrato financiero por estudiante.
  DECLARE @Estado nvarchar(10),@Capacidad int,@AnioNumero int,@ModalidadNombre nvarchar(80);
  SELECT @Estado=Estado FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Estudiante;
  SELECT @Capacidad=A.Capacidad,@AnioNumero=Y.Anio,@ModalidadNombre=M.Nombre,@Nivel=P.Nivel,@Periodo=G.PeriodoId FROM dbo.GrupoAcademico G JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE G.Id=@Grupo;
  IF @Estado IS NULL OR @Estado<>'Activo' OR NOT EXISTS(SELECT 1 FROM dbo.Matriculas WHERE Registro_Estudiante=@Estudiante AND Anio=@AnioNumero AND Modalidad=@ModalidadNombre AND Grado=@Nivel) THROW 52314,N'El estudiante requiere matrícula vigente del mismo año, modalidad y nivel.',1;
  IF EXISTS(SELECT 1 FROM dbo.GrupoEstudiante E JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId WHERE E.Registro=@Estudiante AND G.PeriodoId=@Periodo) THROW 52315,N'El estudiante ya pertenece a un grupo en este período.',1;
  IF (SELECT COUNT(*) FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo)>=@Capacidad THROW 52316,N'El aula alcanzó su capacidad.',1;
  INSERT dbo.GrupoEstudiante(GrupoId,Registro) VALUES(@Grupo,@Estudiante);SET @Resultado=@Grupo;
 END;
 DECLARE @Operacion uniqueidentifier=NEWID(),@RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Resultado),@AccionAudit nvarchar(50)=N'Planificar'+@Accion;
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N'Planificacion',@RegistroId=@RegistroId,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Planificacion_Consultar @UsuarioId nvarchar(450),@SoloDocente bit=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THEN 1 ELSE 0 END;
 IF @Admin=0 AND (@SoloDocente=0 OR NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Profesor')) THROW 52301,N'Acceso denegado.',1;
 IF @SoloDocente=1
 BEGIN
  SELECT Y.Anio,P.Nombre Periodo,G.Seccion,S.Nombre Asignatura,A.Nombre Aula,A.Ubicacion,H.Dia,H.Inicio,H.Fin
  FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=N.AnioId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.Aula A ON A.Id=G.AulaId LEFT JOIN dbo.HorarioClase H ON H.AsignacionId=D.Id
  WHERE D.UsuarioId=@UsuarioId ORDER BY Y.Anio DESC,P.Inicio,H.Dia,H.Inicio;
  RETURN;
 END;
 SELECT Id,Anio,Activo,CONVERT(nvarchar(10),Anio) Etiqueta FROM dbo.AnioLectivo ORDER BY Anio DESC;
 SELECT Id,AnioId,Nombre,Inicio,Fin,Cerrado,CONCAT(AnioId,' / ',Nombre) Etiqueta FROM dbo.PeriodoAcademico ORDER BY Inicio DESC;
 SELECT Id,Nombre,Activo,Nombre Etiqueta FROM dbo.ModalidadAcademica ORDER BY Nombre;
 SELECT Id,Nombre,Activo,Nombre Etiqueta FROM dbo.TurnoAcademico ORDER BY Nombre;
 SELECT Id,Nombre,Ubicacion,Capacidad,Activo,CONCAT(Nombre,' / ',Ubicacion) Etiqueta FROM dbo.Aula ORDER BY Nombre;
 SELECT Id,Codigo,Nombre,Activo,CONCAT(Codigo,' / ',Nombre) Etiqueta FROM dbo.Asignatura ORDER BY Nombre;
 SELECT P.Id,P.AnioId,P.ModalidadId,P.Nivel,CONCAT(Y.Anio,' / ',M.Nombre,' / ',P.Nivel) Etiqueta FROM dbo.Pensum P JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId ORDER BY Y.Anio DESC,M.Nombre,P.Nivel;
 SELECT P.PensumId,A.Nombre Asignatura FROM dbo.PensumAsignatura P JOIN dbo.Asignatura A ON A.Id=P.AsignaturaId ORDER BY P.PensumId,A.Nombre;
 SELECT G.Id,G.PensumId,G.PeriodoId,G.TurnoId,G.AulaId,G.Seccion,CONCAT(Y.Anio,' / ',P.Nivel,' ',G.Seccion,' / ',T.Nombre) Etiqueta FROM dbo.GrupoAcademico G JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.PeriodoAcademico T ON T.Id=G.PeriodoId ORDER BY Y.Anio DESC,P.Nivel,G.Seccion;
 SELECT U.Id,U.UserName Etiqueta FROM dbo.AspNetUsers U WHERE EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id AND R.Name='Profesor') ORDER BY U.UserName;
 SELECT D.Id,D.GrupoId,S.Nombre Asignatura,U.UserName Docente,CONCAT(D.GrupoId,' / ',S.Nombre,' / ',U.UserName) Etiqueta FROM dbo.AsignacionDocente D JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId;
 SELECT H.Id,H.AsignacionId,G.Seccion,S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId ORDER BY H.Dia,H.Inicio;
 SELECT E.GrupoId,E.Registro,S.NombreEstudiante FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro ORDER BY E.GrupoId,S.NombreEstudiante;
END;
GO
