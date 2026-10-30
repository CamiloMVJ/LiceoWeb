-- Ejecutar en base de desarrollo sin actividad concurrente. Todos los datos se revierten.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' THROW 52200,N'Base incorrecta.',1;
IF @@TRANCOUNT<>0 THROW 52200,N'Cierre transacciones anteriores.',1;
DECLARE @Usuario nvarchar(450)=(SELECT TOP(1) UR.UserId FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE R.Name='Administrador');
IF @Usuario IS NULL THROW 52200,N'Cree un administrador primero.',1;
BEGIN TRY
BEGIN TRANSACTION;
DECLARE @Datos nvarchar(max)=N'{"NombreEstudiante":"PRUEBA EXPEDIENTE","Modalidad":"Primaria","Grado":"1er Grado","FechaNacimiento":"2018-01-15","Sexo":"F","Direccion":"Prueba","TipoIngreso":"Nuevo","Tutor":"Madre","Motivo":"Alta de prueba","Madre":{"Nombre":"MADRE PRUEBA","Telefono":"88888888"},"Padre":{},"Otro":{},"PartidaRecibida":true}';
DECLARE @Salida TABLE(Registro nvarchar(10));
INSERT @Salida EXEC dbo.Expediente_Guardar @Datos,@Usuario;
DECLARE @Registro nvarchar(10)=(SELECT Registro FROM @Salida),@Version varchar(18);
SELECT @Version=CONVERT(varchar(18),Version,1) FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro;
IF NOT EXISTS(SELECT 1 FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro AND T.Hasta IS NULL) THROW 52201,N'No se guardó tutela.',1;
SET @Datos=JSON_MODIFY(JSON_MODIFY(@Datos,'$.Registro',@Registro),'$.Version',@Version);
SET @Datos=JSON_MODIFY(@Datos,'$.Tutor','Otro');
SET @Datos=JSON_MODIFY(@Datos,'$.Otro',JSON_QUERY(N'{"Nombre":"ABUELA PRUEBA","Telefono":"77777777","Parentesco":"Abuela"}'));
DELETE @Salida;
INSERT @Salida EXEC dbo.Expediente_Guardar @Datos,@Usuario;
IF (SELECT COUNT(*) FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro)<>2 THROW 52202,N'No se conservó historia.',1;
IF (SELECT COUNT(*) FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro AND T.Hasta IS NULL)<>1 THROW 52203,N'Tutelas vigentes duplicadas.',1;
EXEC dbo.Estudiante_DarBaja @Registro,N'Baja de prueba',@Usuario;
IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WHERE Registro=@Registro AND Estado='Inactivo') THROW 52204,N'Falló baja.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Auditoria WHERE RegistroId=@Registro AND Accion='DarBajaEstudiante') THROW 52205,N'Falta auditoría.',1;
ROLLBACK;
SELECT N'Prueba correcta: alta, cambio histórico de tutor y baja revertidos.' Resultado;
END TRY
BEGIN CATCH
IF XACT_STATE()<>0 ROLLBACK;
THROW;
END CATCH;
