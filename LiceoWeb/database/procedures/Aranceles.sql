CREATE OR ALTER VIEW dbo.ObligacionLegada
AS
 SELECT N'Matriculas' Origen,Id OrigenId,Registro_Estudiante Registro,Anio,Modalidad,Costo_Matricula Importe,CAST(N'Cancelado' AS nvarchar(10)) Estado,Id_Comprobante Comprobante FROM dbo.Matriculas
 UNION ALL SELECT N'Mensualidades',Id,Registro_Estudiante,Anio,Modalidad,Costo_Mensualidad,Estado,Id_Comprobante FROM dbo.Mensualidades
 UNION ALL SELECT N'Mantenimientos',Id,Registro_Estudiante,Anio,Modalidad,Costo_Mantenimiento,Estado,Id_Comprobante FROM dbo.Mantenimientos
 UNION ALL SELECT N'EvBoTaS',Id,Registro_Estudiante,Anio,Modalidad,Costo_EvBoTa,Estado,Id_Comprobante FROM dbo.EvBoTaS
 UNION ALL SELECT N'Promociones',Id,Registro_Estudiante,Anio,Modalidad,Costo_Promocion,Estado,Id_Comprobante FROM dbo.Promociones;
GO
CREATE OR ALTER PROCEDURE dbo.Aranceles_Guardar @UsuarioId nvarchar(450),@Datos nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52801,N'Solo administración puede modificar estos datos.',1;
 IF ISJSON(@Datos)<>1 THROW 52800,N'Datos inválidos.',1;
 DECLARE @Accion nvarchar(20)=JSON_VALUE(@Datos,'$.Accion'),@Id int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.Id')),
 @Codigo nvarchar(30)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Codigo')),''),@Nombre nvarchar(150)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Nombre')),''),
 @Arancel int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.ArancelId')),@Modalidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.ModalidadId')),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,'$.AnioId')),
 @Importe decimal(18,2)=TRY_CONVERT(decimal(18,2),JSON_VALUE(@Datos,'$.Importe')),@Activo bit=CASE JSON_VALUE(@Datos,'$.Activo') WHEN 'true' THEN 1 WHEN 'false' THEN 0 END,
 @Origen nvarchar(30)=JSON_VALUE(@Datos,'$.Origen'),@Motivo nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,'$.Motivo')),''),
 @Version binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,'$.Version'),1),@Lock int,@Operacion uniqueidentifier=NEWID(),@Antes nvarchar(max),@Despues nvarchar(max);
 IF @Accion IS NULL OR @Accion NOT IN ('Arancel','Tarifa','Mapeo','Preparar') OR @Motivo IS NULL OR @Id IS NULL OR @Id<0 THROW 52800,N'Operación o motivo inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 52802,N'Hay otra operación en curso. Reintenta.',1;
 IF @Accion='Arancel'
 BEGIN
  IF @Codigo IS NULL OR @Nombre IS NULL OR @Activo IS NULL THROW 52800,N'Completa código, nombre y estado.',1;
  IF @Id=0
  BEGIN
   INSERT dbo.Arancel(Codigo,Nombre,Activo) VALUES(@Codigo,@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N'El arancel cambió. Recarga antes de editar.',1;
   SET @Antes=(SELECT Codigo,Nombre,Activo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   IF EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE ArancelId=@Id) OR EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@Id)
    IF EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Id AND (Codigo<>@Codigo OR Nombre<>@Nombre)) THROW 52804,N'El arancel está referenciado. Solo puede cambiar su estado.',1;
   UPDATE dbo.Arancel SET Codigo=@Codigo,Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Codigo,Nombre,Activo,@Motivo Motivo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion='Tarifa'
 BEGIN
  IF @Importe IS NULL OR @Importe<0 OR @Activo IS NULL THROW 52800,N'Importe o estado inválido.',1;
  IF TRY_CONVERT(decimal(38,10),JSON_VALUE(@Datos,'$.Importe'))<>@Importe THROW 52800,N'El importe admite hasta dos decimales.',1;
  IF @Id=0
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Arancel AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Modalidad AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Anio AND Activo=1) THROW 52804,N'Selecciona arancel, modalidad y año activos.',1;
   INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe,Activo) VALUES(@Arancel,@Modalidad,@Anio,@Importe,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.HistorialTarifa(TarifaId,ImporteNuevo,ActivoNuevo,Motivo,UsuarioId) VALUES(@Id,@Importe,@Activo,@Motivo,@UsuarioId);
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N'La tarifa cambió. Recarga antes de editar.',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE Id=@Id AND ArancelId=@Arancel AND ModalidadId=@Modalidad AND AnioId=@Anio) THROW 52804,N'No se cambia el arancel, modalidad ni año de una tarifa. Crea otra combinación.',1;
   SET @Antes=(SELECT Importe,Activo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   INSERT dbo.HistorialTarifa(TarifaId,ImporteAnterior,ImporteNuevo,ActivoAnterior,ActivoNuevo,Motivo,UsuarioId) SELECT Id,Importe,@Importe,Activo,@Activo,@Motivo,@UsuarioId FROM dbo.TarifaArancel WHERE Id=@Id;
   UPDATE dbo.TarifaArancel SET Importe=@Importe,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Importe,Activo,@Motivo Motivo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion='Mapeo'
 BEGIN
  IF @Origen IS NULL OR @Origen NOT IN ('Matriculas','Mensualidades','Mantenimientos','EvBoTaS','Promociones') OR NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Arancel AND Activo=1) THROW 52804,N'Origen o arancel inválido.',1;
  IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE Origen=@Origen AND ArancelId<>@Arancel) THROW 52804,N'El origen ya está vinculado. La corrección del mapeo requiere revisión de sus dependencias.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE Origen=@Origen)
   INSERT dbo.MapaConceptoLegado(Origen,ArancelId,UsuarioId) VALUES(@Origen,@Arancel,@UsuarioId);
  SET @Despues=(SELECT @Origen Origen,@Arancel ArancelId,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion='Preparar'
 BEGIN
  IF (SELECT COUNT(*) FROM dbo.MapaConceptoLegado)<>5 THROW 52804,N'Vincula los cinco conceptos antes de preparar.',1;
  -- HOLDLOCK conserva una lectura consistente durante esta captura; no es el corte financiero.
  INSERT dbo.PreparacionObligacion(Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante,ArancelId,UsuarioId)
  SELECT O.Origen,O.OrigenId,O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante,M.ArancelId,@UsuarioId
  FROM dbo.ObligacionLegada O WITH(HOLDLOCK) JOIN dbo.MapaConceptoLegado M ON M.Origen=O.Origen
  WHERE NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P WITH(UPDLOCK,HOLDLOCK) WHERE P.Origen=O.Origen AND P.OrigenId=O.OrigenId);
  DECLARE @Cantidad int=@@ROWCOUNT;
  SET @Despues=(SELECT @Cantidad NuevasFilas,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 DECLARE @AccionAudit nvarchar(50)=N'Finanzas_'+@Accion,@RegistroAudit nvarchar(100)=CASE WHEN @Accion='Mapeo' THEN @Origen ELSE CONVERT(nvarchar(100),@Id) END;
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N'CatalogoFinanciero',@RegistroId=@RegistroAudit,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Aranceles_Consultar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52801,N'Acceso exclusivo de administración.',1;
 SELECT Id,Codigo,Nombre,Activo,CONVERT(varchar(18),Version,1) Version FROM dbo.Arancel ORDER BY Nombre;
 SELECT T.Id,T.ArancelId,T.ModalidadId,T.AnioId,A.Nombre Arancel,M.Nombre Modalidad,Y.Anio,T.Importe,T.Activo,CONVERT(varchar(18),T.Version,1) Version
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId ORDER BY Y.Anio DESC,A.Nombre,M.Nombre;
 SELECT Id,CONVERT(nvarchar(10),Anio) Etiqueta,Activo FROM dbo.AnioLectivo ORDER BY Anio DESC;
 SELECT Id,Nombre Etiqueta,Activo FROM dbo.ModalidadAcademica ORDER BY Nombre;
 SELECT M.Origen,M.ArancelId,A.Nombre Arancel FROM dbo.MapaConceptoLegado M JOIN dbo.Arancel A ON A.Id=M.ArancelId ORDER BY M.Origen;
 SELECT TOP(200) H.Id,H.TarifaId,A.Nombre Arancel,H.ImporteAnterior,H.ImporteNuevo,H.ActivoAnterior,H.ActivoNuevo,H.Motivo,U.UserName Responsable,H.Fecha
 FROM dbo.HistorialTarifa H JOIN dbo.TarifaArancel T ON T.Id=H.TarifaId JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId ORDER BY H.Id DESC;
 -- Compara con la fuente actual; no sobrescribe evidencia previa ni aprueba conciliaciones.
 SELECT TOP(200) P.Origen,P.OrigenId,P.Registro,P.Anio,P.Importe,P.Estado,P.Comprobante,P.CargoId,
 CASE WHEN O.OrigenId IS NULL THEN N'ORIGEN_AUSENTE'
 WHEN EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N'ORIGEN_CAMBIO'
 ELSE N'CAPTURADO_SIN_CONCILIAR' END Revision
 FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId ORDER BY P.Origen,P.OrigenId;
 SELECT (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada) OrigenesActuales,(SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion) FilasPreparadas,
 (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada O WHERE NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P WHERE P.Origen=O.Origen AND P.OrigenId=O.OrigenId)) SinPreparar,
 (SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId WHERE O.OrigenId IS NULL OR EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante)) FuentesCambiadas;
END;
GO
