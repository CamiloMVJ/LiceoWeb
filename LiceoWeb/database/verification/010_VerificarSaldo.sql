-- Solo desarrollo, sin actividad concurrente. Cada caso revierte sus datos.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53300,N'Use desarrollo sin transacciones abiertas.',1;
DECLARE @Usuario nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
IF @Usuario IS NULL THROW 53300,N'Requiere administrador.',1;
DECLARE @Caso int=1,@Error int,@Registro nvarchar(10),@Json nvarchar(max),@Saldo decimal(18,2),@Filas int,@Huella varchar(66),@Revision bigint;
DECLARE @Insertados TABLE(Registro nvarchar(10));
WHILE @Caso<=3
BEGIN
 SET @Error=0;
 BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.Estudiantes(NombreEstudiante,Modalidad,Grado,FechaNacimiento,Sexo,NombreTutor,Telefono,Direccion)
 OUTPUT INSERTED.Registro INTO @Insertados VALUES(N'Prueba saldo',N'Primaria',N'1er Grado','20190101','M',N'Tutor de prueba',N'00000000',N'Prueba');
 SELECT @Registro=Registro FROM @Insertados;
 INSERT dbo.Abonos(Registro_Estudiante,Abono_Disponible) VALUES(@Registro,10.25);
 EXEC dbo.Saldo_Instantanea @Usuario,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
 SET @Huella=CONVERT(varchar(66),HASHBYTES('SHA2_256',@Json),1);
 EXEC dbo.Saldo_Revisar @Usuario,@Registro,@Huella,0,N'Aprobado',N'Respaldo de prueba',N'Conciliación de prueba';
 SELECT @Revision=MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro;
 IF NOT EXISTS(SELECT 1 FROM dbo.RevisionSaldo WHERE Id=@Revision AND SaldoObservado=10.25) THROW 53301,N'Saldo incorrecto.',1;
 IF EXISTS(SELECT 1 FROM dbo.Pagos WHERE Registro_Estudiante=@Registro) THROW 53301,N'La revisión generó un pago.',1;
 IF @Caso=2
 BEGIN
  UPDATE dbo.Abonos SET Abono_Disponible=11.25 WHERE Registro_Estudiante=@Registro;
  EXEC dbo.Saldo_Revisar @Usuario,@Registro,@Huella,@Revision,N'Aprobado',N'Prueba',N'Huella antigua';
 END;
 IF @Caso=3 EXEC dbo.Saldo_Revisar @Usuario,@Registro,@Huella,0,N'Aprobado',N'Prueba',N'Revisión antigua';
 ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Error=ERROR_NUMBER();IF XACT_STATE()<>0 ROLLBACK;
  IF NOT (@Caso IN (2,3) AND @Error=53203) THROW;
 END CATCH;
 IF @Caso>1 AND @Error=0 THROW 53301,N'No se rechazó la revisión antigua.',1;
 DELETE FROM @Insertados;
 SELECT @Caso Caso,N'Correcto; datos revertidos' Resultado;
 SET @Caso+=1;
END;
