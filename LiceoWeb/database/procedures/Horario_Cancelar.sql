CREATE OR ALTER PROCEDURE dbo.Horario_Cancelar
 @UsuarioId nvarchar(450),@HorarioId int,@Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name='Administrador') THROW 54201,N'Se requiere administrador.',1;
 SET @Motivo=NULLIF(LTRIM(RTRIM(@Motivo)),N'');
 IF @HorarioId IS NULL OR @HorarioId<=0 OR @Operacion IS NULL OR @Operacion='00000000-0000-0000-0000-000000000000'
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>'0x' OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54202,N'Indica horario, versión, operación y motivo de 10 a 500 caracteres.',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock int,@Esperada binary(8)=CONVERT(binary(8),@Version,1),@Actual binary(8),@Cerrado bit,@Antes nvarchar(max);
  EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @Lock<0 THROW 54203,N'Planificación ocupada. Intente nuevamente.',1;
  IF EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE Operacion=@Operacion AND HorarioId=@HorarioId AND UsuarioId=@UsuarioId AND Motivo COLLATE Latin1_General_100_BIN2=@Motivo COLLATE Latin1_General_100_BIN2 AND VersionHorario=@Esperada)
    THROW 54204,N'La operación ya se utilizó con otros datos.',1;
   COMMIT;RETURN;
  END;
  SELECT @Actual=H.Version,@Cerrado=P.Cerrado FROM dbo.HorarioClase H WITH(UPDLOCK,HOLDLOCK)
  JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
  JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE H.Id=@HorarioId;
  IF @Actual IS NULL THROW 54205,N'El horario no existe.',1;
  IF EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE HorarioId=@HorarioId) THROW 54206,N'El horario ya fue cancelado. Consulte el historial.',1;
  IF @Actual<>@Esperada THROW 54207,N'El horario cambió desde que abrió la página. Recargue antes de confirmar.',1;
  IF @Cerrado=1 THROW 54208,N'El período está cerrado. Su reapertura requiere el proceso académico correspondiente.',1;
  SELECT @Antes=(SELECT H.Id,H.AsignacionId,D.GrupoId,G.PeriodoId,Y.Anio,P.Nombre Periodo,G.Seccion,
   S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin
   FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
   JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId
   JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId
   WHERE H.Id=@HorarioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT dbo.CancelacionHorario(HorarioId,Operacion,UsuarioId,Motivo,VersionHorario,Instantanea)
  VALUES(@HorarioId,@Operacion,@UsuarioId,@Motivo,@Actual,@Antes);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@HorarioId),@Despues nvarchar(max)=(SELECT @HorarioId HorarioId,@Motivo Motivo,N'Cancelado' Estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,N'CancelarHorario',N'HorarioClase',@Id,@Operacion,@Antes,@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
