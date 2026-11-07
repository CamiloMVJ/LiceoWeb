-- Solo para una instalación NUEVA de demostración; no ejecutar sobre datos reales.
-- Cuentas solicitadas: camilo@liceo.test / profesor@liceo.test / cajero@liceo.test.
-- Contraseña de demostración: Admin1234#. Se almacenan hashes Identity V3, no texto plano.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS(SELECT 1 FROM dbo.AspNetUsers) OR EXISTS(SELECT 1 FROM dbo.Estudiantes)
 THROW 54902,N'La demostración requiere usuarios y estudiantes vacíos.',1;
BEGIN TRANSACTION;
DECLARE @Cuentas TABLE(Id nvarchar(450),Correo nvarchar(256),Rol nvarchar(256),Hash nvarchar(max));
INSERT @Cuentas VALUES
(N'demo-administrador',N'camilo@liceo.test',N'Administrador',N'AQAAAAIAAYagAAAAEFkG+aS+bZ1TffK01csIU28xixNNSkVFTzqSLsE+y/d7wQz5an9rqpnkBipjtRZa2A=='),
(N'demo-profesor',N'profesor@liceo.test',N'Profesor',N'AQAAAAIAAYagAAAAEL+ZK6jIO3tJiGaFkCCSq7AO15k5uJQsqYzC0ZGhgOzIp7z1Fbnx8fPUNv1ORGOgmw=='),
(N'demo-cajero',N'cajero@liceo.test',N'Cajero',N'AQAAAAIAAYagAAAAEHyfHdOhZ716ymIFbY3ofF0Hmvz6XZXjfpaZZmoMUUFMEqkVu63vA/UmmSeqCrCB0Q==');
INSERT dbo.AspNetUsers(Id,UserName,NormalizedUserName,Email,NormalizedEmail,EmailConfirmed,
 PasswordHash,SecurityStamp,ConcurrencyStamp,PhoneNumberConfirmed,TwoFactorEnabled,LockoutEnabled,AccessFailedCount)
SELECT Id,Correo,UPPER(Correo),Correo,UPPER(Correo),1,Hash,CONVERT(nvarchar(36),NEWID()),
 CONVERT(nvarchar(36),NEWID()),0,0,1,0 FROM @Cuentas;
INSERT dbo.AspNetUserRoles(UserId,RoleId)
 SELECT C.Id,R.Id FROM @Cuentas C JOIN dbo.AspNetRoles R ON R.Name=C.Rol;
INSERT dbo.EstadoCuentaPersonal(UsuarioId,Activa) SELECT Id,1 FROM @Cuentas;
DECLARE @Op uniqueidentifier=NEWID();
EXEC dbo.Registrar_Auditoria N'demo-administrador',N'InicializarDemo',N'Identity',N'cuentas-demo',@Op;
COMMIT;
GO
-- Se aplica el procedimiento real sobre una base sin actividad financiera.
-- Esto activa el libro nuevo sin migrar ni reinterpretar pagos de otra instalación.
DECLARE @Corte uniqueidentifier=NEWID();
EXEC dbo.CorteFinanciero_Ejecutar
 @UsuarioId=N'demo-administrador',@Operacion=@Corte,@Aplicar=1,
 @Confirmacion=N'APLICAR CORTE EN DESARROLLO';
IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N'No se activó el libro nuevo. No se continuará con los datos demo.',1;
GO
DECLARE @Admin nvarchar(450)=N'demo-administrador',@Profesor nvarchar(450)=N'demo-profesor',
 @Cajero nvarchar(450)=N'demo-cajero',@Anio int=YEAR(SYSUTCDATETIME()),
 @AnioId int,@Periodo int,@Turno int,@Matricula int,@Mensualidad int,@Bus int;
INSERT dbo.AnioLectivo(Anio) VALUES(@Anio); SET @AnioId=SCOPE_IDENTITY();
INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin)
 VALUES(@AnioId,N'Período de demostración',DATEFROMPARTS(@Anio,1,1),DATEFROMPARTS(@Anio,12,31));
SET @Periodo=SCOPE_IDENTITY();
INSERT dbo.TurnoAcademico(Nombre) VALUES(N'Matutino');SET @Turno=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N'MAT',N'Matrícula');SET @Matricula=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N'MEN',N'Mensualidad');SET @Mensualidad=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N'BUS',N'Transporte escolar');SET @Bus=SCOPE_IDENTITY();
EXEC dbo.Cargos_Configurar @Admin,@Matricula,N'Anual';
EXEC dbo.Cargos_Configurar @Admin,@Mensualidad,N'Mensual';
EXEC dbo.Cargos_Configurar @Admin,@Bus,N'Mensual';
EXEC dbo.Cargos_ConfigurarMatricula @Admin,@Matricula;

DECLARE @Niveles TABLE(N int PRIMARY KEY,Modalidad nvarchar(80),Grado nvarchar(50),Precio decimal(18,2),Nacimiento int);
INSERT @Niveles VALUES(1,N'Preescolar',N'I Nivel',350,4),(2,N'Primaria',N'1er Grado',500,6),(3,N'Secundaria',N'7mo Grado',650,12);
DECLARE @n int=1,@i int,@Modalidad nvarchar(80),@Grado nvarchar(50),@Precio decimal(18,2),@Edad int,
 @Mod int,@Aula int,@Plan int,@Grupo int,@Materia int,@Asignacion int,@TarifaMat int,@TarifaMen int,
 @VMat binary(8),@VMen binary(8),@Cargo bigint,@Registro nvarchar(10),@Json nvarchar(max),@Op uniqueidentifier,
 @Aplicaciones nvarchar(max),@Recibido decimal(28,8),@Nombre nvarchar(100),@Familia nvarchar(100);
DECLARE @Salida TABLE(Registro nvarchar(10));
DECLARE @Alumnos TABLE(N int,I int,Registro nvarchar(10),GrupoId int);
DECLARE @Clases TABLE(N int,Orden int,AsignacionId int);
WHILE @n<=3
BEGIN
 SELECT @Modalidad=Modalidad,@Grado=Grado,@Precio=Precio,@Edad=Nacimiento FROM @Niveles WHERE N=@n;
 INSERT dbo.ModalidadAcademica(Nombre) VALUES(@Modalidad); SET @Mod=SCOPE_IDENTITY();
 INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(CONCAT(N'Aula demo ',@n),N'Planta baja · demostración',25); SET @Aula=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Matricula,@Mod,@AnioId,450); SET @TarifaMat=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Mensualidad,@Mod,@AnioId,@Precio); SET @TarifaMen=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Bus,@Mod,@AnioId,150);
 SELECT @VMat=Version FROM dbo.TarifaArancel WHERE Id=@TarifaMat;
 SELECT @VMen=Version FROM dbo.TarifaArancel WHERE Id=@TarifaMen;
 SET @Json=(SELECT N'Pensum' Accion,@AnioId AnioId,@Mod ModalidadId,@Grado Nivel FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Plan OUTPUT;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SET @Nombre=CASE WHEN @n=1 THEN CASE @i WHEN 1 THEN N'Comunicación y lenguaje' ELSE N'Expresión y creatividad' END
   ELSE CASE @i WHEN 1 THEN N'Matemáticas' ELSE N'Lengua y literatura' END END;
  -- Una asignatura por código de nivel mantiene la demostración simple y visible.
  INSERT dbo.Asignatura(Codigo,Nombre) VALUES(CONCAT(N'DEMO-',@n,N'-',@i),@Nombre); SET @Materia=SCOPE_IDENTITY();
  SET @Json=(SELECT N'Materia' Accion,@Plan PensumId,@Materia AsignaturaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Planificacion_Guardar @Json,@Admin;
  SET @i+=1;
 END;
 SET @Json=(SELECT N'Grupo' Accion,@Plan PensumId,@Periodo PeriodoId,@Turno TurnoId,@Aula AulaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Grupo OUTPUT;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SELECT @Materia=Id FROM dbo.Asignatura WHERE Codigo=CONCAT(N'DEMO-',@n,N'-',@i);
  SET @Json=(SELECT N'Docente' Accion,@Grupo GrupoId,@Materia AsignaturaId,@Profesor DocenteId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Asignacion OUTPUT;
  INSERT @Clases VALUES(@n,@i,@Asignacion);
  DECLARE @Dia int=1,@Inicio time,@Fin time;
  SET @Inicio=CONVERT(time,DATEADD(minute,(@n-1)*100+(@i-1)*40,CONVERT(datetime,'19000101 07:00')));
  SET @Fin=CONVERT(time,DATEADD(minute,40,CONVERT(datetime,@Inicio)));
  WHILE @Dia<=CASE @n WHEN 1 THEN 2 WHEN 2 THEN 5 ELSE 3 END
  BEGIN
   SET @Json=(SELECT N'Horario' Accion,@Asignacion AsignacionId,@Dia Dia,@Inicio Inicio,@Fin Fin FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
   SET @Dia+=1;
  END;
  SET @i+=1;
 END;

 SET @i=1;
 WHILE @i<=4
 BEGIN
  SET @Nombre=CONCAT(N'Demo ',@Modalidad,N' ',CHOOSE(@i,N'Ana López',N'Luis Rivera',N'Sofía Castro',N'Diego Torres'));
  SET @Familia=CONCAT(N'Responsable ficticio ',@n,N'-',@i);
  SET @Json=(SELECT @Nombre NombreEstudiante,@Modalidad Modalidad,@Grado Grado,
   DATEFROMPARTS(@Anio-@Edad,1,15) FechaNacimiento,
   CASE WHEN @i IN (1,3) THEN N'F' ELSE N'M' END Sexo,N'Dirección ficticia · demostración' Direccion,
   N'Nuevo' TipoIngreso,N'Madre' Tutor,N'Alta de datos ficticios para presentación' Motivo,
   JSON_QUERY((SELECT @Familia Nombre,N'00000000' Telefono,N'Contacto ficticio' Direccion FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Madre,
   JSON_QUERY((SELECT N'Padre ficticio' Nombre,N'00000000' Telefono FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Padre,
   N'No reportadas (dato ficticio)' Alergias,CAST(1 AS bit) PartidaRecibida,CAST(1 AS bit) IdentificacionTutorRecibida
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DELETE @Salida; INSERT @Salida EXEC dbo.Expediente_Guardar @Json,@Admin;
  SELECT @Registro=Registro FROM @Salida;
  INSERT @Alumnos VALUES(@n,@i,@Registro,@Grupo);
  SET @Op=NEWID();
  EXEC dbo.Cargos_Generar @Admin,@Op,@Registro,@TarifaMat,@VMat;
  SELECT @Cargo=Id FROM dbo.CargoEstudiante WHERE Registro=@Registro AND TarifaId=@TarifaMat AND Referencia=N'ANUAL';
  SET @Aplicaciones=(SELECT @Cargo CargoId,CAST(450 AS decimal(18,2)) Importe FOR JSON PATH);
  SET @Op=NEWID();
  EXEC dbo.CobroMultiple_Registrar @Cajero,@Op,@Registro,@Familia,N'Efectivo',NULL,450,0,@Aplicaciones;
  -- El cuarto alumno queda listo para inscribir durante la presentación.
  IF @i<=3
  BEGIN
   SET @Json=(SELECT N'Estudiante' Accion,@Grupo GrupoId,@Registro Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
  END;
  SET @Op=NEWID();
  DECLARE @Mes int=MONTH(SYSUTCDATETIME());
  EXEC dbo.Cargos_Generar @Admin,@Op,@Registro,@TarifaMen,@VMen,@Mes;
  SELECT @Cargo=Id FROM dbo.CargoEstudiante WHERE Registro=@Registro AND TarifaId=@TarifaMen;
  IF @i<=2
  BEGIN
   SET @Recibido=CASE WHEN @i=1 THEN @Precio ELSE @Precio/2 END;
   SET @Aplicaciones=(SELECT @Cargo CargoId,@Recibido Importe FOR JSON PATH);
   SET @Op=NEWID();
   EXEC dbo.CobroMultiple_Registrar @Cajero,@Op,@Registro,@Familia,N'Efectivo',NULL,@Recibido,0,@Aplicaciones;
  END;
  IF @i=3
  BEGIN
   SET @Op=NEWID();
   EXEC dbo.Anticipo_Registrar @Cajero,@Op,@Registro,@Familia,N'Efectivo',NULL,150;
  END;
  SET @i+=1;
 END;
 SET @n+=1;
END;


IF (SELECT COUNT(*) FROM dbo.Estudiantes)<>12 OR (SELECT COUNT(*) FROM dbo.GrupoEstudiante)<>9
 OR (SELECT COUNT(*) FROM dbo.AspNetUsers)<>3 OR NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N'La demostración base no terminó correctamente.',1;
IF (SELECT COUNT(*) FROM dbo.CargoEstudiante)<>24
 OR (SELECT COUNT(*) FROM dbo.ReciboMultiple)<>21
 OR (SELECT COUNT(*) FROM dbo.HorarioClaseVigente)<>20
 OR (SELECT SUM(Disponible) FROM dbo.SaldoFinanciero)<>450
 OR NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula C JOIN dbo.Arancel A ON A.Id=C.ArancelId WHERE C.Id=1 AND A.Codigo=N'MAT')
 THROW 54902,N'Los cargos, recibos, horarios o saldos demo no coinciden con lo esperado.',1;
