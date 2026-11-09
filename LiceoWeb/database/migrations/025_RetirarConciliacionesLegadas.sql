-- 025 · Retirar conciliaciones del sistema de escritorio.
-- Ejecutar TODO una vez con la aplicación detenida, después de 024.
-- No importa registros de escritorio. Conserva cargos, recibos, estudiantes,
-- saldos disponibles, cuentas y cortes de caja existentes.
-- Elimina las tablas de preparación/revisión y los procedimientos de traslado.
-- RevisionSaldoId se conserva nullable SIN FK como compatibilidad de scripts demo
-- distribuidos; ya no se utiliza para consultar, aprobar ni importar saldos.
-- Los archivos 001–024 son historia de instalación, no deben volverse a ejecutar.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54920,N'Cierra transacciones antes de instalar 025.',1;
IF OBJECT_ID('dbo.CorteCaja','U') IS NULL OR COL_LENGTH('dbo.ReciboMultiple','Anticipo') IS NULL
 THROW 54920,N'Instala primero la migración 024.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54920,N'Finanzas ocupada. Detén la aplicación y reintenta.',1;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54920,N'Planificación ocupada. Reintenta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1)
 THROW 54920,N'Falta el control financiero de la instalación.',1;
 DECLARE @Cargos bigint=(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante),
 @Recibos bigint=(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple),
 @Saldo decimal(38,2)=(SELECT ISNULL(SUM(Disponible),0) FROM dbo.SaldoFinanciero),
 @Cortes bigint=(SELECT COUNT_BIG(*) FROM dbo.CorteCaja);
 -- En instalación nueva los procedimientos se crean después, en orden de dependencia.
 -- En una actualización se reemplazan aquí, dentro de la misma transacción del retiro.
 IF OBJECT_ID('dbo.Cargos_Autorizar','P') IS NOT NULL
 BEGIN
 -- Dependencia vigente: Aranceles.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Aranceles_Guardar @UsuarioId nvarchar(450),@Datos nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52801,N''Solo administración puede modificar estos datos.'',1;
 IF ISJSON(@Datos)<>1 THROW 52800,N''Datos inválidos.'',1;
 DECLARE @Accion nvarchar(20)=JSON_VALUE(@Datos,''$.Accion''),@Id int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Id'')),
 @Codigo nvarchar(30)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Codigo'')),''''),@Nombre nvarchar(150)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Nombre'')),''''),
 @Arancel int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.ArancelId'')),@Modalidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.ModalidadId'')),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AnioId'')),
 @Importe decimal(18,2)=TRY_CONVERT(decimal(18,2),JSON_VALUE(@Datos,''$.Importe'')),@Activo bit=CASE JSON_VALUE(@Datos,''$.Activo'') WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 END,
 @Motivo nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Motivo'')),''''),
 @Version binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,''$.Version''),1),@Lock int,@Operacion uniqueidentifier=NEWID(),@Antes nvarchar(max),@Despues nvarchar(max);
 IF @Accion IS NULL OR @Accion NOT IN (''Arancel'',''Tarifa'') OR @Motivo IS NULL OR @Id IS NULL OR @Id<0 THROW 52800,N''Operación o motivo inválido.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52802,N''Hay otra operación en curso. Reintenta.'',1;
 IF @Accion=''Arancel''
 BEGIN
  IF @Codigo IS NULL OR @Nombre IS NULL OR @Activo IS NULL THROW 52800,N''Completa código, nombre y estado.'',1;
  IF @Id=0
  BEGIN
   INSERT dbo.Arancel(Codigo,Nombre,Activo) VALUES(@Codigo,@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N''El arancel cambió. Recarga antes de editar.'',1;
   SET @Antes=(SELECT Codigo,Nombre,Activo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   IF EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE ArancelId=@Id)
    IF EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Id AND (Codigo<>@Codigo OR Nombre<>@Nombre)) THROW 52804,N''El arancel está referenciado. Solo puede cambiar su estado.'',1;
   UPDATE dbo.Arancel SET Codigo=@Codigo,Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Codigo,Nombre,Activo,@Motivo Motivo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion=''Tarifa''
 BEGIN
  IF @Importe IS NULL OR @Importe<0 OR @Activo IS NULL THROW 52800,N''Importe o estado inválido.'',1;
  IF TRY_CONVERT(decimal(38,10),JSON_VALUE(@Datos,''$.Importe''))<>@Importe THROW 52800,N''El importe admite hasta dos decimales.'',1;
  IF @Id=0
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Arancel AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Modalidad AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Anio AND Activo=1) THROW 52804,N''Selecciona arancel, modalidad y año activos.'',1;
   INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe,Activo) VALUES(@Arancel,@Modalidad,@Anio,@Importe,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.HistorialTarifa(TarifaId,ImporteNuevo,ActivoNuevo,Motivo,UsuarioId) VALUES(@Id,@Importe,@Activo,@Motivo,@UsuarioId);
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N''La tarifa cambió. Recarga antes de editar.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE Id=@Id AND ArancelId=@Arancel AND ModalidadId=@Modalidad AND AnioId=@Anio) THROW 52804,N''No se cambia el arancel, modalidad ni año de una tarifa. Crea otra combinación.'',1;
   SET @Antes=(SELECT Importe,Activo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   INSERT dbo.HistorialTarifa(TarifaId,ImporteAnterior,ImporteNuevo,ActivoAnterior,ActivoNuevo,Motivo,UsuarioId) SELECT Id,Importe,@Importe,Activo,@Activo,@Motivo,@UsuarioId FROM dbo.TarifaArancel WHERE Id=@Id;
   UPDATE dbo.TarifaArancel SET Importe=@Importe,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Importe,Activo,@Motivo Motivo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 DECLARE @AccionAudit nvarchar(50)=N''Finanzas_''+@Accion,@RegistroAudit nvarchar(100)=CONVERT(nvarchar(100),@Id);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N''CatalogoFinanciero'',@RegistroId=@RegistroAudit,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;';
 -- Dependencia vigente: Aranceles_Consultar.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Aranceles_Consultar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52801,N''Acceso exclusivo de administración.'',1;
 SELECT A.Id,A.Codigo,A.Nombre,A.Activo,CONVERT(varchar(18),CONVERT(binary(8),A.[Version]),1) [Version] FROM dbo.Arancel A ORDER BY A.Nombre;
 SELECT T.Id,T.ArancelId,T.ModalidadId,T.AnioId,A.Nombre Arancel,M.Nombre Modalidad,Y.Anio,T.Importe,T.Activo,CONVERT(varchar(18),CONVERT(binary(8),T.[Version]),1) [Version]
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId ORDER BY Y.Anio DESC,A.Nombre,M.Nombre;
 SELECT Id,CONVERT(nvarchar(10),Anio) Etiqueta,Activo FROM dbo.AnioLectivo ORDER BY Anio DESC;
 SELECT Id,Nombre Etiqueta,Activo FROM dbo.ModalidadAcademica ORDER BY Nombre;
 SELECT TOP(200) H.Id,H.TarifaId,A.Nombre Arancel,H.ImporteAnterior,H.ImporteNuevo,H.ActivoAnterior,H.ActivoNuevo,H.Motivo,U.UserName Responsable,H.Fecha
 FROM dbo.HistorialTarifa H JOIN dbo.TarifaArancel T ON T.Id=H.TarifaId JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId ORDER BY H.Id DESC;
END;';
 -- Dependencia vigente: GeneracionCargos.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Cargos_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53601,N''Solo administración puede generar cargos.'',1;
END;';
 -- Dependencia vigente: GeneracionCargos.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Cargos_Configurar @UsuarioId nvarchar(450),@ArancelId int,@Periodicidad nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @Periodicidad IS NULL OR @Periodicidad NOT IN (''Anual'',''Mensual'',''Eventual'') THROW 53602,N''Periodicidad inválida.'',1;
 IF @@TRANCOUNT<>0 THROW 53600,N''No usar transacción externa.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@ArancelId AND Activo=1) THROW 53602,N''Arancel inexistente o inactivo.'',1;
 IF EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId AND Periodicidad<>@Periodicidad) THROW 53602,N''La periodicidad ya fue definida. Su cambio requiere revisar cargos e historial.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId)
 BEGIN
  INSERT dbo.ConfiguracionCargo VALUES(@ArancelId,@Periodicidad);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@ArancelId),@Op uniqueidentifier=NEWID(),@Json nvarchar(max)=(SELECT @Periodicidad Periodicidad FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,''ConfigurarCargo'',''Arancel'',@Id,@Op,NULL,@Json;
 END;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 -- Dependencia vigente: GeneracionCargos.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Cargos_Generar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@TarifaId int,@VersionTarifa binary(8),@Mes int=NULL,@Evento nvarchar(30)=NULL,@Vencimiento date=NULL,@PermitirTransaccion bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 AND ISNULL(@PermitirTransaccion,0)=0 THROW 53600,N''No usar transacción externa.'',1;
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR @VersionTarifa IS NULL THROW 53602,N''Falta operación o versión de tarifa.'',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),'''');
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@TarifaId TarifaId,CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Mes Mes,@Evento Evento,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@CargoId bigint,@Lock int,@Anio int,@ArancelId int,@AnioId int,@Importe decimal(18,2),@Nombre nvarchar(150),@Periodicidad nvarchar(10),@Referencia nvarchar(80),@Descripcion nvarchar(200);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado. Reintente la misma operación.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N''Actualiza la base con la migración 025 para habilitar las operaciones financieras.'',1;
 SELECT @CargoId=CargoId FROM dbo.GeneracionCargo WHERE Operacion=@Operacion;
 IF @CargoId IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.GeneracionCargo WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53602,N''La operación ya se usó con otros datos. Consulte la cuenta.'',1;
  COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;RETURN;
 END;
 -- El precio procede siempre de la tarifa y la modalidad debe coincidir con el expediente.
 SELECT @ArancelId=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Importe=T.Importe,@Nombre=A.Nombre,@Periodicidad=F.Periodicidad
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Arancel A ON A.Id=T.ArancelId
 JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.Estudiantes E ON E.Registro=@Registro AND E.Modalidad=M.Nombre
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND E.Estado=''Activo'';
 IF @Importe IS NULL OR @Importe<=0 THROW 53602,N''Revise estudiante activo, modalidad, periodicidad y tarifa vigente. Si cambió la tarifa, vuelva a consultar.'',1;
 IF @Periodicidad=''Mensual'' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL) THROW 53602,N''El cargo mensual requiere mes de 1 a 12 y ningún evento.'',1;
 IF @Periodicidad=''Anual'' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL) THROW 53602,N''El cargo anual no lleva mes ni evento.'',1;
 IF @Periodicidad=''Eventual'' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Z0-9_-]%'') THROW 53602,N''El evento requiere código de letras, números, guion o guion bajo; no lleva mes.'',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N''El vencimiento debe pertenecer al año de la tarifa.'',1;
 SET @Referencia=CASE @Periodicidad WHEN ''Anual'' THEN ''ANUAL'' WHEN ''Mensual'' THEN ''MES:''+RIGHT(''0''+CONVERT(varchar(2),@Mes),2) ELSE ''EVENTO:''+@Evento END;
 IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante C WITH(UPDLOCK,HOLDLOCK) JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId WHERE C.Registro=@Registro AND T.ArancelId=@ArancelId AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THROW 53602,N''Ya existe ese cargo, incluso si fue anulado. Consulte la cuenta.'',1;
 SET @Descripcion=LEFT(@Nombre,150)+N'' · ''+CONVERT(nvarchar(4),@Anio)+N'' · ''+@Referencia;
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento) VALUES(@Registro,@TarifaId,@Referencia,@Descripcion,@Importe,@Vencimiento);
 SET @CargoId=SCOPE_IDENTITY();
 INSERT dbo.GeneracionCargo(Operacion,CargoId,SolicitudHash,UsuarioId) VALUES(@Operacion,@CargoId,@Hash,@UsuarioId);
 DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@CargoId),@Json nvarchar(max)=(SELECT @Registro Registro,@TarifaId TarifaId,@Referencia Referencia,@Descripcion Descripcion,@Importe Importe,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''GenerarCargo'',''CargoEstudiante'',@Id,@Operacion,NULL,@Json;
 COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 -- Dependencia vigente: GeneracionCargos.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Cargos_Pantalla @UsuarioId nvarchar(450),@Registro nvarchar(10)=NULL,@Global bit=0
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 SELECT CONVERT(bit,ISNULL((SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1),0)) Migrado;
 SELECT A.Id,A.Nombre,F.Periodicidad FROM dbo.Arancel A LEFT JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id WHERE A.Activo=1 ORDER BY A.Nombre;
 SELECT Registro,NombreEstudiante,Modalidad,Estado FROM dbo.Estudiantes WHERE Registro=@Registro;
 SELECT T.Id,A.Nombre,Y.Anio,M.Nombre Modalidad,T.Importe,F.Periodicidad,CONVERT(binary(8),T.Version) VersionTarifa
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 WHERE T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND T.Importe>0
 AND (@Global=1 OR EXISTS(SELECT 1 FROM dbo.Estudiantes E WHERE E.Registro=@Registro AND E.Modalidad=M.Nombre AND E.Estado=''Activo''))
 ORDER BY Y.Anio DESC,M.Nombre,A.Nombre;
 SELECT C.ArancelId,A.Nombre FROM dbo.ConfiguracionMatricula C JOIN dbo.Arancel A ON A.Id=C.ArancelId WHERE C.Id=1;
END;';
 -- Dependencia vigente: Cargos_GenerarModalidad.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Cargos_GenerarModalidad
 @UsuarioId nvarchar(450), @TarifaId int, @VersionTarifa binary(8),
 @Mes int=NULL, @Evento nvarchar(30)=NULL, @Vencimiento date=NULL,
 @Aplicar bit=0, @Huella binary(32)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53600,N''No usar transacción externa.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado. Reintenta.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N''Actualiza la base con la migración 025 antes de generar cargos.'',1;
 DECLARE @Arancel int,@AnioId int,@Anio int,@Modalidad nvarchar(80),@Periodicidad nvarchar(10),@Importe decimal(18,2),@Referencia nvarchar(80);
 SELECT @Arancel=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Modalidad=M.Nombre,@Periodicidad=F.Periodicidad,@Importe=T.Importe
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND T.Importe>0;
 IF @Arancel IS NULL THROW 53602,N''La tarifa cambió o ya no está disponible. Vuelve a seleccionarla.'',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),N'''');
 IF (@Periodicidad=''Mensual'' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL))
 OR (@Periodicidad=''Anual'' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL))
 OR (@Periodicidad=''Eventual'' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Z0-9_-]%''))
 THROW 53602,N''Indica el mes para una tarifa mensual o el código para una eventual. Las anuales no llevan esos datos.'',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N''El vencimiento debe pertenecer al año de la tarifa.'',1;
 SET @Referencia=CASE @Periodicidad WHEN ''Anual'' THEN ''ANUAL'' WHEN ''Mensual'' THEN ''MES:''+RIGHT(''0''+CONVERT(varchar(2),@Mes),2) ELSE ''EVENTO:''+@Evento END;

 DECLARE @Alumnos TABLE(Registro nvarchar(10) PRIMARY KEY, Motivo nvarchar(60) NULL);
 INSERT @Alumnos(Registro,Motivo)
 SELECT E.Registro,CASE
 WHEN EXISTS(SELECT 1 FROM dbo.CargoEstudiante C JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId
  WHERE C.Registro=E.Registro AND T.ArancelId=@Arancel AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THEN N''Cargo ya registrado (incluye anulados)''
 END
 FROM dbo.Estudiantes E WITH(HOLDLOCK) WHERE E.Estado=''Activo'' AND E.Modalidad=@Modalidad;

 DECLARE @Lista nvarchar(max)=(SELECT Registro,Motivo FROM @Alumnos ORDER BY Registro FOR JSON PATH,INCLUDE_NULL_VALUES);
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@TarifaId TarifaId,
 CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Referencia Referencia,@Vencimiento Vencimiento,JSON_QUERY(@Lista) Alumnos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Actual binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Cantidad int=(SELECT COUNT(*) FROM @Alumnos WHERE Motivo IS NULL);
 IF @Aplicar=1
 BEGIN
  IF @Huella IS NULL OR @Huella<>@Actual THROW 53602,N''La lista de estudiantes o los cargos cambiaron. Revisa una nueva vista previa antes de confirmar.'',1;
  IF @Cantidad=0 THROW 53602,N''No hay estudiantes pendientes de este cargo.'',1;
  DECLARE @Registro nvarchar(10),@Operacion uniqueidentifier;
  WHILE EXISTS(SELECT 1 FROM @Alumnos WHERE Motivo IS NULL)
  BEGIN
   SELECT @Registro=MIN(Registro) FROM @Alumnos WHERE Motivo IS NULL;
   SET @Operacion=NEWID();
   EXEC dbo.Cargos_Generar @UsuarioId,@Operacion,@Registro,@TarifaId,@VersionTarifa,@Mes,@Evento,@Vencimiento,@PermitirTransaccion=1;
   DELETE FROM @Alumnos WHERE Registro=@Registro;
  END;
  COMMIT;
  SELECT @Cantidad Generados;
  RETURN;
 END;
 COMMIT;
 SELECT @Cantidad Pendientes,(SELECT COUNT(*) FROM @Alumnos WHERE Motivo IS NOT NULL) Omitidos,
  @Importe Importe,@Importe*@Cantidad Total,@Actual Huella;
 SELECT A.Registro,E.NombreEstudiante,A.Motivo FROM @Alumnos A
 JOIN dbo.Estudiantes E ON E.Registro=A.Registro ORDER BY E.NombreEstudiante,A.Registro;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 -- Dependencia vigente: Anticipos.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.Anticipo_Registrar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@Pagador nvarchar(200),
 @Metodo nvarchar(20),@Referencia nvarchar(100)=NULL,@Importe decimal(28,8)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 54700,N''No usar transacción externa.'',1;
 SET @Pagador=NULLIF(TRIM(@Pagador),N'''');
 SET @Referencia=NULLIF(TRIM(@Referencia),N'''');
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Pagador IS NULL OR @Metodo IS NULL OR @Metodo NOT IN (''Efectivo'',''Transferencia'')
 OR (@Metodo=''Transferencia'' AND @Referencia IS NULL)
 OR @Importe IS NULL OR @Importe<=0 OR @Importe>9999999999999999.99 OR ROUND(@Importe,2)<>@Importe
 THROW 54702,N''Revisa pagador, método, importe positivo y referencia de transferencia.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT N''Anticipo'' Tipo,@UsuarioId UsuarioId,@Registro Registro,@Pagador Pagador,
 @Metodo Metodo,@Referencia Referencia,@Importe Importe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Id bigint,@Nombre nvarchar(100),@Saldo decimal(18,2)=0,@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54703,N''Finanzas está ocupado. Reintenta desde el mismo formulario.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54702,N''El libro nuevo requiere el corte financiero aprobado.'',1;
 SELECT @Id=Id FROM dbo.ReciboMultiple WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId AND Anticipo>0)
   THROW 54702,N''La operación ya se usó con otros datos. Consulta los recibos.'',1;
  COMMIT;SELECT @Id;RETURN;
 END;
 DECLARE @CorteCajaId bigint;
 SELECT @CorteCajaId=Id FROM dbo.CorteCaja WHERE Fin IS NULL;
 IF @CorteCajaId IS NULL THROW 54802,N''La caja está cerrada. Un administrador debe abrir un nuevo corte.'',1;
 SELECT @Nombre=NombreEstudiante FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro AND Estado=''Activo'';
 IF @Nombre IS NULL THROW 54702,N''El anticipo requiere un estudiante activo.'',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Saldo+@Importe>9999999999999999.99 THROW 54702,N''El saldo resultante excede el límite permitido.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SaldoFinanciero WHERE Registro=@Registro)
  INSERT dbo.SaldoFinanciero(Registro,SaldoInicial,Disponible) VALUES(@Registro,0,0);
 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible+@Importe WHERE Registro=@Registro;
 DECLARE @Secuencia bigint=NEXT VALUE FOR dbo.Secuencia_Comprobantes;
 DECLARE @Numero nvarchar(25)=N''RC-''+CONVERT(nvarchar(20),@Secuencia);
 INSERT dbo.ReciboMultiple(Numero,Operacion,Registro,Pagador,UsuarioId,Metodo,Referencia,Recibido,Cambio,SolicitudHash,
  NombreEstudiante,SaldoAnterior,SaldoAplicado,SaldoFinal,TotalAplicado,Anticipo,CorteCajaId)
 VALUES(@Numero,@Operacion,@Registro,@Pagador,@UsuarioId,@Metodo,@Referencia,@Importe,0,@Hash,@Nombre,@Saldo,0,@Saldo+@Importe,0,@Importe,@CorteCajaId);
 SET @Id=SCOPE_IDENTITY();
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Id),
  @Json nvarchar(max)=(SELECT @Registro Registro,@Numero Numero,@Importe Anticipo,@Saldo SaldoAnterior,@Saldo+@Importe SaldoFinal FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''RegistrarAnticipo'',''ReciboMultiple'',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;SELECT @Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 -- Dependencia vigente: CortesCaja.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.CorteCaja_Consultar @UsuarioId nvarchar(450),@Id bigint=0
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Shared'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54803,N''Caja ocupada. Reintenta.'',1;
 SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1;
 SELECT C.*,U.UserName AperturaPor,V.UserName CierrePor
 FROM dbo.CorteCaja C LEFT JOIN dbo.AspNetUsers U ON U.Id=C.UsuarioApertura
 LEFT JOIN dbo.AspNetUsers V ON V.Id=C.UsuarioCierre WHERE C.Id IN(SELECT TOP(50) Id FROM dbo.CorteCaja ORDER BY Id DESC) OR C.Id=@Id ORDER BY C.Id DESC;
 IF @Id=0 SELECT @Id=Id FROM dbo.CorteCaja WHERE Fin IS NULL;
 SELECT Metodo,SUM(Entrada) Entrada,SUM(Devolucion) Devolucion,SUM(Entrada-Devolucion) Neto
 FROM (
 SELECT Metodo,Recibido-Cambio Entrada,CAST(0 AS decimal(18,2)) Devolucion FROM dbo.ReciboMultiple WHERE CorteCajaId=@Id
 UNION ALL SELECT R.Metodo,0,A.DineroDevuelto FROM dbo.AnulacionRecibo A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId WHERE A.CorteCajaId=@Id
 ) M GROUP BY Metodo;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 -- Dependencia vigente: CortesCaja.sql
 EXEC sys.sp_executesql N'CREATE OR ALTER PROCEDURE dbo.CorteCaja_Operar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Accion nvarchar(20),@CorteId bigint=0,
 @Fondo decimal(28,8)=0,@Contado decimal(28,8)=NULL,@Motivo nvarchar(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 54800,N''No usar transacción externa.'',1;
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Accion IS NULL OR @Accion NOT IN (''Abrir'',''Cerrar'',''CerrarAbrir'')
 OR @Fondo IS NULL OR @Fondo<0 OR @Fondo>9999999999999999.99 OR ROUND(@Fondo,2)<>@Fondo
 OR (@Accion<>''Abrir'' AND (@CorteId<=0 OR @Contado IS NULL OR @Contado<0 OR @Contado>9999999999999999.99 OR ROUND(@Contado,2)<>@Contado))
 OR (@Accion=''Cerrar'' AND @Fondo<>0)
 OR LEN(ISNULL(TRIM(@Motivo),N''''))<10
 THROW 54802,N''Revisa corte, efectivo contado, fondo y motivo de al menos 10 caracteres.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId Usuario,@Accion Accion,@CorteId CorteId,@Fondo Fondo,@Contado Contado,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Lock int,@Id bigint,@Siguiente bigint,@Ahora datetime2=SYSUTCDATETIME();
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54803,N''Caja ocupada. Reintenta la misma operación.'',1;
 SET @Ahora=SYSUTCDATETIME();
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 54802,N''Actualiza la base con la migración 025.'',1;
 IF EXISTS(SELECT 1 FROM dbo.EventoCorteCaja WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.EventoCorteCaja WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId)
   THROW 54802,N''La operación ya fue usada con otros datos.'',1;
  COMMIT;RETURN;
 END;
 IF @Accion=''Abrir''
 BEGIN
  IF EXISTS(SELECT 1 FROM dbo.CorteCaja WHERE Fin IS NULL) THROW 54802,N''Ya existe un corte abierto.'',1;
  INSERT dbo.CorteCaja(Inicio,UsuarioApertura,FondoApertura) VALUES(@Ahora,@UsuarioId,@Fondo);
  SET @Id=SCOPE_IDENTITY();
 END
 ELSE
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.CorteCaja WITH(UPDLOCK,HOLDLOCK) WHERE Id=@CorteId AND Fin IS NULL)
   THROW 54802,N''El corte ya no está abierto. Recarga antes de confirmar.'',1;
  DECLARE @Entrada decimal(38,2),@Devuelto decimal(38,2),@Esperado decimal(38,2),@Resumen nvarchar(max);
  SELECT @Entrada=ISNULL(SUM(Recibido-Cambio),0) FROM dbo.ReciboMultiple WHERE CorteCajaId=@CorteId AND Metodo=''Efectivo'';
  SELECT @Devuelto=ISNULL(SUM(A.DineroDevuelto),0) FROM dbo.AnulacionRecibo A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId WHERE A.CorteCajaId=@CorteId AND R.Metodo=''Efectivo'';
  SELECT @Esperado=FondoApertura+@Entrada-@Devuelto FROM dbo.CorteCaja WHERE Id=@CorteId;
  IF ABS(@Esperado)>9999999999999999.99 OR ABS(@Contado-@Esperado)>9999999999999999.99
   THROW 54802,N''El total excede el límite permitido para cerrar.'',1;
  SET @Resumen=(SELECT Metodo,SUM(Entrada) Entrada,SUM(Devolucion) Devolucion,SUM(Entrada-Devolucion) Neto FROM(
   SELECT Metodo,Recibido-Cambio Entrada,CAST(0 AS decimal(18,2)) Devolucion FROM dbo.ReciboMultiple WHERE CorteCajaId=@CorteId
   UNION ALL SELECT R.Metodo,0,A.DineroDevuelto FROM dbo.AnulacionRecibo A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId WHERE A.CorteCajaId=@CorteId
  ) M GROUP BY Metodo FOR JSON PATH);
  UPDATE dbo.CorteCaja SET Fin=@Ahora,UsuarioCierre=@UsuarioId,EfectivoEsperado=@Esperado,EfectivoContado=@Contado,
   Diferencia=@Contado-@Esperado,Motivo=@Motivo,ResumenJson=@Resumen WHERE Id=@CorteId;
  SET @Id=@CorteId;
  IF @Accion=''CerrarAbrir''
  BEGIN
   INSERT dbo.CorteCaja(Inicio,UsuarioApertura,FondoApertura) VALUES(@Ahora,@UsuarioId,@Fondo);
   SET @Siguiente=SCOPE_IDENTITY();
  END;
 END;
 INSERT dbo.EventoCorteCaja(Operacion,SolicitudHash,CorteId,SiguienteId,UsuarioId) VALUES(@Operacion,@Hash,@Id,@Siguiente,@UsuarioId);
 DECLARE @Registro nvarchar(100)=CONVERT(nvarchar(100),@Id),@Despues nvarchar(max)=(SELECT @Id CorteId,@Siguiente SiguienteId,@Accion Accion,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''GestionarCorteCaja'',''CorteCaja'',@Registro,@Operacion,NULL,@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;';
 END;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Revisar;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Consultar;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Pantalla;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Recapturar;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Instantanea;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Consultar;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Revisar;
 DROP PROCEDURE IF EXISTS dbo.CorteFinanciero_Ejecutar;
 DROP VIEW IF EXISTS dbo.ObligacionLegada;
 -- Quitar solo la FK de conciliación. Los valores y balances financieros permanecen.
 DECLARE @Sql nvarchar(max)=N'';
 SELECT @Sql+=N'ALTER TABLE dbo.SaldoFinanciero DROP CONSTRAINT '+QUOTENAME(name)+N';'
 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('dbo.SaldoFinanciero')
  AND referenced_object_id=OBJECT_ID('dbo.RevisionSaldo');
 IF @Sql<>N'' EXEC sys.sp_executesql @Sql;
 DROP TABLE IF EXISTS dbo.ObligacionMigrada;
 DROP TABLE IF EXISTS dbo.RevisionObligacion;
 DROP TABLE IF EXISTS dbo.HistorialCaptura;
 DROP TABLE IF EXISTS dbo.PreparacionObligacion;
 DROP TABLE IF EXISTS dbo.MapaConceptoLegado;
 DROP TABLE IF EXISTS dbo.RevisionSaldo;
 -- Activar el esquema web directamente; no leer ni trasladar datos de las tablas antiguas.
 -- Migrado se conserva como indicador interno de compatibilidad con los módulos vigentes.
 UPDATE dbo.ControlFinanciero SET Migrado=1,Fecha=COALESCE(Fecha,SYSUTCDATETIME()) WHERE Id=1 AND Migrado=0;
 IF @Cargos<>(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante)
 OR @Recibos<>(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple)
 OR @Saldo<>(SELECT ISNULL(SUM(Disponible),0) FROM dbo.SaldoFinanciero)
 OR @Cortes<>(SELECT COUNT_BIG(*) FROM dbo.CorteCaja)
 THROW 54920,N'Cambió un total financiero durante el retiro. Se revierte la actualización.',1;
 COMMIT;
 SELECT N'025 APLICADA: conciliaciones retiradas; operaciones financieras conservadas.' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
