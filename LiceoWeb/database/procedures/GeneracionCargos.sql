CREATE OR ALTER PROCEDURE dbo.Cargos_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53601,N'Solo administración puede generar cargos.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Cargos_Configurar @UsuarioId nvarchar(450),@ArancelId int,@Periodicidad nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @Periodicidad IS NULL OR @Periodicidad NOT IN ('Anual','Mensual','Eventual') THROW 53602,N'Periodicidad inválida.',1;
 IF @@TRANCOUNT<>0 THROW 53600,N'No usar transacción externa.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N'Finanzas está ocupado.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@ArancelId AND Activo=1) THROW 53602,N'Arancel inexistente o inactivo.',1;
 IF EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId AND Periodicidad<>@Periodicidad) THROW 53602,N'La periodicidad ya fue definida. Su cambio requiere revisar cargos e historial.',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@ArancelId AND CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END<>@Periodicidad) THROW 53602,N'La periodicidad contradice el mapeo histórico. Revise la conciliación.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId)
 BEGIN
  INSERT dbo.ConfiguracionCargo VALUES(@ArancelId,@Periodicidad);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@ArancelId),@Op uniqueidentifier=NEWID(),@Json nvarchar(max)=(SELECT @Periodicidad Periodicidad FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,'ConfigurarCargo','Arancel',@Id,@Op,NULL,@Json;
 END;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Cargos_Generar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@TarifaId int,@VersionTarifa binary(8),@Mes int=NULL,@Evento nvarchar(30)=NULL,@Vencimiento date=NULL,@PermitirTransaccion bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 AND ISNULL(@PermitirTransaccion,0)=0 THROW 53600,N'No usar transacción externa.',1;
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000' OR @VersionTarifa IS NULL THROW 53602,N'Falta operación o versión de tarifa.',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),'');
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@TarifaId TarifaId,CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Mes Mes,@Evento Evento,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@CargoId bigint,@Lock int,@Anio int,@ArancelId int,@AnioId int,@Importe decimal(18,2),@Nombre nvarchar(150),@Periodicidad nvarchar(10),@Referencia nvarchar(80),@Descripcion nvarchar(200);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N'Finanzas está ocupado. Reintente la misma operación.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N'Aplique y valide el corte financiero antes de generar cargos.',1;
 SELECT @CargoId=CargoId FROM dbo.GeneracionCargo WHERE Operacion=@Operacion;
 IF @CargoId IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.GeneracionCargo WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53602,N'La operación ya se usó con otros datos. Consulte la cuenta.',1;
  COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;RETURN;
 END;
 -- El precio procede siempre de la tarifa y la modalidad debe coincidir con el expediente.
 SELECT @ArancelId=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Importe=T.Importe,@Nombre=A.Nombre,@Periodicidad=F.Periodicidad
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Arancel A ON A.Id=T.ArancelId
 JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.Estudiantes E ON E.Registro=@Registro AND E.Modalidad=M.Nombre
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND E.Estado='Activo';
 IF @Importe IS NULL OR @Importe<=0 THROW 53602,N'Revise estudiante activo, modalidad, periodicidad y tarifa vigente. Si cambió la tarifa, vuelva a consultar.',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@ArancelId AND CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END<>@Periodicidad) THROW 53602,N'La periodicidad contradice los conceptos históricos.',1;
 IF @Periodicidad='Mensual' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL) THROW 53602,N'El cargo mensual requiere mes de 1 a 12 y ningún evento.',1;
 IF @Periodicidad='Anual' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL) THROW 53602,N'El cargo anual no lleva mes ni evento.',1;
 IF @Periodicidad='Eventual' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Z0-9_-]%') THROW 53602,N'El evento requiere código de letras, números, guion o guion bajo; no lleva mes.',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N'El vencimiento debe pertenecer al año de la tarifa.',1;
 SET @Referencia=CASE @Periodicidad WHEN 'Anual' THEN 'ANUAL' WHEN 'Mensual' THEN 'MES:'+RIGHT('0'+CONVERT(varchar(2),@Mes),2) ELSE 'EVENTO:'+@Evento END;
 IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante C WITH(UPDLOCK,HOLDLOCK) JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId WHERE C.Registro=@Registro AND T.ArancelId=@ArancelId AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THROW 53602,N'Ya existe ese cargo, incluso si fue anulado. Consulte la cuenta.',1;
 -- Incluye obligaciones antiguas pagadas (CargoId nulo): no volver a facturarlas.
 IF EXISTS(SELECT 1 FROM dbo.ObligacionMigrada O JOIN dbo.RevisionObligacion R ON R.Id=O.RevisionId JOIN dbo.TarifaArancel T ON T.Id=R.TarifaId
 LEFT JOIN dbo.Mensualidades M ON O.Origen='Mensualidades' AND M.Id=O.OrigenId
 WHERE R.Registro=@Registro AND T.ArancelId=@ArancelId AND T.AnioId=@AnioId AND (O.Origen<>'Mensualidades' OR @Periodicidad<>'Mensual' OR M.Numero_Mes=@Mes OR M.Id IS NULL))
 THROW 53602,N'Existe una obligación histórica para este concepto y período; consulte la cuenta y la conciliación.',1;
 SET @Descripcion=LEFT(@Nombre,150)+N' · '+CONVERT(nvarchar(4),@Anio)+N' · '+@Referencia;
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento) VALUES(@Registro,@TarifaId,@Referencia,@Descripcion,@Importe,@Vencimiento);
 SET @CargoId=SCOPE_IDENTITY();
 INSERT dbo.GeneracionCargo(Operacion,CargoId,SolicitudHash,UsuarioId) VALUES(@Operacion,@CargoId,@Hash,@UsuarioId);
 DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@CargoId),@Json nvarchar(max)=(SELECT @Registro Registro,@TarifaId TarifaId,@Referencia Referencia,@Descripcion Descripcion,@Importe Importe,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'GenerarCargo','CargoEstudiante',@Id,@Operacion,NULL,@Json;
 COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Cargos_Pantalla @UsuarioId nvarchar(450),@Registro nvarchar(10)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 SELECT CONVERT(bit,ISNULL((SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1),0)) Migrado;
 SELECT A.Id,A.Nombre,F.Periodicidad FROM dbo.Arancel A LEFT JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id WHERE A.Activo=1 ORDER BY A.Nombre;
 SELECT Registro,NombreEstudiante,Modalidad,Estado FROM dbo.Estudiantes WHERE Registro=@Registro;
 SELECT T.Id,A.Nombre,Y.Anio,M.Nombre Modalidad,T.Importe,F.Periodicidad,CONVERT(varchar(18),CONVERT(binary(8),T.Version),1) VersionTarifa
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 JOIN dbo.Estudiantes E ON E.Registro=@Registro AND E.Modalidad=M.Nombre
 WHERE T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND E.Estado='Activo' AND T.Importe>0 ORDER BY Y.Anio DESC,A.Nombre;
 SELECT C.ArancelId,A.Nombre FROM dbo.ConfiguracionMatricula C JOIN dbo.Arancel A ON A.Id=C.ArancelId WHERE C.Id=1;
END;
GO
