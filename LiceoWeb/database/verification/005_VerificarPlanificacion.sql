-- Base descartable/de desarrollo, sin actividad concurrente.
-- Este ensayo espera un conflicto de horario que revierte toda su transacción.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' THROW 52400,N'Base incorrecta.',1;
IF @@TRANCOUNT<>0 THROW 52400,N'Cierre las transacciones anteriores.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
DECLARE @Docente nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Profesor');
IF @Admin IS NULL OR @Docente IS NULL THROW 52400,N'Cree cuentas de Administrador y Profesor antes de probar.',1;
DECLARE @Etiqueta nvarchar(30)=N'TEST-'+LEFT(CONVERT(nvarchar(36),NEWID()),8),@AnioNumero int=2098,@Json nvarchar(max),@A int,@M int,@T int,@S int,@Aula int,@P int,@Pensum int,@Grupo int,@Asignacion int;
WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@AnioNumero) SET @AnioNumero=@AnioNumero-1;
DECLARE @Antes int=(SELECT COUNT(*) FROM dbo.GrupoAcademico),@Esperado bit=0;
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
 -- Clases adyacentes sí se permiten.
 SET @Json=JSON_MODIFY(JSON_MODIFY(@Json,'$.Inicio','10:00'),'$.Fin','11:00');
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 IF (SELECT COUNT(*) FROM dbo.HorarioClase WHERE AsignacionId=@Asignacion)<>2 THROW 52401,N'No se guardaron horarios adyacentes.',1;
 SET @Json=JSON_MODIFY(JSON_MODIFY(@Json,'$.Inicio','09:30'),'$.Fin','10:30');
 EXEC dbo.Planificacion_Guardar @Json,@Admin;
 THROW 52402,N'No se rechazó el cruce.',1;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER()=52313 SET @Esperado=1;ELSE THROW;
END CATCH;
IF @Esperado<>1 OR (SELECT COUNT(*) FROM dbo.GrupoAcademico)<>@Antes THROW 52403,N'No se revirtió la prueba.',1;
SELECT N'Correcto: planificación y horarios adyacentes; cruce rechazado y datos revertidos.' Resultado;
