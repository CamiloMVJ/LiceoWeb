-- Solo actualiza la consulta; no reemplaza Aranceles_Guardar ni modifica datos.
IF DB_NAME()<>N'LiceoWeb_Dev' THROW 52800,N'Base incorrecta.',1;
GO
CREATE OR ALTER PROCEDURE dbo.Aranceles_Consultar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 52801,N'Acceso exclusivo de administración.',1;
 SELECT A.Id,A.Codigo,A.Nombre,A.Activo,CONVERT(varchar(18),CONVERT(binary(8),A.[Version]),1) [Version] FROM dbo.Arancel A ORDER BY A.Nombre;
 SELECT T.Id,T.ArancelId,T.ModalidadId,T.AnioId,A.Nombre Arancel,M.Nombre Modalidad,Y.Anio,T.Importe,T.Activo,CONVERT(varchar(18),CONVERT(binary(8),T.[Version]),1) [Version]
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId ORDER BY Y.Anio DESC,A.Nombre,M.Nombre;
 SELECT Id,CONVERT(nvarchar(10),Anio) Etiqueta,Activo FROM dbo.AnioLectivo ORDER BY Anio DESC;
 SELECT Id,Nombre Etiqueta,Activo FROM dbo.ModalidadAcademica ORDER BY Nombre;
 SELECT M.Origen,M.ArancelId,A.Nombre Arancel FROM dbo.MapaConceptoLegado M JOIN dbo.Arancel A ON A.Id=M.ArancelId ORDER BY M.Origen;
 SELECT TOP(200) H.Id,H.TarifaId,A.Nombre Arancel,H.ImporteAnterior,H.ImporteNuevo,H.ActivoAnterior,H.ActivoNuevo,H.Motivo,U.UserName Responsable,H.Fecha
 FROM dbo.HistorialTarifa H JOIN dbo.TarifaArancel T ON T.Id=H.TarifaId JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId ORDER BY H.Id DESC;
 -- Compara con la fuente actual; no sobrescribe evidencia previa ni aprueba conciliaciones.
 SELECT TOP(200) P.Origen,P.OrigenId,P.Registro,P.Anio,P.Importe,P.Estado,P.Comprobante,P.CargoId,
 CASE WHEN O.OrigenId IS NULL THEN N'ORIGEN_AUSENTE'
 WHEN EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N'ORIGEN_CAMBIO'
 ELSE N'CAPTURADO_SIN_CONCILIAR' END Revision
 FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId ORDER BY P.Origen,P.OrigenId;
 SELECT (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada) OrigenesActuales,(SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion) FilasPreparadas,
 (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada O WHERE NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P WHERE P.Origen=O.Origen AND P.OrigenId=O.OrigenId)) SinPreparar,
 (SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId WHERE O.OrigenId IS NULL OR EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante)) FuentesCambiadas;
END;
GO
