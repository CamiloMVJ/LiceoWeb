CREATE OR ALTER PROCEDURE dbo.CorteFinanciero_Ejecutar @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Aplicar bit=0,@Confirmacion nvarchar(60)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53400,N'Use desarrollo sin transacciones abiertas.',1;
 IF @Operacion IS NULL OR @Aplicar IS NULL THROW 53400,N'Indique operación y modalidad.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53401,N'Se requiere administrador.',1;
 IF @Aplicar=1 AND ISNULL(@Confirmacion,N'')<>N'APLICAR CORTE EN DESARROLLO' THROW 53400,N'Falta confirmación explícita.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Tabla sysname,@Sql nvarchar(max),@N bigint;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53402,N'Hay otra operación financiera en curso.',1;
 IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Operacion=@Operacion) THROW 53403,N'El corte ya fue aplicado con otra operación.',1;
  COMMIT;SELECT N'YA_APLICADO' Estado;RETURN;
 END;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1) THROW 53400,N'Falta control de corte.',1;
 -- Bloquear primero fuentes: los procedimientos heredados no conocen el applock.
 DECLARE Bloqueos CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM (VALUES
 ('Estudiantes'),('Pagos'),('Abonos'),('Matriculas'),('Mensualidades'),('Mantenimientos'),('EvBoTaS'),('Promociones'),('Arreglos_Pago'),('Historial_Comprobantes'),
 ('Costo_Matricula'),('Costo_Mensualidad'),('Costo_Mantenimiento'),('Costo_EvBoTa'),('Costo_Promocion'),
 ('PreparacionObligacion'),('RevisionObligacion'),('RevisionSaldo'),('MapaConceptoLegado'),('HistorialCaptura'),
 ('Arancel'),('TarifaArancel'),('AnioLectivo'),('ModalidadAcademica'),('CargoEstudiante'),('ReciboMultiple'),('AplicacionPago'),('SaldoFinanciero'),('ObligacionMigrada')) V(T);
 OPEN Bloqueos;FETCH NEXT FROM Bloqueos INTO @Tabla;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Sql=N'SELECT @N=COUNT_BIG(*) FROM dbo.'+QUOTENAME(@Tabla)+N' WITH(TABLOCKX,HOLDLOCK);';EXEC sys.sp_executesql @Sql,N'@N bigint OUTPUT',@N OUTPUT;
  FETCH NEXT FROM Bloqueos INTO @Tabla;
 END;
 CLOSE Bloqueos;DEALLOCATE Bloqueos;
 -- Verificar que las barreras realmente existen y están habilitadas.
 IF EXISTS(SELECT 1 FROM (VALUES('Pagos'),('Abonos'),('Matriculas'),('Mensualidades'),('Mantenimientos'),('EvBoTaS'),('Promociones'),('Arreglos_Pago'),('Historial_Comprobantes'),('Costo_Matricula'),('Costo_Mensualidad'),('Costo_Mantenimiento'),('Costo_EvBoTa'),('Costo_Promocion'),('PreparacionObligacion'),('RevisionObligacion'),('RevisionSaldo'),('MapaConceptoLegado'),('HistorialCaptura')) V(T)
 WHERE NOT EXISTS(SELECT 1 FROM sys.triggers WHERE name=N'TR_Corte_'+V.T AND parent_id=OBJECT_ID(N'dbo.'+V.T) AND is_disabled=0)) THROW 53404,N'Faltan barreras de escritura; reinstale correctamente la infraestructura.',1;
 IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante) OR EXISTS(SELECT 1 FROM dbo.ReciboMultiple) OR EXISTS(SELECT 1 FROM dbo.SaldoFinanciero) OR EXISTS(SELECT 1 FROM dbo.ObligacionMigrada) THROW 53404,N'El destino financiero no está vacío. Requiere investigación.',1;
 IF EXISTS(SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada EXCEPT SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.PreparacionObligacion)
 OR EXISTS(SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.PreparacionObligacion EXCEPT SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada) THROW 53404,N'Hay obligaciones sin capturar, cambiadas o eliminadas.',1;
 SELECT P.*,R.Id RevisionId,R.TarifaId,R.Decision,R.Generacion GeneracionRevisada INTO #Obligaciones
 FROM dbo.PreparacionObligacion P OUTER APPLY(SELECT TOP(1) * FROM dbo.RevisionObligacion X WHERE X.Origen=P.Origen AND X.OrigenId=P.OrigenId ORDER BY Id DESC) R;
 IF EXISTS(SELECT 1 FROM #Obligaciones WHERE RevisionId IS NULL OR Generacion<>GeneracionRevisada OR Decision='Rechazada' OR CargoId IS NOT NULL OR Importe<0) THROW 53404,N'Faltan revisiones vigentes y aprobadas de obligaciones.',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones P WHERE NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel T JOIN dbo.AnioLectivo A ON A.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId WHERE T.Id=P.TarifaId AND T.ArancelId=P.ArancelId AND A.Anio=P.Anio AND M.Nombre=P.Modalidad)) THROW 53404,N'Las tarifas ya no coinciden con las obligaciones.',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones WHERE (Decision='Deuda' AND (Estado NOT IN ('Pendiente','Vencido') OR Importe<=0 OR Comprobante IS NOT NULL OR Origen='Matriculas')) OR (Decision='SinDeuda' AND Estado<>'Cancelado' AND Importe<>0)) THROW 53404,N'Decisión incompatible con estado o importe.',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones O WHERE Comprobante IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Pagos P WHERE P.Id_Comprobante=O.Comprobante AND P.Registro_Estudiante=O.Registro)) THROW 53404,N'Hay comprobantes incompatibles con la obligación.',1;
 -- Todos los estudiantes con actividad financiera requieren saldo revisado, incluso cero.
 DECLARE @Registro nvarchar(10),@Json nvarchar(max),@Saldo decimal(18,2),@Filas int,@Revision bigint;
 DECLARE Saldos CURSOR LOCAL FAST_FORWARD FOR SELECT Registro_Estudiante FROM dbo.Pagos UNION SELECT Registro_Estudiante FROM dbo.Abonos UNION SELECT Registro FROM dbo.PreparacionObligacion;
 OPEN Saldos;FETCH NEXT FROM Saldos INTO @Registro;
 WHILE @@FETCH_STATUS=0
 BEGIN
  EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
  SET @Revision=NULL;
  SELECT @Revision=Id FROM dbo.RevisionSaldo WHERE Id=(SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro) AND Decision='Aprobado' AND Huella=HASHBYTES('SHA2_256',@Json) AND SaldoObservado=@Saldo AND FilasSaldo=@Filas;
  IF @Revision IS NULL OR @Saldo<0 OR @Filas>1 THROW 53404,N'Falta aprobación vigente de un saldo. Consulte Conciliación de saldos.',1;
  INSERT dbo.SaldoFinanciero(Registro,RevisionSaldoId,SaldoInicial,Disponible) VALUES(@Registro,@Revision,@Saldo,@Saldo);
  FETCH NEXT FROM Saldos INTO @Registro;
 END;
 CLOSE Saldos;DEALLOCATE Saldos;
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento)
 SELECT O.Registro,O.TarifaId,CONCAT(N'LEGADO:',O.Origen,':',O.OrigenId),CONCAT(A.Nombre,N' / ',O.Anio,N' / ',O.Origen,N' #',O.OrigenId),O.Importe,NULL FROM #Obligaciones O JOIN dbo.Arancel A ON A.Id=O.ArancelId WHERE O.Decision='Deuda';
 INSERT dbo.ObligacionMigrada(Origen,OrigenId,RevisionId,CargoId)
 SELECT O.Origen,O.OrigenId,O.RevisionId,C.Id FROM #Obligaciones O LEFT JOIN dbo.CargoEstudiante C ON C.Registro=O.Registro AND C.TarifaId=O.TarifaId AND C.Referencia=CONCAT(N'LEGADO:',O.Origen,':',O.OrigenId);
 UPDATE P SET CargoId=M.CargoId FROM dbo.PreparacionObligacion P JOIN dbo.ObligacionMigrada M ON M.Origen=P.Origen AND M.OrigenId=P.OrigenId;
 IF ISNULL((SELECT SUM(Importe) FROM dbo.CargoEstudiante),0)<>ISNULL((SELECT SUM(Importe) FROM #Obligaciones WHERE Decision='Deuda'),0) THROW 53404,N'No coinciden los totales de deuda.',1;
 DECLARE @Cargos bigint=(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante),@TotalDeuda decimal(38,2)=ISNULL((SELECT SUM(Importe) FROM dbo.CargoEstudiante),0),@TotalSaldo decimal(38,2)=ISNULL((SELECT SUM(SaldoInicial) FROM dbo.SaldoFinanciero),0);
 IF @Aplicar=0
 BEGIN
  ROLLBACK;SELECT N'SIMULACION_REVERTIDA' Estado,@Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial;RETURN;
 END;
 UPDATE dbo.ControlFinanciero SET Migrado=1,Operacion=@Operacion,Fecha=SYSUTCDATETIME(),UsuarioId=@UsuarioId WHERE Id=1;
 DECLARE @Detalle nvarchar(max)=(SELECT @Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'CorteFinanciero',@Entidad=N'ControlFinanciero',@RegistroId=N'1',@IdOperacion=@Operacion,@DespuesJson=@Detalle;
 COMMIT;
 SELECT N'APLICADO' Estado,@Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
