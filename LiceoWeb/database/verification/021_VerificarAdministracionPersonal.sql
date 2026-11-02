-- SOLO copia de desarrollo, sin usuarios conectados. Cada caso revierte todas sus filas.
-- No equivale a una prueba de concurrencia ni a iniciar sesión por HTTP.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 54520,N'Use desarrollo sin transacciones abiertas.',1;
IF OBJECT_ID('dbo.Personal_Guardar','P') IS NULL THROW 54520,N'Instale 021 y sus procedimientos primero.',1;
DECLARE @Caso int=1,@Esperado int,@Error int,@Admin nvarchar(450),@Cuenta nvarchar(450),@Version nvarchar(128),@Sello nvarchar(128),@Op uniqueidentifier;
DECLARE @AdminRol nvarchar(450),@ProfesorRol nvarchar(450),@CajeroRol nvarchar(450),@Rol nvarchar(30),@Activa bit,@Actor nvarchar(450),@Motivo nvarchar(500)=N'Verificación de administración de personal';
DECLARE @Antes bigint=(SELECT COUNT_BIG(*) FROM dbo.AspNetUsers);
WHILE @Caso<=16
BEGIN
 SET @Admin=CONVERT(nvarchar(36),NEWID()); SET @Cuenta=CONVERT(nvarchar(36),NEWID()); SET @Version=CONVERT(nvarchar(36),NEWID()); SET @Sello=CONVERT(nvarchar(36),NEWID()); SET @Op=NEWID();
 SET @Rol=N'Profesor';SET @Activa=0;SET @Error=0;SET @Actor=@Admin;
 SET @Esperado=CASE @Caso WHEN 3 THEN 54504 WHEN 4 THEN 54501 WHEN 5 THEN 54501 WHEN 6 THEN 54507 WHEN 7 THEN 54505 WHEN 8 THEN 54508 WHEN 9 THEN 54511 WHEN 10 THEN 54510 WHEN 12 THEN 54503 WHEN 13 THEN 54509 WHEN 16 THEN 52310 ELSE 0 END;
 BEGIN TRY
  BEGIN TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM dbo.AspNetRoles WHERE Name=N'Administrador') INSERT dbo.AspNetRoles(Id,Name,NormalizedName,ConcurrencyStamp) VALUES(NEWID(),N'Administrador',N'ADMINISTRADOR',NEWID());
  IF NOT EXISTS(SELECT 1 FROM dbo.AspNetRoles WHERE Name=N'Profesor') INSERT dbo.AspNetRoles(Id,Name,NormalizedName,ConcurrencyStamp) VALUES(NEWID(),N'Profesor',N'PROFESOR',NEWID());
  IF NOT EXISTS(SELECT 1 FROM dbo.AspNetRoles WHERE Name=N'Cajero') INSERT dbo.AspNetRoles(Id,Name,NormalizedName,ConcurrencyStamp) VALUES(NEWID(),N'Cajero',N'CAJERO',NEWID());
  SELECT @AdminRol=Id FROM dbo.AspNetRoles WHERE Name=N'Administrador';
  SELECT @ProfesorRol=Id FROM dbo.AspNetRoles WHERE Name=N'Profesor';
  SELECT @CajeroRol=Id FROM dbo.AspNetRoles WHERE Name=N'Cajero';
  INSERT dbo.AspNetUsers(Id,UserName,NormalizedUserName,Email,NormalizedEmail,EmailConfirmed,PasswordHash,SecurityStamp,ConcurrencyStamp,PhoneNumberConfirmed,TwoFactorEnabled,LockoutEnabled,AccessFailedCount)
  VALUES(@Admin,@Admin,@Admin,@Admin,@Admin,1,N'Prueba-no-utilizable-para-login',NEWID(),NEWID(),0,0,1,0),
        (@Cuenta,@Cuenta,@Cuenta,@Cuenta,@Cuenta,1,N'Prueba-no-utilizable-para-login',@Sello,@Version,0,0,1,0);
  INSERT dbo.AspNetUserRoles(UserId,RoleId) VALUES(@Admin,@AdminRol),(@Cuenta,@ProfesorRol);
  IF @Caso=2 BEGIN INSERT dbo.EstadoCuentaPersonal VALUES(@Cuenta,0);SET @Activa=1;SET @Rol=N'Cajero';END;
  IF @Caso=3 SET @Cuenta=@Admin;
  IF @Caso=4 BEGIN UPDATE dbo.AspNetUserRoles SET RoleId=@CajeroRol WHERE UserId=@Admin;END;
  IF @Caso=5 INSERT dbo.EstadoCuentaPersonal VALUES(@Admin,0);
  IF @Caso=6 UPDATE dbo.AspNetUsers SET ConcurrencyStamp=NEWID() WHERE Id=@Cuenta;
  IF @Caso=8 INSERT dbo.AspNetUserRoles VALUES(@Cuenta,@CajeroRol);
  IF @Caso=9
  BEGIN
   UPDATE dbo.AspNetUserRoles SET RoleId=@AdminRol WHERE UserId=@Cuenta;
   -- Temporal, revertido: simula que ningún otro administrador puede entrar con contraseña.
   UPDATE U SET PasswordHash=NULL FROM dbo.AspNetUsers U WHERE U.Id<>@Cuenta AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR WHERE UR.UserId=U.Id AND UR.RoleId=@AdminRol);
  END;
  IF @Caso IN(10,11,16)
  BEGIN
   DECLARE @A int,@M int,@T int,@S int,@Aula int,@P int,@Pensum int,@Grupo int,@Anio int=2097,@Etiqueta nvarchar(30)=LEFT(@Cuenta,30);
   WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@Anio) SET @Anio-=1;
   INSERT dbo.AnioLectivo(Anio) VALUES(@Anio);SET @A=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.ModalidadAcademica(Nombre) VALUES(@Etiqueta);SET @M=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.TurnoAcademico(Nombre) VALUES(@Etiqueta);SET @T=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(@Etiqueta,N'Prueba',20);SET @Aula=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.Asignatura(Codigo,Nombre) VALUES(@Etiqueta,@Etiqueta);SET @S=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin,Cerrado) VALUES(@A,@Etiqueta,DATEFROMPARTS(@Anio,1,1),DATEFROMPARTS(@Anio,6,30),CASE WHEN @Caso=11 THEN 1 ELSE 0 END);SET @P=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.Pensum(AnioId,ModalidadId,Nivel) VALUES(@A,@M,N'1er Grado');SET @Pensum=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.PensumAsignatura VALUES(@Pensum,@S);
   INSERT dbo.GrupoAcademico(PensumId,PeriodoId,TurnoId,AulaId,Seccion) VALUES(@Pensum,@P,@T,@Aula,N'A');SET @Grupo=CONVERT(int,SCOPE_IDENTITY());
   IF @Caso<>16 INSERT dbo.AsignacionDocente(GrupoId,AsignaturaId,UsuarioId) VALUES(@Grupo,@S,@Cuenta);
  END;
  IF @Caso=12 SET @Rol=N'Visitante';
  IF @Caso=13 SET @Activa=1;
  IF @Caso=14 BEGIN UPDATE dbo.AspNetUserRoles SET RoleId=@AdminRol WHERE UserId=@Cuenta;SET @Rol=N'Cajero';SET @Activa=1;END;
  IF @Caso=15 BEGIN SET @Rol=N'Administrador';SET @Activa=1;END;
  EXEC dbo.Personal_Guardar @Actor,@Cuenta,@Version,@Rol,@Activa,@Motivo,@Op;
  IF @Caso=7 EXEC dbo.Personal_Guardar @Actor,@Cuenta,@Version,@Rol,@Activa,N'Motivo diferente de la primera solicitud',@Op;
  IF @Caso=16
  BEGIN
   DECLARE @Json nvarchar(max)=(SELECT 'Docente' Accion,@Grupo GrupoId,@S AsignaturaId,@Cuenta DocenteId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
  END;
  IF @Esperado=0
  BEGIN
   EXEC dbo.Personal_Guardar @Actor,@Cuenta,@Version,@Rol,@Activa,@Motivo,@Op; -- reintento exacto
   IF (SELECT COUNT(*) FROM dbo.HistorialCuentaPersonal WHERE Operacion=@Op)<>1 OR (SELECT COUNT(*) FROM dbo.Auditoria WHERE IdOperacion=@Op)<>1 THROW 54520,N'Auditoría o idempotencia incorrectas.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@Cuenta AND Activa=@Activa) THROW 54520,N'Estado no actualizado.',1;
   IF EXISTS(SELECT 1 FROM dbo.AspNetUsers WHERE Id=@Cuenta AND (SecurityStamp=@Sello OR ConcurrencyStamp=@Version)) THROW 54520,N'No se renovaron ambos sellos.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@Cuenta AND R.Name=@Rol) THROW 54520,N'Rol no actualizado.',1;
   IF @Caso=11 AND NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE UsuarioId=@Cuenta) THROW 54520,N'Se borró historial docente.',1;
  END;
  ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Error=ERROR_NUMBER();IF XACT_STATE()<>0 ROLLBACK;
  IF @Error<>@Esperado THROW;
 END CATCH;
 IF @Error<>@Esperado THROW 54520,N'No se rechazó el escenario esperado.',1;
 IF (SELECT COUNT_BIG(*) FROM dbo.AspNetUsers)<>@Antes THROW 54520,N'Quedaron cuentas de prueba.',1;
 SELECT @Caso Caso,N'APROBADO: DATOS REVERTIDOS' Resultado;
 SET @Caso+=1;
END;
