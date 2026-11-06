CREATE OR ALTER PROCEDURE dbo.Cargos_GenerarModalidad
 @UsuarioId nvarchar(450), @TarifaId int, @VersionTarifa binary(8),
 @Mes int=NULL, @Evento nvarchar(30)=NULL, @Vencimiento date=NULL,
 @Aplicar bit=0, @Huella binary(32)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53600,N'No usar transacción externa.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N'Finanzas está ocupado. Reintenta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N'El corte financiero debe estar aplicado antes de generar cargos.',1;
 DECLARE @Arancel int,@AnioId int,@Anio int,@Modalidad nvarchar(80),@Periodicidad nvarchar(10),@Importe decimal(18,2),@Referencia nvarchar(80);
 SELECT @Arancel=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Modalidad=M.Nombre,@Periodicidad=F.Periodicidad,@Importe=T.Importe
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND T.Importe>0;
 IF @Arancel IS NULL THROW 53602,N'La tarifa cambió o ya no está disponible. Vuelve a seleccionarla.',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@Arancel AND CASE WHEN Origen='Mensualidades' THEN 'Mensual' ELSE 'Anual' END<>@Periodicidad)
 THROW 53602,N'La periodicidad contradice los conceptos históricos.',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),N'');
 IF (@Periodicidad='Mensual' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL))
 OR (@Periodicidad='Anual' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL))
 OR (@Periodicidad='Eventual' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE '%[^A-Z0-9_-]%'))
 THROW 53602,N'Indica el mes para una tarifa mensual o el código para una eventual. Las anuales no llevan esos datos.',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N'El vencimiento debe pertenecer al año de la tarifa.',1;
 SET @Referencia=CASE @Periodicidad WHEN 'Anual' THEN 'ANUAL' WHEN 'Mensual' THEN 'MES:'+RIGHT('0'+CONVERT(varchar(2),@Mes),2) ELSE 'EVENTO:'+@Evento END;

 DECLARE @Alumnos TABLE(Registro nvarchar(10) PRIMARY KEY, Motivo nvarchar(60) NULL);
 INSERT @Alumnos(Registro,Motivo)
 SELECT E.Registro,CASE
 WHEN EXISTS(SELECT 1 FROM dbo.CargoEstudiante C JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId
  WHERE C.Registro=E.Registro AND T.ArancelId=@Arancel AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THEN N'Cargo ya registrado (incluye anulados)'
 WHEN EXISTS(SELECT 1 FROM dbo.ObligacionMigrada O JOIN dbo.RevisionObligacion R ON R.Id=O.RevisionId
  JOIN dbo.TarifaArancel T ON T.Id=R.TarifaId LEFT JOIN dbo.Mensualidades M ON O.Origen='Mensualidades' AND M.Id=O.OrigenId
  WHERE R.Registro=E.Registro AND T.ArancelId=@Arancel AND T.AnioId=@AnioId AND (O.Origen<>'Mensualidades' OR @Periodicidad<>'Mensual' OR M.Numero_Mes=@Mes OR M.Id IS NULL))
  THEN N'Obligación histórica'
 END
 FROM dbo.Estudiantes E WITH(HOLDLOCK) WHERE E.Estado='Activo' AND E.Modalidad=@Modalidad;

 DECLARE @Lista nvarchar(max)=(SELECT Registro,Motivo FROM @Alumnos ORDER BY Registro FOR JSON PATH,INCLUDE_NULL_VALUES);
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@TarifaId TarifaId,
 CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Referencia Referencia,@Vencimiento Vencimiento,JSON_QUERY(@Lista) Alumnos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Actual binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Cantidad int=(SELECT COUNT(*) FROM @Alumnos WHERE Motivo IS NULL);
 IF @Aplicar=1
 BEGIN
  IF @Huella IS NULL OR @Huella<>@Actual THROW 53602,N'La lista de estudiantes o los cargos cambiaron. Revisa una nueva vista previa antes de confirmar.',1;
  IF @Cantidad=0 THROW 53602,N'No hay estudiantes pendientes de este cargo.',1;
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
END;
GO
