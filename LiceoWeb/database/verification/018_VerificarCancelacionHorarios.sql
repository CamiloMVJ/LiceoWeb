-- Ejecutar solo en copia de desarrollo, sin actividad concurrente.
-- Requiere migración 018, Planificacion.sql actualizado y los tres Horario_*.sql.
-- Revierte todos los datos de prueba; contadores identity/rowversion pueden avanzar.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54220,N'Use desarrollo sin transacciones abiertas.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
DECLARE @Docente nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Profesor'
 AND NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles X JOIN dbo.AspNetRoles Y ON Y.Id=X.RoleId WHERE X.UserId=U.UserId AND Y.Name='Administrador'));
IF @Admin IS NULL OR @Docente IS NULL THROW 54220,N'Requiere Administrador y Profesor sin rol Administrador.',1;
DECLARE @Etiqueta nvarchar(30),@AnioNumero int=2098,@Json nvarchar(max),@A int,@M int,@T int,@S int,@Aula int,@P int,@Pensum int,@Grupo int,@Asignacion int;
WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@AnioNumero) SET @AnioNumero=@AnioNumero-1;
DECLARE @Caso int=1,@Esperado int,@Recibido int,@Horario int,@Version varchar(18),@Operacion uniqueidentifier,@Otra uniqueidentifier;
DECLARE @Antes int=(SELECT COUNT(*) FROM dbo.HorarioClase),@AntesCancel int=(SELECT COUNT(*) FROM dbo.CancelacionHorario);
WHILE @Caso<=6
BEGIN
 SET @Esperado=CASE @Caso WHEN 1 THEN 0 WHEN 2 THEN 54208 WHEN 3 THEN 54207 WHEN 4 THEN 54201 WHEN 5 THEN 54206 WHEN 6 THEN 54204 END;
 SET @Recibido=0;SET @Etiqueta=N'TEST-'+LEFT(CONVERT(nvarchar(36),NEWID()),8);SET @Operacion=NEWID();SET @Otra=NEWID();
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
 SET @Json=(SELECT 'Horario' Accion,@Asignacion AsignacionId,1 Dia,'09:00' Inicio,'10:00' Fin FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin;

  SELECT @Horario=Id,@Version=CONVERT(varchar(18),Version,1) FROM dbo.HorarioClase WHERE AsignacionId=@Asignacion;
  IF @Caso=2 UPDATE dbo.PeriodoAcademico SET Cerrado=1 WHERE Id=@P;
  IF @Caso=3 UPDATE dbo.HorarioClase SET Dia=2 WHERE Id=@Horario;
  DECLARE @Actor nvarchar(450)=CASE WHEN @Caso=4 THEN @Docente ELSE @Admin END;
  EXEC dbo.Horario_Cancelar @Actor,@Horario,@Version,@Operacion,N'Reorganización de clases de prueba';
  IF @Caso=5 EXEC dbo.Horario_Cancelar @Admin,@Horario,@Version,@Otra,N'Reorganización de clases de prueba';
  IF @Caso=6 EXEC dbo.Horario_Cancelar @Admin,@Horario,@Version,@Operacion,N'Otro motivo para la misma operación';
  IF @Caso=1
  BEGIN
   EXEC dbo.Horario_Cancelar @Admin,@Horario,@Version,@Operacion,N'Reorganización de clases de prueba';
   IF (SELECT COUNT(*) FROM dbo.CancelacionHorario WHERE HorarioId=@Horario)<>1 THROW 54221,N'Cancelación duplicada o ausente.',1;
   IF (SELECT COUNT(*) FROM dbo.Auditoria WHERE IdOperacion=@Operacion AND Accion='CancelarHorario')<>1 THROW 54221,N'Auditoría duplicada o ausente.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.HorarioClase WHERE Id=@Horario) OR EXISTS(SELECT 1 FROM dbo.HorarioClaseVigente WHERE Id=@Horario) THROW 54221,N'No se conservó el original o sigue vigente.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE HorarioId=@Horario AND JSON_VALUE(Instantanea,'$.Asignatura')=@Etiqueta) THROW 54221,N'Falta la instantánea histórica.',1;
   -- Reutilizar exactamente el mismo espacio tras cancelar.
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
   IF (SELECT COUNT(*) FROM dbo.HorarioClaseVigente WHERE AsignacionId=@Asignacion)<>1 OR (SELECT COUNT(*) FROM dbo.HorarioClase WHERE AsignacionId=@Asignacion)<>2 THROW 54221,N'No se liberó el horario o se borró el original.',1;
  END;
  ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Recibido=ERROR_NUMBER();
  IF XACT_STATE()<>0 ROLLBACK;
  IF @Recibido<>@Esperado THROW;
 END CATCH;
 IF @Recibido<>@Esperado THROW 54221,N'No se rechazó la operación esperada.',1;
 IF (SELECT COUNT(*) FROM dbo.HorarioClase)<>@Antes OR (SELECT COUNT(*) FROM dbo.CancelacionHorario)<>@AntesCancel THROW 54221,N'Quedaron datos de prueba.',1;
 SELECT @Caso Caso,N'APROBADO: DATOS REVERTIDOS' Resultado;
 SET @Caso+=1;
END;
