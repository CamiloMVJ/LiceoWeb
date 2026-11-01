-- Solo lectura: objetos y contratos de esta actualización; no certifica todas las migraciones.
SET NOCOUNT ON;
SELECT DB_NAME() AS BaseActual;
SELECT P.Objeto, CASE WHEN OBJECT_ID(P.Objeto,'P') IS NULL THEN N'FALTA' ELSE N'INSTALADO' END AS Estado
FROM (VALUES(N'dbo.Cargos_ConfigurarMatricula'),(N'dbo.Cargos_Generar'),
 (N'dbo.Cargos_Pantalla'),(N'dbo.Mensualidades_GenerarLote'),
 (N'dbo.Planificacion_Guardar'),(N'dbo.ReporteFinanciero_Consultar')) P(Objeto);
SELECT P.Objeto,P.Parametro,CASE WHEN EXISTS(SELECT 1 FROM sys.parameters S
 WHERE S.object_id=OBJECT_ID(P.Objeto) AND S.name=P.Parametro) THEN N'ACTUALIZADO' ELSE N'FALTA ACTUALIZAR' END AS Estado
FROM (VALUES(N'dbo.Cargos_Generar',N'@PermitirTransaccion'),
 (N'dbo.ReporteFinanciero_Consultar',N'@Exportar')) P(Objeto,Parametro);
SELECT T.Objeto,CASE WHEN OBJECT_ID(T.Objeto,'U') IS NULL THEN N'FALTA' ELSE N'INSTALADO' END AS Estado
FROM (VALUES(N'dbo.MatriculaAcademica'),(N'dbo.ConfiguracionMatricula'),(N'dbo.LoteMensualidades')) T(Objeto);
IF OBJECT_ID(N'dbo.ControlFinanciero',N'U') IS NOT NULL
 EXEC sys.sp_executesql N'SELECT Migrado,CASE WHEN Migrado=1 THEN N''LIBRO NUEVO ACTIVADO'' ELSE N''CORTE TODAVÍA NO APLICADO'' END AS Estado FROM dbo.ControlFinanciero WHERE Id=1;';
GO
