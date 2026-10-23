-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 50001, N'Seleccione LiceoWeb_Dev antes de ejecutar.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.PK_Mensualidades') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT PK_Mensualidades PRIMARY KEY (Id);

IF OBJECT_ID(N'dbo.PK_Abonos') IS NULL
    ALTER TABLE dbo.Abonos ADD CONSTRAINT PK_Abonos PRIMARY KEY (Registro_Estudiante);

IF OBJECT_ID(N'dbo.UQ_Matriculas_Estudiante_Anio') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT UQ_Matriculas_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N'dbo.UQ_Mensualidades_Estudiante_Periodo') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT UQ_Mensualidades_Estudiante_Periodo UNIQUE (Registro_Estudiante, Anio, Numero_Mes);

IF OBJECT_ID(N'dbo.UQ_Mantenimientos_Estudiante_Anio') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT UQ_Mantenimientos_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N'dbo.UQ_EvBoTaS_Estudiante_Anio') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT UQ_EvBoTaS_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N'dbo.CK_Pagos_Monto_NoNegativo') IS NULL
    ALTER TABLE dbo.Pagos ADD CONSTRAINT CK_Pagos_Monto_NoNegativo CHECK (Monto >= 0);

IF OBJECT_ID(N'dbo.CK_Abonos_Abono_Disponible_NoNegativo') IS NULL
    ALTER TABLE dbo.Abonos ADD CONSTRAINT CK_Abonos_Abono_Disponible_NoNegativo CHECK (Abono_Disponible >= 0);

IF OBJECT_ID(N'dbo.CK_Matriculas_Costo_Matricula_NoNegativo') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT CK_Matriculas_Costo_Matricula_NoNegativo CHECK (Costo_Matricula >= 0);

IF OBJECT_ID(N'dbo.CK_Mensualidades_Costo_Mensualidad_NoNegativo') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT CK_Mensualidades_Costo_Mensualidad_NoNegativo CHECK (Costo_Mensualidad >= 0);

IF OBJECT_ID(N'dbo.CK_Mantenimientos_Costo_Mantenimiento_NoNegativo') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT CK_Mantenimientos_Costo_Mantenimiento_NoNegativo CHECK (Costo_Mantenimiento >= 0);

IF OBJECT_ID(N'dbo.CK_EvBoTaS_Costo_EvBoTa_NoNegativo') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT CK_EvBoTaS_Costo_EvBoTa_NoNegativo CHECK (Costo_EvBoTa >= 0);

IF OBJECT_ID(N'dbo.CK_Promociones_Costo_Promocion_NoNegativo') IS NULL
    ALTER TABLE dbo.Promociones ADD CONSTRAINT CK_Promociones_Costo_Promocion_NoNegativo CHECK (Costo_Promocion >= 0);

IF OBJECT_ID(N'dbo.CK_Costo_Matricula_Costo_Actual_NoNegativo') IS NULL
    ALTER TABLE dbo.Costo_Matricula ADD CONSTRAINT CK_Costo_Matricula_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N'dbo.CK_Costo_Mensualidad_Costo_Actual_NoNegativo') IS NULL
    ALTER TABLE dbo.Costo_Mensualidad ADD CONSTRAINT CK_Costo_Mensualidad_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N'dbo.CK_Costo_Mantenimiento_Costo_Actual_NoNegativo') IS NULL
    ALTER TABLE dbo.Costo_Mantenimiento ADD CONSTRAINT CK_Costo_Mantenimiento_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N'dbo.CK_Costo_EvBoTa_Costo_Actual_NoNegativo') IS NULL
    ALTER TABLE dbo.Costo_EvBoTa ADD CONSTRAINT CK_Costo_EvBoTa_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N'dbo.CK_Costo_Promocion_Costo_Actual_NoNegativo') IS NULL
    ALTER TABLE dbo.Costo_Promocion ADD CONSTRAINT CK_Costo_Promocion_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N'dbo.CK_Arreglos_Pago_Monto_Anterior_NoNegativo') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Monto_Anterior_NoNegativo CHECK (Monto_Anterior >= 0);

IF OBJECT_ID(N'dbo.CK_Arreglos_Pago_Monto_Nuevo_NoNegativo') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Monto_Nuevo_NoNegativo CHECK (Monto_Nuevo >= 0);

IF OBJECT_ID(N'dbo.CK_Arreglos_Pago_Mes') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Mes CHECK (Mes_Inicio BETWEEN 1 AND 12);

IF OBJECT_ID(N'dbo.CK_Matriculas_Anio') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT CK_Matriculas_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N'dbo.CK_Mensualidades_Anio') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT CK_Mensualidades_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N'dbo.CK_Mantenimientos_Anio') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT CK_Mantenimientos_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N'dbo.CK_EvBoTaS_Anio') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT CK_EvBoTaS_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N'dbo.CK_Promociones_Anio') IS NULL
    ALTER TABLE dbo.Promociones ADD CONSTRAINT CK_Promociones_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Pagos') AND name = N'IX_Pagos_Fecha')
    CREATE INDEX IX_Pagos_Fecha ON dbo.Pagos (Fecha_Pago);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Pagos') AND name = N'IX_Pagos_Estudiante_Fecha')
    CREATE INDEX IX_Pagos_Estudiante_Fecha ON dbo.Pagos (Registro_Estudiante, Fecha_Pago);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Mensualidades') AND name = N'IX_Mensualidades_Estudiante_Estado_Periodo')
    CREATE INDEX IX_Mensualidades_Estudiante_Estado_Periodo ON dbo.Mensualidades (Registro_Estudiante, Estado, Anio, Numero_Mes);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Estudiantes') AND name = N'IX_Estudiantes_Nombre')
    CREATE INDEX IX_Estudiantes_Nombre ON dbo.Estudiantes (NombreEstudiante);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
