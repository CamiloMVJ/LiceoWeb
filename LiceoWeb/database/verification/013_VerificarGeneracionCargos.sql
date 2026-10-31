-- Solo lectura, tras instalar 014 y probar generación en copia de desarrollo.
IF DB_NAME()<>'LiceoWeb_Dev' THROW 53600,N'Use desarrollo.',1;
IF OBJECT_ID('dbo.GeneracionCargo','U') IS NULL THROW 53600,N'Instale 014.',1;
GO
IF EXISTS(SELECT 1 FROM dbo.GeneracionCargo G JOIN dbo.CargoEstudiante C ON C.Id=G.CargoId WHERE C.Importe<=0 OR NOT EXISTS(SELECT 1 FROM dbo.Auditoria A WHERE A.IdOperacion=G.Operacion AND A.Entidad='CargoEstudiante' AND A.Accion='GenerarCargo')) THROW 53600,N'Cargo generado inválido o sin auditoría.',1;
IF EXISTS(SELECT C.Registro,T.ArancelId,T.AnioId,C.Referencia FROM dbo.GeneracionCargo G JOIN dbo.CargoEstudiante C ON C.Id=G.CargoId JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId GROUP BY C.Registro,T.ArancelId,T.AnioId,C.Referencia HAVING COUNT(*)>1) THROW 53600,N'Período duplicado por estudiante, arancel y año.',1;
SELECT 'INTEGRIDAD_OK' Resultado,COUNT(*) CargosGenerados FROM dbo.GeneracionCargo;
-- No comparar C.Importe con tarifa actual: una actualización de tarifa no revaloriza deuda anterior.
