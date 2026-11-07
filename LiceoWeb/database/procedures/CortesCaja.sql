CREATE OR ALTER PROCEDURE dbo.CorteCaja_Consultar @UsuarioId nvarchar(450),@Id bigint=0
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Shared',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54803,N'Caja ocupada. Reintenta.',1;
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
END;
GO
CREATE OR ALTER PROCEDURE dbo.CorteCaja_Operar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Accion nvarchar(20),@CorteId bigint=0,
 @Fondo decimal(28,8)=0,@Contado decimal(28,8)=NULL,@Motivo nvarchar(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 54800,N'No usar transacción externa.',1;
 IF @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
 OR @Accion IS NULL OR @Accion NOT IN ('Abrir','Cerrar','CerrarAbrir')
 OR @Fondo IS NULL OR @Fondo<0 OR @Fondo>9999999999999999.99 OR ROUND(@Fondo,2)<>@Fondo
 OR (@Accion<>'Abrir' AND (@CorteId<=0 OR @Contado IS NULL OR @Contado<0 OR @Contado>9999999999999999.99 OR ROUND(@Contado,2)<>@Contado))
 OR (@Accion='Cerrar' AND @Fondo<>0)
 OR LEN(ISNULL(TRIM(@Motivo),N''))<10
 THROW 54802,N'Revisa corte, efectivo contado, fondo y motivo de al menos 10 caracteres.',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId Usuario,@Accion Accion,@CorteId CorteId,@Fondo Fondo,@Contado Contado,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES('SHA2_256',@Solicitud),@Lock int,@Id bigint,@Siguiente bigint,@Ahora datetime2=SYSUTCDATETIME();
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54803,N'Caja ocupada. Reintenta la misma operación.',1;
 SET @Ahora=SYSUTCDATETIME();
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 54802,N'Activa primero el libro financiero nuevo.',1;
 IF EXISTS(SELECT 1 FROM dbo.EventoCorteCaja WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.EventoCorteCaja WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId)
   THROW 54802,N'La operación ya fue usada con otros datos.',1;
  COMMIT;RETURN;
 END;
 IF @Accion='Abrir'
 BEGIN
  IF EXISTS(SELECT 1 FROM dbo.CorteCaja WHERE Fin IS NULL) THROW 54802,N'Ya existe un corte abierto.',1;
  INSERT dbo.CorteCaja(Inicio,UsuarioApertura,FondoApertura) VALUES(@Ahora,@UsuarioId,@Fondo);
  SET @Id=SCOPE_IDENTITY();
 END
 ELSE
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.CorteCaja WITH(UPDLOCK,HOLDLOCK) WHERE Id=@CorteId AND Fin IS NULL)
   THROW 54802,N'El corte ya no está abierto. Recarga antes de confirmar.',1;
  DECLARE @Entrada decimal(38,2),@Devuelto decimal(38,2),@Esperado decimal(38,2),@Resumen nvarchar(max);
  SELECT @Entrada=ISNULL(SUM(Recibido-Cambio),0) FROM dbo.ReciboMultiple WHERE CorteCajaId=@CorteId AND Metodo='Efectivo';
  SELECT @Devuelto=ISNULL(SUM(A.DineroDevuelto),0) FROM dbo.AnulacionRecibo A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId WHERE A.CorteCajaId=@CorteId AND R.Metodo='Efectivo';
  SELECT @Esperado=FondoApertura+@Entrada-@Devuelto FROM dbo.CorteCaja WHERE Id=@CorteId;
  IF ABS(@Esperado)>9999999999999999.99 OR ABS(@Contado-@Esperado)>9999999999999999.99
   THROW 54802,N'El total excede el límite permitido para cerrar.',1;
  SET @Resumen=(SELECT Metodo,SUM(Entrada) Entrada,SUM(Devolucion) Devolucion,SUM(Entrada-Devolucion) Neto FROM(
   SELECT Metodo,Recibido-Cambio Entrada,CAST(0 AS decimal(18,2)) Devolucion FROM dbo.ReciboMultiple WHERE CorteCajaId=@CorteId
   UNION ALL SELECT R.Metodo,0,A.DineroDevuelto FROM dbo.AnulacionRecibo A JOIN dbo.ReciboMultiple R ON R.Id=A.ReciboId WHERE A.CorteCajaId=@CorteId
  ) M GROUP BY Metodo FOR JSON PATH);
  UPDATE dbo.CorteCaja SET Fin=@Ahora,UsuarioCierre=@UsuarioId,EfectivoEsperado=@Esperado,EfectivoContado=@Contado,
   Diferencia=@Contado-@Esperado,Motivo=@Motivo,ResumenJson=@Resumen WHERE Id=@CorteId;
  SET @Id=@CorteId;
  IF @Accion='CerrarAbrir'
  BEGIN
   INSERT dbo.CorteCaja(Inicio,UsuarioApertura,FondoApertura) VALUES(@Ahora,@UsuarioId,@Fondo);
   SET @Siguiente=SCOPE_IDENTITY();
  END;
 END;
 INSERT dbo.EventoCorteCaja(Operacion,SolicitudHash,CorteId,SiguienteId,UsuarioId) VALUES(@Operacion,@Hash,@Id,@Siguiente,@UsuarioId);
 DECLARE @Registro nvarchar(100)=CONVERT(nvarchar(100),@Id),@Despues nvarchar(max)=(SELECT @Id CorteId,@Siguiente SiguienteId,@Accion Accion,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 EXEC dbo.Registrar_Auditoria @UsuarioId,'GestionarCorteCaja','CorteCaja',@Registro,@Operacion,NULL,@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
