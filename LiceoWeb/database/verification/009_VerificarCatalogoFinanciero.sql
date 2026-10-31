-- Base de desarrollo sin actividad concurrente. Revierte todo; identidades pueden avanzar.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 52900,N'Use desarrollo sin transacciones abiertas.',1;
DECLARE @Admin nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
IF @Admin IS NULL THROW 52900,N'Requiere una cuenta Administrador.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.ObligacionLegada) THROW 52900,N'Requiere al menos una obligación de prueba para verificar la repetición de captura.',1;
DECLARE @Caso int=1,@Error int,@Json nvarchar(max),@Id int,@Tarifa int,@Anio int,@AnioNumero int,@Modalidad int,@Version varchar(18),@N int;
WHILE @Caso<=4
BEGIN
 SET @Error=0;
 DECLARE @Nombre nvarchar(30)=N'TEST-'+LEFT(CONVERT(nvarchar(36),NEWID()),8);
 BEGIN TRY
 BEGIN TRANSACTION;
 SET @AnioNumero=2098;
 WHILE EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Anio=@AnioNumero) SET @AnioNumero-=1;
 INSERT dbo.AnioLectivo(Anio) VALUES(@AnioNumero);SET @Anio=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.ModalidadAcademica(Nombre) VALUES(@Nombre);SET @Modalidad=CONVERT(int,SCOPE_IDENTITY());
 SET @Json=(SELECT 'Arancel' Accion,0 Id,@Nombre Codigo,@Nombre Nombre,CAST(1 AS bit) Activo,'Alta de prueba' Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Aranceles_Guardar @Admin,@Json;
 SELECT @Id=Id FROM dbo.Arancel WHERE Codigo=@Nombre;
 SET @Json=(SELECT 'Tarifa' Accion,0 Id,@Id ArancelId,@Modalidad ModalidadId,@Anio AnioId,150.25 Importe,CAST(1 AS bit) Activo,'Precio de prueba' Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Aranceles_Guardar @Admin,@Json;
 SELECT @Tarifa=Id,@Version=CONVERT(varchar(18),Version,1) FROM dbo.TarifaArancel WHERE ArancelId=@Id;
 IF @Caso=2 EXEC dbo.Aranceles_Guardar @Admin,@Json; -- Combinación duplicada.
 SET @Json=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(@Json,'$.Id',@Tarifa),'$.Version',@Version),'$.Importe',200.75);
 EXEC dbo.Aranceles_Guardar @Admin,@Json;
 IF @Caso=3 EXEC dbo.Aranceles_Guardar @Admin,@Json; -- Versión antigua.
 IF NOT EXISTS(SELECT 1 FROM dbo.HistorialTarifa WHERE TarifaId=@Tarifa AND ImporteAnterior=150.25 AND ImporteNuevo=200.75) THROW 52901,N'Falta historial de tarifa.',1;
 IF @Caso=4
 BEGIN
  SET @Json=(SELECT 'Mapeo' Accion,0 Id,'Pagos' Origen,@Id ArancelId,'Origen inválido' Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Aranceles_Guardar @Admin,@Json;
 END;
 -- Completar solo relaciones faltantes para comprobar repetición de captura.
 INSERT dbo.MapaConceptoLegado(Origen,ArancelId,UsuarioId)
 SELECT O.Origen,@Id,@Admin FROM (VALUES(N'Matriculas'),(N'Mensualidades'),(N'Mantenimientos'),(N'EvBoTaS'),(N'Promociones')) O(Origen)
 WHERE NOT EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado M WHERE M.Origen=O.Origen);
 SET @Json=N'{"Accion":"Preparar","Id":0,"Motivo":"Prueba de repetición"}';
 EXEC dbo.Aranceles_Guardar @Admin,@Json;
 SELECT @N=COUNT(*) FROM dbo.PreparacionObligacion;
 EXEC dbo.Aranceles_Guardar @Admin,@Json;
 IF (SELECT COUNT(*) FROM dbo.PreparacionObligacion)<>@N THROW 52901,N'La captura duplicó registros.',1;
 ROLLBACK;
 END TRY
 BEGIN CATCH
  SET @Error=ERROR_NUMBER();
  IF XACT_STATE()<>0 ROLLBACK;
  IF NOT ((@Caso=2 AND @Error IN (2601,2627)) OR (@Caso=3 AND @Error=52803) OR (@Caso=4 AND @Error=52804)) THROW;
 END CATCH;
 IF @Caso>1 AND @Error=0 THROW 52901,N'No se rechazó el escenario inválido.',1;
 SELECT @Caso Caso,N'Correcto; cambios revertidos' Resultado;
 SET @Caso+=1;
END;
