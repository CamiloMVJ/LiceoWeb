CREATE OR ALTER PROCEDURE dbo.Conciliacion_Revisar
 @UsuarioId nvarchar(450),@Origen nvarchar(30),@OrigenId int,@TarifaId int,
 @Decision nvarchar(20),@Motivo nvarchar(500),@RevisionAnterior bigint=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53001,N'Se requiere administrador.',1;
 IF @Decision IS NULL OR @Decision NOT IN ('Deuda','SinDeuda','Rechazada') OR NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL THROW 53000,N'Decisión o motivo inválido.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 53002,N'Hay otra operación en curso.',1;
 DECLARE @Registro nvarchar(10),@Anio int,@Modalidad nvarchar(20),@Importe decimal(18,2),@Estado nvarchar(10),@Comprobante nvarchar(25),@Arancel int,@Cargo bigint;
 SELECT @Registro=Registro,@Anio=Anio,@Modalidad=Modalidad,@Importe=Importe,@Estado=Estado,@Comprobante=Comprobante,@Arancel=ArancelId,@Cargo=CargoId
 FROM dbo.PreparacionObligacion WITH(UPDLOCK,HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId;
 IF @Registro IS NULL OR @Cargo IS NOT NULL THROW 53000,N'Obligación no disponible para revisión.',1;
 IF ISNULL((SELECT MAX(Id) FROM dbo.RevisionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId),0)<>@RevisionAnterior OR @RevisionAnterior IS NULL THROW 53003,N'Otra persona revisó esta obligación. Recarga antes de continuar.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N'La obligación de origen ya no existe.',1;
 IF EXISTS(SELECT @Registro,@Anio,@Modalidad,@Importe,@Estado,@Comprobante EXCEPT SELECT Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N'El origen cambió desde la captura. No se aprobó.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel T WITH(HOLDLOCK) JOIN dbo.AnioLectivo A ON A.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId WHERE T.Id=@TarifaId AND T.ArancelId=@Arancel AND A.Anio=@Anio AND M.Nombre=@Modalidad) THROW 53005,N'La tarifa debe corresponder al arancel, año y modalidad originales.',1;
 -- El precio actual no reemplaza el importe histórico ni las becas.
 IF @Decision<>'Rechazada' AND @Importe<0 THROW 53005,N'No se aprueban importes negativos.',1;
 IF @Decision='Deuda' AND (@Estado NOT IN ('Pendiente','Vencido') OR @Importe<=0 OR @Comprobante IS NOT NULL OR @Origen='Matriculas') THROW 53005,N'Solo puede aprobarse como deuda una obligación pendiente positiva sin comprobante.',1;
 IF @Decision='SinDeuda' AND NOT (@Estado='Cancelado' OR @Importe=0) THROW 53005,N'Una obligación pendiente positiva no puede marcarse sin deuda.',1;
 IF @Decision<>'Rechazada' AND @Comprobante IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Pagos WITH(HOLDLOCK) WHERE Id_Comprobante=@Comprobante AND Registro_Estudiante=@Registro) THROW 53005,N'El comprobante no corresponde al estudiante.',1;
 INSERT dbo.RevisionObligacion(Origen,OrigenId,TarifaId,Decision,Motivo,UsuarioId,Registro,Anio,Modalidad,Importe,Estado,Comprobante)
 VALUES(@Origen,@OrigenId,@TarifaId,@Decision,@Motivo,@UsuarioId,@Registro,@Anio,@Modalidad,@Importe,@Estado,@Comprobante);
 DECLARE @Id bigint=CONVERT(bigint,SCOPE_IDENTITY()),@Operacion uniqueidentifier=NEWID(),@Clave nvarchar(100)=CONCAT(@Origen,':',@OrigenId),@Json nvarchar(max);
 SET @Json=(SELECT @Id RevisionId,@TarifaId TarifaId,@Decision Decision,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N'RevisarObligacion',@Entidad=N'Conciliacion',@RegistroId=@Clave,@IdOperacion=@Operacion,@DespuesJson=@Json;
 COMMIT;
 SELECT @Id RevisionId;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Conciliacion_Consultar @UsuarioId nvarchar(450),@DespuesDeRevision bigint=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53001,N'Se requiere administrador.',1;
 SELECT TOP(200) R.Id,R.Origen,R.OrigenId,R.Registro,R.TarifaId,R.Decision,R.Motivo,R.UsuarioId,R.Fecha,
 CASE WHEN O.OrigenId IS NULL THEN N'ORIGEN_AUSENTE'
 WHEN EXISTS(SELECT R.Registro,R.Anio,R.Modalidad,R.Importe,R.Estado,R.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N'ORIGEN_CAMBIO'
 ELSE N'COINCIDE_CON_ORIGEN' END EstadoFuente,
 CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM dbo.RevisionObligacion X WHERE X.Origen=R.Origen AND X.OrigenId=R.OrigenId AND X.Id>R.Id) THEN 0 ELSE 1 END) UltimaRevision
 FROM dbo.RevisionObligacion R LEFT JOIN dbo.ObligacionLegada O ON O.Origen=R.Origen AND O.OrigenId=R.OrigenId
 WHERE R.Id>@DespuesDeRevision ORDER BY R.Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Conciliacion_Pantalla
 @UsuarioId nvarchar(450),@Pagina int=1,@Registro nvarchar(10)=N'',@Origen nvarchar(30)=N'',@OrigenId int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 53001,N'Se requiere administrador.',1;
 IF @Pagina NOT BETWEEN 1 AND 100000 THROW 53000,N'Página inválida.',1;
 SELECT P.Origen,P.OrigenId,P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante,
 ISNULL(R.Id,0) RevisionAnterior,R.Decision,
 CASE WHEN O.OrigenId IS NULL THEN N'ORIGEN_AUSENTE'
 WHEN EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N'ORIGEN_CAMBIO'
 ELSE N'COINCIDE_CON_ORIGEN' END EstadoFuente
 FROM dbo.PreparacionObligacion P
 OUTER APPLY(SELECT TOP(1) Id,Decision FROM dbo.RevisionObligacion R WHERE R.Origen=P.Origen AND R.OrigenId=P.OrigenId ORDER BY Id DESC) R
 LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId
 WHERE @Registro=N'' OR P.Registro=@Registro
 ORDER BY P.Origen,P.OrigenId OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 51 ROWS ONLY;
 SELECT P.*,ISNULL(R.Id,0) RevisionAnterior,R.Decision
 FROM dbo.PreparacionObligacion P OUTER APPLY(SELECT TOP(1) Id,Decision FROM dbo.RevisionObligacion R WHERE R.Origen=P.Origen AND R.OrigenId=P.OrigenId ORDER BY Id DESC) R
 WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId;
 SELECT T.Id,CONCAT(A.Nombre,N' / ',Y.Anio,N' / ',M.Nombre,N' / precio actual ',T.Importe) Etiqueta
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 JOIN dbo.PreparacionObligacion P ON P.ArancelId=T.ArancelId AND P.Anio=Y.Anio AND P.Modalidad=M.Nombre
 WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId ORDER BY T.Id;
 SELECT TOP(200) R.Id,R.TarifaId,R.Decision,R.Motivo,U.UserName Responsable,R.Fecha
 FROM dbo.RevisionObligacion R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId
 WHERE R.Origen=@Origen AND R.OrigenId=@OrigenId ORDER BY R.Id DESC;
END;
GO
