CREATE OR ALTER PROCEDURE dbo.Expediente_Obtener @Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Json nvarchar(max), @Version varchar(18);
 SELECT @Json=FormularioJson,@Version=CONVERT(varchar(18),Version,1)
 FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro;
 IF @Json IS NOT NULL
 BEGIN
  SELECT JSON_MODIFY(JSON_MODIFY(@Json,'$.Registro',@Registro),'$.Version',@Version); RETURN;
 END;
 SELECT (SELECT E.Registro,E.NombreEstudiante,E.Modalidad,E.Grado,
 CONVERT(varchar(10),E.FechaNacimiento,23) FechaNacimiento,E.Sexo,E.Direccion,
 'Nuevo' TipoIngreso,'Otro' Tutor,'Ampliación de expediente existente' Motivo,
 JSON_QUERY((SELECT E.NombreTutor Nombre,E.Telefono Telefono FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Otro
 FROM dbo.Estudiantes E WHERE E.Registro=@Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Expediente_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52110,N'Formulario inválido.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@UsuarioId AND R.Name=N'Administrador')
 THROW 52111,N'Se requiere administrador.',1;
 DECLARE @Registro nvarchar(10)=NULLIF(JSON_VALUE(@Datos,'$.Registro'),''),
 @Nombre nvarchar(100)=JSON_VALUE(@Datos,'$.NombreEstudiante'),
 @Modalidad nvarchar(20)=JSON_VALUE(@Datos,'$.Modalidad'),@Grado nvarchar(50)=JSON_VALUE(@Datos,'$.Grado'),
 @Nacimiento date=TRY_CONVERT(date,JSON_VALUE(@Datos,'$.FechaNacimiento')),
 @Sexo char(1)=JSON_VALUE(@Datos,'$.Sexo'),@Direccion nvarchar(200)=JSON_VALUE(@Datos,'$.Direccion'),
 @Tutor nvarchar(20)=JSON_VALUE(@Datos,'$.Tutor'),@Motivo nvarchar(500)=JSON_VALUE(@Datos,'$.Motivo'),
 @Hoy date=CONVERT(date,SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Central America Standard Time'),
 @Ingreso nvarchar(20)=JSON_VALUE(@Datos,'$.TipoIngreso'),@Codigo nvarchar(100)=JSON_VALUE(@Datos,'$.CodigoTraslado'),
 @Centro nvarchar(200)=JSON_VALUE(@Datos,'$.CentroProcedencia'),@Version varchar(18)=JSON_VALUE(@Datos,'$.Version');
 IF NULLIF(LTRIM(RTRIM(@Nombre)),'') IS NULL OR @Nacimiento IS NULL OR @Nacimiento>@Hoy OR @Nacimiento<DATEADD(year,-100,@Hoy)
 OR @Tutor IS NULL OR @Tutor NOT IN ('Padre','Madre','Otro') OR NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL
 THROW 52112,N'Revise nombre, fecha de nacimiento, tutor y motivo.',1;
 IF @Ingreso IS NULL OR @Ingreso NOT IN ('Nuevo','Traslado') OR (@Ingreso='Traslado' AND (NULLIF(LTRIM(RTRIM(@Codigo)),'') IS NULL OR NULLIF(LTRIM(RTRIM(@Centro)),'') IS NULL))
 THROW 52113,N'Revise los datos del traslado.',1;
 DECLARE @Familia TABLE(Vinculo nvarchar(20),Nombre nvarchar(200),Direccion nvarchar(300),CentroTrabajo nvarchar(200),Telefono nvarchar(30),Parentesco nvarchar(50));
 INSERT @Familia SELECT J.[key],F.* FROM OPENJSON(@Datos) J
 CROSS APPLY OPENJSON(CASE WHEN J.type=5 THEN J.value ELSE N'{}' END) WITH(Nombre nvarchar(200),Direccion nvarchar(300),CentroTrabajo nvarchar(200),Telefono nvarchar(30),Parentesco nvarchar(50)) F
 WHERE J.[key] IN ('Padre','Madre','Otro') AND J.type=5 AND NULLIF(LTRIM(RTRIM(F.Nombre)),'') IS NOT NULL;
 DECLARE @TutorNombre nvarchar(200),@Telefono nvarchar(30);
 SELECT @TutorNombre=Nombre,@Telefono=Telefono FROM @Familia WHERE Vinculo=@Tutor;
 IF @TutorNombre IS NULL OR NULLIF(LTRIM(RTRIM(@Telefono)),'') IS NULL OR (@Tutor='Otro' AND NOT EXISTS(SELECT 1 FROM @Familia WHERE Vinculo='Otro' AND NULLIF(LTRIM(RTRIM(Parentesco)),'') IS NOT NULL))
 THROW 52114,N'El tutor requiere nombre, teléfono y parentesco si es un tercero.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Anterior nvarchar(max),@VersionActual varchar(18),@Existe bit=0;
 IF @Registro IS NOT NULL
 BEGIN
  SELECT @Existe=1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
  IF @Existe=0 THROW 52115,N'Estudiante inexistente.',1;
  SELECT @Anterior=FormularioJson,@VersionActual=CONVERT(varchar(18),Version,1) FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro;
  IF ISNULL(@Version,'')<>ISNULL(@VersionActual,'') THROW 52116,N'Otro usuario actualizó el expediente. Recargue antes de guardar.',1;
  UPDATE dbo.Estudiantes SET NombreEstudiante=@Nombre,Modalidad=@Modalidad,Grado=@Grado,FechaNacimiento=@Nacimiento,Sexo=@Sexo,Direccion=@Direccion,NombreTutor=@TutorNombre,Telefono=@Telefono WHERE Registro=@Registro;
 END
 ELSE
 BEGIN
  DECLARE @Creado TABLE(Registro nvarchar(10));
  INSERT dbo.Estudiantes(NombreEstudiante,Modalidad,Grado,FechaNacimiento,Sexo,Direccion,NombreTutor,Telefono)
  OUTPUT inserted.Registro INTO @Creado VALUES(@Nombre,@Modalidad,@Grado,@Nacimiento,@Sexo,@Direccion,@TutorNombre,@Telefono);
  SELECT @Registro=Registro FROM @Creado;
 END;
 IF NOT EXISTS(SELECT 1 FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro)
  INSERT dbo.ExpedienteAmpliado(Registro,TipoIngreso,CodigoTraslado) VALUES(@Registro,@Ingreso,@Codigo);
 UPDATE dbo.ExpedienteAmpliado SET Identificacion=JSON_VALUE(@Datos,'$.Identificacion'),TipoSangre=JSON_VALUE(@Datos,'$.TipoSangre'),
 Alergias=JSON_VALUE(@Datos,'$.Alergias'),Padecimientos=JSON_VALUE(@Datos,'$.Padecimientos'),IndicacionesEmergencia=JSON_VALUE(@Datos,'$.IndicacionesEmergencia'),
 TipoIngreso=@Ingreso,CodigoTraslado=CASE WHEN @Ingreso='Traslado' THEN @Codigo END,CentroProcedencia=CASE WHEN @Ingreso='Traslado' THEN @Centro END,
 FormularioJson=JSON_MODIFY(JSON_MODIFY(@Datos,'$.Registro',@Registro),'$.Version',NULL) WHERE Registro=@Registro;
 -- Cambiar responsables conserva las versiones previas, incluso cambios el mismo día.
 IF @Anterior IS NULL OR ISNULL(JSON_QUERY(@Anterior,'$.Padre'),'')<>ISNULL(JSON_QUERY(@Datos,'$.Padre'),'')
 OR ISNULL(JSON_QUERY(@Anterior,'$.Madre'),'')<>ISNULL(JSON_QUERY(@Datos,'$.Madre'),'')
 OR ISNULL(JSON_QUERY(@Anterior,'$.Otro'),'')<>ISNULL(JSON_QUERY(@Datos,'$.Otro'),'')
 OR ISNULL(JSON_VALUE(@Anterior,'$.Tutor'),'')<>@Tutor
 OR ISNULL(JSON_VALUE(@Anterior,'$.DocumentoTutela'),'')<>ISNULL(JSON_VALUE(@Datos,'$.DocumentoTutela'),'')
 BEGIN
  UPDATE T SET Hasta=@Hoy FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro AND T.Hasta IS NULL;
  UPDATE dbo.ResponsableEstudiante SET Hasta=@Hoy WHERE Registro=@Registro AND Hasta IS NULL;
  INSERT dbo.ResponsableEstudiante(Registro,Vinculo,Nombre,Direccion,CentroTrabajo,Telefono,Parentesco,Desde)
  SELECT @Registro,Vinculo,Nombre,Direccion,CentroTrabajo,Telefono,Parentesco,@Hoy FROM @Familia;
  INSERT dbo.TutelaEstudiante(ResponsableId,Desde,Motivo,UsuarioId,NombreHistorico,DocumentoReferencia)
  SELECT Id,@Hoy,@Motivo,@UsuarioId,Nombre,JSON_VALUE(@Datos,'$.DocumentoTutela') FROM dbo.ResponsableEstudiante WHERE Registro=@Registro AND Hasta IS NULL AND Vinculo=@Tutor;
 END;
 INSERT dbo.DocumentoEstudiante(Registro,Tipo,Estado,Fecha,UsuarioId)
 SELECT @Registro,V.Tipo,CASE WHEN JSON_VALUE(@Datos,V.Ruta)='true' THEN 'Recibido' ELSE 'Pendiente' END,@Hoy,@UsuarioId
 FROM (VALUES('Partida de nacimiento','$.PartidaRecibida'),('Identificación tutor','$.IdentificacionTutorRecibida'),('Boletín','$.BoletinRecibido'),('Traslado','$.TrasladoRecibido')) V(Tipo,Ruta)
 WHERE @Anterior IS NULL OR ISNULL(JSON_VALUE(@Anterior,V.Ruta),'false')<>ISNULL(JSON_VALUE(@Datos,V.Ruta),'false');
 DECLARE @Operacion uniqueidentifier=NEWID();
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'GuardarExpediente',@Entidad=N'Estudiantes',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 SELECT @Registro;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Estudiante_DarBaja @Registro nvarchar(10), @Motivo nvarchar(500), @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@UsuarioId AND R.Name=N'Administrador') THROW 52111,N'Se requiere administrador.',1;
 IF NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL THROW 52112,N'Indique el motivo de la baja.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Estado nvarchar(10);
 SELECT @Estado=Estado FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Estado IS NULL THROW 52115,N'Estudiante inexistente.',1;
 IF @Estado<>'Activo' THROW 52112,N'El estudiante ya está inactivo.',1;
 UPDATE dbo.Estudiantes SET Estado='Inactivo' WHERE Registro=@Registro;
 INSERT dbo.Historial_Bajas(RegistroEstudiante,Motivo,FechaBaja)
 VALUES(@Registro,@Motivo,CONVERT(datetime,SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Central America Standard Time'));
 DECLARE @Operacion uniqueidentifier=NEWID();
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'DarBajaEstudiante',@Entidad=N'Estudiantes',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
