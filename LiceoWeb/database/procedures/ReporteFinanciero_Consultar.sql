CREATE OR ALTER PROCEDURE dbo.ReporteFinanciero_Consultar
 @UsuarioId nvarchar(450),@Desde date,@Hasta date,@Pagina int=1,@Exportar bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @Exportar IS NULL THROW 54002,N'Indica el modo de consulta.',1;
 IF @Desde IS NULL OR @Hasta IS NULL OR @Desde<'20000101' OR @Hasta>'99981231' OR @Hasta<@Desde OR DATEDIFF(day,@Desde,@Hasta)>365 OR @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54002,N'Indica un rango de hasta 366 días y página válida.',1;
 DECLARE @Inicio datetime2=DATEADD(hour,6,CONVERT(datetime2,@Desde)),@Fin datetime2=DATEADD(hour,6,DATEADD(day,1,CONVERT(datetime2,@Hasta))),@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource='Liceo.Finanzas.Configuracion',@LockMode='Shared',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54003,N'Finanzas está ocupado. Reintenta la consulta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 54002,N'El reporte requiere el corte aplicado; no incluye el libro anterior.',1;
 -- Conservar ambos eventos; una anulación posterior no cambia el ingreso de la fecha original.
 SELECT R.Id ReciboId,R.Numero,R.Registro,R.NombreEstudiante,R.Fecha FechaUTC,CONVERT(nvarchar(12),CASE WHEN R.Anticipo>0 THEN N'Anticipo' ELSE N'Cobro' END) Tipo,R.Metodo,R.UsuarioId,
 R.Recibido-R.Cambio Dinero,R.SaldoAplicado Saldo,R.TotalAplicado Aplicado
 INTO #Movimientos FROM dbo.ReciboMultiple R WHERE R.Fecha>=@Inicio AND R.Fecha<@Fin
 UNION ALL
 SELECT R.Id,R.Numero,R.Registro,R.NombreEstudiante,X.Fecha,N'Devolución',R.Metodo,X.UsuarioId,-X.DineroDevuelto,-X.SaldoRestituido,-(X.TotalRevertido-X.SaldoRetirado)
 FROM dbo.AnulacionRecibo X JOIN dbo.ReciboMultiple R ON R.Id=X.ReciboId WHERE X.Fecha>=@Inicio AND X.Fecha<@Fin;
 COMMIT;
 IF @Exportar=1 AND (SELECT COUNT_BIG(*) FROM #Movimientos)>50000 THROW 54002,N'El rango supera 50000 movimientos. Reduce las fechas para exportar; no se descargaron datos parciales.',1;
 SELECT COUNT_BIG(*) Movimientos,
 ISNULL(SUM(CASE WHEN Tipo IN ('Cobro','Anticipo') THEN Dinero ELSE 0 END),0) Cobrado,
 -ISNULL(SUM(CASE WHEN Tipo=N'Devolución' THEN Dinero ELSE 0 END),0) Devuelto,
 ISNULL(SUM(Dinero),0) DineroNeto,ISNULL(SUM(Saldo),0) SaldoNeto,ISNULL(SUM(Aplicado),0) AplicadoNeto,
 ISNULL(SUM(CASE WHEN Tipo='Anticipo' THEN Dinero ELSE 0 END),0) Anticipos,
 COUNT(DISTINCT CASE WHEN Tipo<>'Devolución' THEN Registro END) Estudiantes,
 SUM(CASE WHEN Tipo IN ('Cobro','Anticipo') THEN 1 ELSE 0 END) Recibos
 FROM #Movimientos;
 SELECT Metodo,ISNULL(SUM(CASE WHEN Tipo IN ('Cobro','Anticipo') THEN Dinero ELSE 0 END),0) Cobrado,
 -ISNULL(SUM(CASE WHEN Tipo=N'Devolución' THEN Dinero ELSE 0 END),0) Devuelto,SUM(Dinero) DineroNeto,SUM(Saldo) SaldoNeto FROM #Movimientos GROUP BY Metodo ORDER BY Metodo;
 SELECT M.ReciboId,M.Numero,M.Registro,M.NombreEstudiante,DATEADD(hour,-6,M.FechaUTC) FechaLocal,M.Tipo,M.Metodo,U.UserName Responsable,M.Dinero,M.Saldo,M.Aplicado
 FROM #Movimientos M LEFT JOIN dbo.AspNetUsers U ON U.Id=M.UsuarioId ORDER BY M.FechaUTC DESC,M.ReciboId DESC,M.Tipo
 OFFSET (CASE WHEN @Exportar=1 THEN 0 ELSE (@Pagina-1)*100 END) ROWS
 FETCH NEXT (CASE WHEN @Exportar=1 THEN 50000 ELSE 100 END) ROWS ONLY;
 SELECT CONVERT(date,DATEADD(hour,-6,FechaUTC)) Dia,
 SUM(CASE WHEN Tipo IN ('Cobro','Anticipo') THEN Dinero ELSE 0 END) Entradas,
 -SUM(CASE WHEN Tipo=N'Devolución' THEN Dinero ELSE 0 END) Devoluciones,
 SUM(Dinero) Neto FROM #Movimientos GROUP BY CONVERT(date,DATEADD(hour,-6,FechaUTC)) ORDER BY Dia;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
