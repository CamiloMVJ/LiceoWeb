CREATE OR ALTER PROCEDURE dbo.Mensualidades_GenerarLote
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@TarifaId int,@VersionTarifa binary(8),@MesInicial int,@MesFinal int,@DiaVencimiento int
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53900,N'No usar transacción externa.',1;
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000' OR @MesInicial IS NULL OR @MesFinal IS NULL OR @DiaVencimiento IS NULL OR @MesInicial NOT BETWEEN 1 AND 12 OR @MesFinal NOT BETWEEN @MesInicial AND 12 OR @DiaVencimiento NOT BETWEEN 1 AND 28 THROW 53902,N'Revise meses y día de vencimiento (1 a 28).',1;
 DECLARE @Json nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@TarifaId TarifaId,CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@MesInicial MesInicial,@MesFinal MesFinal,@DiaVencimiento DiaVencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@Hash binary(32),@Lock int,@Anio int;
 SET @Hash=HASHBYTES('SHA2_256',@Json);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53903,N'Finanzas está ocupado.',1;
 IF EXISTS(SELECT 1 FROM dbo.LoteMensualidades WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.LoteMensualidades WHERE Operacion=@Operacion AND SolicitudHash=@Hash) THROW 53902,N'Esta operación ya se utilizó con otros datos.',1;
  COMMIT;SELECT Cantidad FROM dbo.LoteMensualidades WHERE Operacion=@Operacion;RETURN;
 END;
 SELECT @Anio=Y.Anio FROM dbo.TarifaArancel T JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 JOIN dbo.ConfiguracionCargo F ON F.ArancelId=T.ArancelId AND F.Periodicidad='Mensual'
 JOIN dbo.MatriculaAcademica A ON A.Registro=@Registro AND A.Anio=Y.Anio AND A.Modalidad=M.Nombre WHERE T.Id=@TarifaId;
 IF @Anio IS NULL THROW 53902,N'Requiere matrícula académica del año/modalidad y una tarifa mensual.',1;
 DECLARE @Mes int=@MesInicial,@OpCargo uniqueidentifier,@Fecha date,@Id nvarchar(100)=CONVERT(nvarchar(100),@Operacion);
 WHILE @Mes<=@MesFinal
 BEGIN
  SET @OpCargo=NEWID();SET @Fecha=DATEFROMPARTS(@Anio,@Mes,@DiaVencimiento);
  EXEC dbo.Cargos_Generar @UsuarioId=@UsuarioId,@Operacion=@OpCargo,@Registro=@Registro,@TarifaId=@TarifaId,@VersionTarifa=@VersionTarifa,@Mes=@Mes,@Vencimiento=@Fecha,@PermitirTransaccion=1;
  SET @Mes+=1;
 END;
 INSERT dbo.LoteMensualidades(Operacion,SolicitudHash,UsuarioId,Registro,Cantidad) VALUES(@Operacion,@Hash,@UsuarioId,@Registro,@MesFinal-@MesInicial+1);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'GenerarMensualidades','LoteMensualidades',@Id,@Operacion,NULL,@Json;
 COMMIT;SELECT @MesFinal-@MesInicial+1 Cantidad;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
