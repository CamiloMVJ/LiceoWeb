-- Requiere copia de desarrollo conciliada, sin actividad concurrente. NO aplica el corte.
SET XACT_ABORT ON;
IF DB_NAME()<>'LiceoWeb_Dev' OR @@TRANCOUNT<>0 THROW 53500,N'Use desarrollo sin transacciones abiertas.',1;
IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Migrado=1) THROW 53500,N'Esta prueba requiere libro anterior abierto.',1;
DECLARE @Usuario nvarchar(450)=(SELECT TOP(1) U.UserId FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE R.Name='Administrador');
IF @Usuario IS NULL THROW 53500,N'Requiere Administrador.',1;
DECLARE @Operacion uniqueidentifier=NEWID(),@Cargos bigint=(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante),@Saldos bigint=(SELECT COUNT_BIG(*) FROM dbo.SaldoFinanciero),@Mapas bigint=(SELECT COUNT_BIG(*) FROM dbo.ObligacionMigrada),@Pagos bigint=(SELECT COUNT_BIG(*) FROM dbo.Pagos),@Recibos bigint=(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple),@Vinculos bigint=(SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion WHERE CargoId IS NOT NULL);
EXEC dbo.CorteFinanciero_Ejecutar @UsuarioId=@Usuario,@Operacion=@Operacion,@Aplicar=0;
IF @Cargos<>(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante) OR @Saldos<>(SELECT COUNT_BIG(*) FROM dbo.SaldoFinanciero) OR @Mapas<>(SELECT COUNT_BIG(*) FROM dbo.ObligacionMigrada) OR @Pagos<>(SELECT COUNT_BIG(*) FROM dbo.Pagos) OR @Recibos<>(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple) OR @Vinculos<>(SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion WHERE CargoId IS NOT NULL) OR EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Migrado=1) THROW 53501,N'La simulación dejó cambios persistidos.',1;
-- Repetir la simulación no produce cargos ni saldos duplicados.
EXEC dbo.CorteFinanciero_Ejecutar @UsuarioId=@Usuario,@Operacion=@Operacion,@Aplicar=0;
IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante) OR EXISTS(SELECT 1 FROM dbo.SaldoFinanciero) OR EXISTS(SELECT 1 FROM dbo.ObligacionMigrada) THROW 53501,N'La repetición dejó datos.',1;
SELECT N'Correcto: simulaciones revertidas; sin nuevos cargos, saldos ni pagos.' Resultado;
