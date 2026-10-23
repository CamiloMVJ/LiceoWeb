-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 50001, N'Seleccione LiceoWeb_Dev antes de ejecutar.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Matricula WHERE Matricula_Modalidad = N'Preescolar')
    INSERT dbo.Costo_Matricula (Matricula_Modalidad, Costo_Actual) VALUES (N'Preescolar', 450.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Matricula WHERE Matricula_Modalidad = N'Primaria')
    INSERT dbo.Costo_Matricula (Matricula_Modalidad, Costo_Actual) VALUES (N'Primaria', 450.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Matricula WHERE Matricula_Modalidad = N'Secundaria')
    INSERT dbo.Costo_Matricula (Matricula_Modalidad, Costo_Actual) VALUES (N'Secundaria', 500.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mensualidad WHERE Mensualidad_Modalidad = N'Preescolar')
    INSERT dbo.Costo_Mensualidad (Mensualidad_Modalidad, Costo_Actual) VALUES (N'Preescolar', 700.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mensualidad WHERE Mensualidad_Modalidad = N'Primaria')
    INSERT dbo.Costo_Mensualidad (Mensualidad_Modalidad, Costo_Actual) VALUES (N'Primaria', 700.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mensualidad WHERE Mensualidad_Modalidad = N'Secundaria')
    INSERT dbo.Costo_Mensualidad (Mensualidad_Modalidad, Costo_Actual) VALUES (N'Secundaria', 800.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Promocion WHERE Promocion_Modalidad = N'Preescolar')
    INSERT dbo.Costo_Promocion (Promocion_Modalidad, Costo_Actual) VALUES (N'Preescolar', 500.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Promocion WHERE Promocion_Modalidad = N'Primaria')
    INSERT dbo.Costo_Promocion (Promocion_Modalidad, Costo_Actual) VALUES (N'Primaria', 500.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Promocion WHERE Promocion_Modalidad = N'Secundaria')
    INSERT dbo.Costo_Promocion (Promocion_Modalidad, Costo_Actual) VALUES (N'Secundaria', 500.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mantenimiento WHERE Mantenimiento_Modalidad = N'Preescolar')
    INSERT dbo.Costo_Mantenimiento (Mantenimiento_Modalidad, Costo_Actual) VALUES (N'Preescolar', 900.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mantenimiento WHERE Mantenimiento_Modalidad = N'Primaria')
    INSERT dbo.Costo_Mantenimiento (Mantenimiento_Modalidad, Costo_Actual) VALUES (N'Primaria', 900.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_Mantenimiento WHERE Mantenimiento_Modalidad = N'Secundaria')
    INSERT dbo.Costo_Mantenimiento (Mantenimiento_Modalidad, Costo_Actual) VALUES (N'Secundaria', 900.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_EvBoTa WHERE EvBoTa_Modalidad = N'Preescolar')
    INSERT dbo.Costo_EvBoTa (EvBoTa_Modalidad, Costo_Actual) VALUES (N'Preescolar', 400.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_EvBoTa WHERE EvBoTa_Modalidad = N'Primaria')
    INSERT dbo.Costo_EvBoTa (EvBoTa_Modalidad, Costo_Actual) VALUES (N'Primaria', 400.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Costo_EvBoTa WHERE EvBoTa_Modalidad = N'Secundaria')
    INSERT dbo.Costo_EvBoTa (EvBoTa_Modalidad, Costo_Actual) VALUES (N'Secundaria', 450.00);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
