-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 50001, N'Seleccione LiceoWeb_Dev antes de ejecutar.', 1;

SELECT DB_NAME() AS BaseActual;

SELECT name AS Tabla FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;

SELECT t.name AS Tabla, kc.name AS ClavePrimaria
FROM sys.tables t LEFT JOIN sys.key_constraints kc ON kc.parent_object_id=t.object_id AND kc.type='PK'
WHERE t.is_ms_shipped=0 ORDER BY t.name;

SELECT name, current_value, maximum_value FROM sys.sequences;

SELECT t.name AS Tabla, c.name AS Columna, ty.name AS Tipo, c.precision, c.scale
FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE t.is_ms_shipped=0 AND (ty.name='decimal' OR c.name='FechaNacimiento') ORDER BY t.name,c.column_id;

SELECT N'Costo_Matricula' AS Tabla, Matricula_Modalidad AS Modalidad, Costo_Actual FROM dbo.Costo_Matricula
UNION ALL
SELECT N'Costo_Mensualidad' AS Tabla, Mensualidad_Modalidad AS Modalidad, Costo_Actual FROM dbo.Costo_Mensualidad
UNION ALL
SELECT N'Costo_Promocion' AS Tabla, Promocion_Modalidad AS Modalidad, Costo_Actual FROM dbo.Costo_Promocion
UNION ALL
SELECT N'Costo_Mantenimiento' AS Tabla, Mantenimiento_Modalidad AS Modalidad, Costo_Actual FROM dbo.Costo_Mantenimiento
UNION ALL
SELECT N'Costo_EvBoTa' AS Tabla, EvBoTa_Modalidad AS Modalidad, Costo_Actual FROM dbo.Costo_EvBoTa;

-- Esperado: cero filas.
SELECT name AS TablaSinPK FROM sys.tables t WHERE t.is_ms_shipped=0
AND NOT EXISTS (SELECT 1 FROM sys.key_constraints k WHERE k.parent_object_id=t.object_id AND k.type='PK');
