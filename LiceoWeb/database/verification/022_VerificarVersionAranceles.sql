-- Diagnóstico de SOLO LECTURA. Ejecutar después de Aranceles_Consultar.sql.
SET NOCOUNT ON;
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52800,N'Base incorrecta.',1;
IF OBJECT_ID(N'dbo.Aranceles_Consultar',N'P') IS NULL THROW 52800,N'Falta Aranceles_Consultar.sql.',1;
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.Arancel') AND name=N'Version' AND system_type_id=189 AND max_length=8)
 OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.TarifaArancel') AND name=N'Version' AND system_type_id=189 AND max_length=8)
 THROW 52800,N'Revise 008: se requieren columnas rowversion de 8 bytes.',1;
-- Comprobar ocho bytes -> dieciocho caracteres -> los mismos ocho bytes.
IF EXISTS(SELECT 1 FROM dbo.Arancel A CROSS APPLY(VALUES(CONVERT(varchar(18),CONVERT(binary(8),A.[Version]),1))) V(Token)
 WHERE V.Token IS NULL OR DATALENGTH(V.Token)<>18 OR LEFT(V.Token,2)<>'0x'
 OR TRY_CONVERT(binary(8),V.Token,1) IS NULL OR TRY_CONVERT(binary(8),V.Token,1)<>CONVERT(binary(8),A.[Version]))
 THROW 52800,N'Falló la conversión de versión de arancel.',1;
IF EXISTS(SELECT 1 FROM dbo.TarifaArancel T CROSS APPLY(VALUES(CONVERT(varchar(18),CONVERT(binary(8),T.[Version]),1))) V(Token)
 WHERE V.Token IS NULL OR DATALENGTH(V.Token)<>18 OR LEFT(V.Token,2)<>'0x'
 OR TRY_CONVERT(binary(8),V.Token,1) IS NULL OR TRY_CONVERT(binary(8),V.Token,1)<>CONVERT(binary(8),T.[Version]))
 THROW 52800,N'Falló la conversión de versión de tarifa.',1;
SELECT TOP(20) A.Id,A.Codigo,DATALENGTH(A.[Version]) Bytes,
 CONVERT(varchar(18),CONVERT(binary(8),A.[Version]),1) VersionHex FROM dbo.Arancel A ORDER BY A.Id;
SELECT TOP(20) T.Id,T.ArancelId,DATALENGTH(T.[Version]) Bytes,
 CONVERT(varchar(18),CONVERT(binary(8),T.[Version]),1) VersionHex FROM dbo.TarifaArancel T ORDER BY T.Id;
SELECT N'CONVERSION_COLUMNAS_VERIFICADA' Resultado,(SELECT COUNT_BIG(*) FROM dbo.Arancel) ArancelesComprobados,
 (SELECT COUNT_BIG(*) FROM dbo.TarifaArancel) TarifasComprobadas;

-- Revisar por separado que se instaló Aranceles_Consultar.sql y probar Editar en la aplicación.
