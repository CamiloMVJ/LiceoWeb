-- LICEOWEB · INSTALACIÓN COMPLETA CON DEMOSTRACIÓN · esquema 001–023
-- Ejecutar TODO con F5 en SSMS NORMAL (no necesita modo SQLCMD ni archivos externos).
-- Editar solo @Base si deseas otro nombre. Debe ser una base NUEVA.
-- No borra ni actualiza bases existentes. Requiere permiso CREATE DATABASE y SQL Server 2017+.
-- Incluye Identity, procedimientos vigentes, roles, cuentas y datos ficticios.
-- Las cuentas siguientes usan la contraseña de demostración Admin1234#:
-- camilo@liceo.test (Administrador), profesor@liceo.test (Profesor), cajero@liceo.test (Cajero).
-- El script solo almacena hashes Identity V3 verificados, nunca contraseñas en texto plano.
-- No usar estas credenciales públicas en una instalación de producción.
-- Al finalizar: Migrado=1, matrícula oficial configurada, 12 estudiantes y clases demo.
-- Solo queda conectar la aplicación a ESTA base (DefaultConnection). No crear cuentas
-- por separado, ejecutar migraciones individuales ni aplicar el corte manualmente.
-- No contiene el archivo obsoleto Procedimientos.sql de Registro_Pagos.
-- Generado con database/tools/generar_instalador.py. No editar los lotes a mano.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54900,N'Cierra las transacciones antes de instalar.',1;
SET IMPLICIT_TRANSACTIONS OFF;
DECLARE @Base sysname=N'LiceoWeb_Dev'; -- ÚNICA CONFIGURACIÓN: nombre de la base nueva.
IF @Base IS NULL OR LEN(@Base)=0 OR @Base COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_]%'
 THROW 54900,N'Usa solo letras, números y guion bajo para el nombre de la base.',1;
IF DB_ID(@Base) IS NOT NULL
 THROW 54900,N'La base ya existe. No se modificó: elige otro nombre nuevo y conecta LiceoWeb a ese nombre.',1;

DECLARE @Etapas TABLE(Orden int IDENTITY PRIMARY KEY,Nombre nvarchar(200),Texto nvarchar(max));

-- Identity · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Identity · lote 1',N'IF OBJECT_ID(N''[__EFMigrationsHistory]'') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
BEGIN TRANSACTION;
CREATE TABLE [AspNetRoles] (
    [Id] nvarchar(450) NOT NULL,
    [Name] nvarchar(256) NULL,
    [NormalizedName] nvarchar(256) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
);
CREATE TABLE [AspNetUsers] (
    [Id] nvarchar(450) NOT NULL,
    [UserName] nvarchar(256) NULL,
    [NormalizedUserName] nvarchar(256) NULL,
    [Email] nvarchar(256) NULL,
    [NormalizedEmail] nvarchar(256) NULL,
    [EmailConfirmed] bit NOT NULL,
    [PasswordHash] nvarchar(max) NULL,
    [SecurityStamp] nvarchar(max) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    [PhoneNumber] nvarchar(max) NULL,
    [PhoneNumberConfirmed] bit NOT NULL,
    [TwoFactorEnabled] bit NOT NULL,
    [LockoutEnd] datetimeoffset NULL,
    [LockoutEnabled] bit NOT NULL,
    [AccessFailedCount] int NOT NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
);
CREATE TABLE [AspNetRoleClaims] (
    [Id] int NOT NULL IDENTITY,
    [RoleId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE
);
CREATE TABLE [AspNetUserClaims] (
    [Id] int NOT NULL IDENTITY,
    [UserId] nvarchar(450) NOT NULL,
    [ClaimType] nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
CREATE TABLE [AspNetUserLogins] (
    [LoginProvider] nvarchar(128) NOT NULL,
    [ProviderKey] nvarchar(128) NOT NULL,
    [ProviderDisplayName] nvarchar(max) NULL,
    [UserId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
    CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
CREATE TABLE [AspNetUserRoles] (
    [UserId] nvarchar(450) NOT NULL,
    [RoleId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
CREATE TABLE [AspNetUserTokens] (
    [UserId] nvarchar(450) NOT NULL,
    [LoginProvider] nvarchar(128) NOT NULL,
    [Name] nvarchar(128) NOT NULL,
    [Value] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
    CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
);
CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [AspNetRoleClaims] ([RoleId]);
CREATE UNIQUE INDEX [RoleNameIndex] ON [AspNetRoles] ([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;
CREATE INDEX [IX_AspNetUserClaims_UserId] ON [AspNetUserClaims] ([UserId]);
CREATE INDEX [IX_AspNetUserLogins_UserId] ON [AspNetUserLogins] ([UserId]);
CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [AspNetUserRoles] ([RoleId]);
CREATE INDEX [EmailIndex] ON [AspNetUsers] ([NormalizedEmail]);
CREATE UNIQUE INDEX [UserNameIndex] ON [AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N''00000000000000_CreateIdentitySchema'', N''8.0.32'');
COMMIT;');

-- Registro de instalación · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Registro de instalación · lote 1',N'CREATE TABLE dbo.InstalacionInicial(
        Etapa nvarchar(160) NOT NULL PRIMARY KEY, FuenteSha256 varchar(64) NOT NULL,
        FechaUTC datetime2 NOT NULL DEFAULT SYSUTCDATETIME());');

-- 001_EstructuraInicial.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'001_EstructuraInicial.sql · lote 1',N'-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N''__LICEO_BASE__''
    THROW 50001, N''Seleccione __LICEO_BASE__ antes de ejecutar.'', 1;

IF OBJECT_ID(N''dbo.Estudiantes'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Historial_Bajas'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Pagos'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Arreglos_Pago'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Costo_Matricula'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Costo_Mensualidad'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Costo_Promocion'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Costo_Mantenimiento'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Costo_EvBoTa'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Matriculas'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Mantenimientos'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.EvBoTaS'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Mensualidades'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Promociones'', N''U'') IS NOT NULL OR
   OBJECT_ID(N''dbo.Abonos'', N''U'') IS NOT NULL
    THROW 50002, N''Ya existen tablas del negocio. No repita esta instalacion.'', 1;
IF OBJECT_ID(N''dbo.Secuencia_Estudiantes'', N''SO'') IS NOT NULL
    THROW 50003, N''Ya existe la secuencia. Revise la base seleccionada.'', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    CREATE SEQUENCE dbo.Secuencia_Estudiantes AS bigint
        START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9999999 NO CYCLE;

CREATE TABLE dbo.Estudiantes (
Registro nvarchar(10) primary key default (N''E_'' + right(N''0000000'' + cast(next value for Secuencia_Estudiantes as nvarchar), 7)),
    NombreEstudiante nvarchar(100) not null,
    Modalidad nvarchar(20) check (Modalidad in (N''Preescolar'',N''Primaria'',N''Secundaria'')) not null,
    Grado nvarchar(50) not null, 
    FechaNacimiento date not null,
    Sexo char(1) check (Sexo in (N''M'',N''F''))not null,
    NombreTutor nvarchar(100) not null,
    Telefono nvarchar(9) not null,
    Direccion nvarchar(200) not null,
    Notas nvarchar(200),
    CodigoEstudiante nvarchar(25) default N''Aun no asignado'',
    Estado nvarchar(10) not null default N''Activo'' check (Estado in (N''Activo'',N''Inactivo''))
);

CREATE TABLE dbo.Historial_Bajas (
IdBaja int identity(1,1) primary key,
    RegistroEstudiante nvarchar(10) not null,
    Motivo nvarchar(500) not null,
    FechaBaja datetime default getdate(),
    constraint FK_Baja_Estudiante foreign key (RegistroEstudiante) references Estudiantes(Registro)
);

CREATE TABLE dbo.Pagos (
Id int identity(1,1) not null,
    Id_Comprobante nvarchar(25) primary key not null, 
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Fecha_Pago datetime default getdate() not null, 
    Concepto nvarchar(35) check (Concepto in (N''Matrícula'', N''Mensualidad'', N''Promoción'', N''Mantenimiento'', N''Evaluaciones, Boletín y Tarjeta'', N''Uso de Saldo'')) not null,
    Monto decimal(18,2) not null,
	Metodo_Pago nvarchar(15) check (Metodo_Pago in (N''Efectivo'', N''Transferencia'', N''Saldo'')) not null,
	Referencia_Transaccion nvarchar(100) null,
    Descripcion nvarchar(100)
);

CREATE TABLE dbo.Arreglos_Pago (
Id int identity(1,1) primary key,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Fecha_Registro datetime default getdate(),
    Monto_Anterior decimal(18,2) not null,
    Monto_Nuevo decimal(18,2) not null,
    Mes_Inicio int not null,
    Motivo nvarchar(200)
);

CREATE TABLE dbo.Costo_Matricula (
Matricula_Modalidad nvarchar(20) primary key not null,
    Costo_Actual decimal(18,2) not null
);

CREATE TABLE dbo.Costo_Mensualidad (
Mensualidad_Modalidad nvarchar(20) primary key not null,
    Costo_Actual decimal(18,2) not null
);

CREATE TABLE dbo.Costo_Promocion (
Promocion_Modalidad nvarchar(20) primary key not null,
    Costo_Actual decimal(18,2) not null
);

CREATE TABLE dbo.Costo_Mantenimiento (
Mantenimiento_Modalidad nvarchar(20) primary key not null,
    Costo_Actual decimal(18,2) not null
);

CREATE TABLE dbo.Costo_EvBoTa (
EvBoTa_Modalidad nvarchar(20) primary key not null,
    Costo_Actual decimal(18,2) not null
);

CREATE TABLE dbo.Matriculas (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) not null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_Matricula(Matricula_Modalidad),
    Grado nvarchar(50) not null, 
    Costo_Matricula decimal(18,2) not null,
    Anio int not null
);

CREATE TABLE dbo.Mantenimientos (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_Mantenimiento(Mantenimiento_Modalidad),
    Grado nvarchar(50) not null, 
    Costo_Mantenimiento decimal(18,2) not null,
    Anio int not null,
	Estado nvarchar(10) default N''Pendiente'' check (Estado in (N''Pendiente'',N''Cancelado'')) not null
);

CREATE TABLE dbo.EvBoTaS (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_EvBoTa(EvBoTa_Modalidad),
    Grado nvarchar(50) not null, 
    Costo_EvBoTa decimal(18,2) not null,
    Anio int not null,
	Estado nvarchar(10) default N''Pendiente'' check (Estado in (N''Pendiente'',N''Cancelado'')) not null
);

CREATE TABLE dbo.Mensualidades (
Id int identity(1,1) not null,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null, 
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_Mensualidad(Mensualidad_Modalidad),
    Costo_Mensualidad decimal(18,2) not null, 
    Mes nvarchar(10) not null,
    Numero_Mes int check (Numero_Mes between 1 and 12) not null ,
    Anio int not null,
    Estado nvarchar(10) default N''Pendiente'' check (Estado in (N''Pendiente'',N''Cancelado'',N''Vencido'')) not null
);

CREATE TABLE dbo.Promociones (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_Promocion(Promocion_Modalidad),
    Costo_Promocion decimal(18,2) not null,
    Anio int not null,
    Estado nvarchar(10) default N''Pendiente'' check (Estado in (N''Pendiente'',N''Cancelado'')) not null,
    constraint UQ_Promocion_Unica unique (Registro_Estudiante, Anio)
);

CREATE TABLE dbo.Abonos (
Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Abono_Disponible decimal(18,2) default 0 not null
);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;');

-- Confirmación 001_EstructuraInicial.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 001_EstructuraInicial.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''001_EstructuraInicial.sql'',''69d25f8546ec22b5247043c003825610ecf953d05ce2d182399e6d605025a97c'');');

-- 002_Integridad.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'002_Integridad.sql · lote 1',N'-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N''__LICEO_BASE__''
    THROW 50001, N''Seleccione __LICEO_BASE__ antes de ejecutar.'', 1;

BEGIN TRY
    BEGIN TRANSACTION;
IF OBJECT_ID(N''dbo.PK_Mensualidades'') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT PK_Mensualidades PRIMARY KEY (Id);

IF OBJECT_ID(N''dbo.PK_Abonos'') IS NULL
    ALTER TABLE dbo.Abonos ADD CONSTRAINT PK_Abonos PRIMARY KEY (Registro_Estudiante);

IF OBJECT_ID(N''dbo.UQ_Matriculas_Estudiante_Anio'') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT UQ_Matriculas_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N''dbo.UQ_Mensualidades_Estudiante_Periodo'') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT UQ_Mensualidades_Estudiante_Periodo UNIQUE (Registro_Estudiante, Anio, Numero_Mes);

IF OBJECT_ID(N''dbo.UQ_Mantenimientos_Estudiante_Anio'') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT UQ_Mantenimientos_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N''dbo.UQ_EvBoTaS_Estudiante_Anio'') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT UQ_EvBoTaS_Estudiante_Anio UNIQUE (Registro_Estudiante, Anio);

IF OBJECT_ID(N''dbo.CK_Pagos_Monto_NoNegativo'') IS NULL
    ALTER TABLE dbo.Pagos ADD CONSTRAINT CK_Pagos_Monto_NoNegativo CHECK (Monto >= 0);

IF OBJECT_ID(N''dbo.CK_Abonos_Abono_Disponible_NoNegativo'') IS NULL
    ALTER TABLE dbo.Abonos ADD CONSTRAINT CK_Abonos_Abono_Disponible_NoNegativo CHECK (Abono_Disponible >= 0);

IF OBJECT_ID(N''dbo.CK_Matriculas_Costo_Matricula_NoNegativo'') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT CK_Matriculas_Costo_Matricula_NoNegativo CHECK (Costo_Matricula >= 0);

IF OBJECT_ID(N''dbo.CK_Mensualidades_Costo_Mensualidad_NoNegativo'') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT CK_Mensualidades_Costo_Mensualidad_NoNegativo CHECK (Costo_Mensualidad >= 0);

IF OBJECT_ID(N''dbo.CK_Mantenimientos_Costo_Mantenimiento_NoNegativo'') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT CK_Mantenimientos_Costo_Mantenimiento_NoNegativo CHECK (Costo_Mantenimiento >= 0);

IF OBJECT_ID(N''dbo.CK_EvBoTaS_Costo_EvBoTa_NoNegativo'') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT CK_EvBoTaS_Costo_EvBoTa_NoNegativo CHECK (Costo_EvBoTa >= 0);

IF OBJECT_ID(N''dbo.CK_Promociones_Costo_Promocion_NoNegativo'') IS NULL
    ALTER TABLE dbo.Promociones ADD CONSTRAINT CK_Promociones_Costo_Promocion_NoNegativo CHECK (Costo_Promocion >= 0);

IF OBJECT_ID(N''dbo.CK_Costo_Matricula_Costo_Actual_NoNegativo'') IS NULL
    ALTER TABLE dbo.Costo_Matricula ADD CONSTRAINT CK_Costo_Matricula_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N''dbo.CK_Costo_Mensualidad_Costo_Actual_NoNegativo'') IS NULL
    ALTER TABLE dbo.Costo_Mensualidad ADD CONSTRAINT CK_Costo_Mensualidad_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N''dbo.CK_Costo_Mantenimiento_Costo_Actual_NoNegativo'') IS NULL
    ALTER TABLE dbo.Costo_Mantenimiento ADD CONSTRAINT CK_Costo_Mantenimiento_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N''dbo.CK_Costo_EvBoTa_Costo_Actual_NoNegativo'') IS NULL
    ALTER TABLE dbo.Costo_EvBoTa ADD CONSTRAINT CK_Costo_EvBoTa_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N''dbo.CK_Costo_Promocion_Costo_Actual_NoNegativo'') IS NULL
    ALTER TABLE dbo.Costo_Promocion ADD CONSTRAINT CK_Costo_Promocion_Costo_Actual_NoNegativo CHECK (Costo_Actual >= 0);

IF OBJECT_ID(N''dbo.CK_Arreglos_Pago_Monto_Anterior_NoNegativo'') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Monto_Anterior_NoNegativo CHECK (Monto_Anterior >= 0);

IF OBJECT_ID(N''dbo.CK_Arreglos_Pago_Monto_Nuevo_NoNegativo'') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Monto_Nuevo_NoNegativo CHECK (Monto_Nuevo >= 0);

IF OBJECT_ID(N''dbo.CK_Arreglos_Pago_Mes'') IS NULL
    ALTER TABLE dbo.Arreglos_Pago ADD CONSTRAINT CK_Arreglos_Pago_Mes CHECK (Mes_Inicio BETWEEN 1 AND 12);

IF OBJECT_ID(N''dbo.CK_Matriculas_Anio'') IS NULL
    ALTER TABLE dbo.Matriculas ADD CONSTRAINT CK_Matriculas_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N''dbo.CK_Mensualidades_Anio'') IS NULL
    ALTER TABLE dbo.Mensualidades ADD CONSTRAINT CK_Mensualidades_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N''dbo.CK_Mantenimientos_Anio'') IS NULL
    ALTER TABLE dbo.Mantenimientos ADD CONSTRAINT CK_Mantenimientos_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N''dbo.CK_EvBoTaS_Anio'') IS NULL
    ALTER TABLE dbo.EvBoTaS ADD CONSTRAINT CK_EvBoTaS_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF OBJECT_ID(N''dbo.CK_Promociones_Anio'') IS NULL
    ALTER TABLE dbo.Promociones ADD CONSTRAINT CK_Promociones_Anio CHECK (Anio BETWEEN 1900 AND 9999);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''dbo.Pagos'') AND name = N''IX_Pagos_Fecha'')
    CREATE INDEX IX_Pagos_Fecha ON dbo.Pagos (Fecha_Pago);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''dbo.Pagos'') AND name = N''IX_Pagos_Estudiante_Fecha'')
    CREATE INDEX IX_Pagos_Estudiante_Fecha ON dbo.Pagos (Registro_Estudiante, Fecha_Pago);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''dbo.Mensualidades'') AND name = N''IX_Mensualidades_Estudiante_Estado_Periodo'')
    CREATE INDEX IX_Mensualidades_Estudiante_Estado_Periodo ON dbo.Mensualidades (Registro_Estudiante, Estado, Anio, Numero_Mes);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''dbo.Estudiantes'') AND name = N''IX_Estudiantes_Nombre'')
    CREATE INDEX IX_Estudiantes_Nombre ON dbo.Estudiantes (NombreEstudiante);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;');

-- Confirmación 002_Integridad.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 002_Integridad.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''002_Integridad.sql'',''e7baf2f68dffd5387d293b61146e8bb43621c35ec4f08b51eae240d87e0f6396'');');

-- 003_ComprobantesAuditoria.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'003_ComprobantesAuditoria.sql · lote 1',N'-- Ejecutar COMPLETO en __LICEO_BASE__. No modifica los pagos existentes.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N''__LICEO_BASE__''
    THROW 51000, N''Seleccione __LICEO_BASE__.'', 1;
IF OBJECT_ID(N''dbo.Pagos'', N''U'') IS NULL OR OBJECT_ID(N''dbo.AspNetUsers'', N''U'') IS NULL
    THROW 51001, N''Faltan las tablas del negocio o las migraciones de Identity.'', 1;
IF OBJECT_ID(N''dbo.Historial_Comprobantes'', N''U'') IS NOT NULL
   OR OBJECT_ID(N''dbo.Auditoria'', N''U'') IS NOT NULL
   OR OBJECT_ID(N''dbo.Secuencia_Comprobantes'', N''SO'') IS NOT NULL
    THROW 51002, N''La etapa 8 ya existe total o parcialmente. No repetir sin revisar.'', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Se inicia despues de cualquier comprobante RC-n preexistente.
    DECLARE @Maximo bigint = ISNULL((
        SELECT MAX(TRY_CONVERT(bigint, SUBSTRING(Id_Comprobante, 4, 22)))
        FROM dbo.Pagos WHERE Id_Comprobante LIKE N''RC-%''), 0);
    IF @Maximo >= 9223372036854775807
        THROW 51003, N''Se agoto la numeracion disponible.'', 1;
    DECLARE @Inicio bigint = CASE WHEN @Maximo < 1 THEN 1 ELSE @Maximo + 1 END;
    DECLARE @Sql nvarchar(max) =
        N''CREATE SEQUENCE dbo.Secuencia_Comprobantes AS bigint START WITH ''
        + CONVERT(nvarchar(20), @Inicio)
        + N'' INCREMENT BY 1 MINVALUE 1 NO MAXVALUE NO CYCLE;'';
    EXEC sys.sp_executesql @Sql;

    CREATE TABLE dbo.Historial_Comprobantes (
        Id_Comprobante nvarchar(25) NOT NULL
            CONSTRAINT PK_Historial_Comprobantes PRIMARY KEY,
        IdOperacion uniqueidentifier NOT NULL
            CONSTRAINT UQ_Historial_Comprobantes_Operacion UNIQUE,
        UsuarioId nvarchar(450) NOT NULL,
        UsuarioNombre nvarchar(256) NOT NULL,
        NombreEstudiante nvarchar(100) NOT NULL,
        Modalidad nvarchar(20) NOT NULL,
        Grado nvarchar(50) NOT NULL,
        DineroRecibido decimal(18,2) NOT NULL,
        SaldoAnterior decimal(18,2) NOT NULL,
        SaldoUtilizado decimal(18,2) NOT NULL,
        DeudaCancelada decimal(18,2) NOT NULL,
        CambioDevuelto decimal(18,2) NOT NULL,
        SaldoFinal decimal(18,2) NOT NULL,
        CONSTRAINT FK_Historial_Comprobantes_Pago
            FOREIGN KEY (Id_Comprobante) REFERENCES dbo.Pagos(Id_Comprobante),
        CONSTRAINT FK_Historial_Comprobantes_Usuario
            FOREIGN KEY (UsuarioId) REFERENCES dbo.AspNetUsers(Id),
        CONSTRAINT CK_Historial_Comprobantes_Importes CHECK (
            DineroRecibido >= 0 AND SaldoAnterior >= 0 AND SaldoUtilizado >= 0
            AND DeudaCancelada >= 0 AND CambioDevuelto >= 0 AND SaldoFinal >= 0
            AND SaldoUtilizado <= SaldoAnterior AND SaldoUtilizado <= DeudaCancelada
            AND CambioDevuelto <= DineroRecibido
            AND DeudaCancelada - SaldoUtilizado <= DineroRecibido - CambioDevuelto
            AND SaldoAnterior + DineroRecibido = DeudaCancelada + CambioDevuelto + SaldoFinal)
    );

    CREATE TABLE dbo.Auditoria (
        Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Auditoria PRIMARY KEY,
        Fecha datetime2(3) NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT (
            CONVERT(datetime2(3), SYSUTCDATETIME()
                AT TIME ZONE ''UTC'' AT TIME ZONE ''Central America Standard Time'')),
        UsuarioId nvarchar(450) NOT NULL,
        UsuarioNombre nvarchar(256) NOT NULL,
        Accion nvarchar(50) NOT NULL,
        Entidad nvarchar(80) NOT NULL,
        RegistroId nvarchar(100) NOT NULL,
        IdOperacion uniqueidentifier NOT NULL,
        AntesJson nvarchar(max) NULL,
        DespuesJson nvarchar(max) NULL,
        CONSTRAINT FK_Auditoria_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.AspNetUsers(Id),
        CONSTRAINT CK_Auditoria_AntesJson CHECK (AntesJson IS NULL OR ISJSON(AntesJson) = 1),
        CONSTRAINT CK_Auditoria_DespuesJson CHECK (DespuesJson IS NULL OR ISJSON(DespuesJson) = 1)
    );
    CREATE INDEX IX_Auditoria_Entidad_Registro ON dbo.Auditoria(Entidad, RegistroId, Fecha);
    CREATE INDEX IX_Auditoria_Operacion ON dbo.Auditoria(IdOperacion);
    CREATE INDEX IX_Auditoria_Usuario_Fecha ON dbo.Auditoria(UsuarioId, Fecha);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;');

-- Confirmación 003_ComprobantesAuditoria.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 003_ComprobantesAuditoria.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''003_ComprobantesAuditoria.sql'',''ba3fed7bd0e2f6a589bc79f10bec90b8ae185835422f83263b00d0672d897e62'');');

-- 004_RevisionProfesor.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'004_RevisionProfesor.sql · lote 1',N'-- Ampliación aditiva. No elimina ni transforma registros históricos.
-- Instalar después de 003 y de Identity, sobre una copia respaldada.
SET XACT_ABORT ON;
IF DB_NAME() <> N''__LICEO_BASE__'' THROW 52000, N''Base incorrecta.'', 1;
IF OBJECT_ID(''dbo.Estudiantes'') IS NULL OR OBJECT_ID(''dbo.AspNetUsers'') IS NULL
 THROW 52001, N''Instale negocio e Identity primero.'', 1;
IF OBJECT_ID(''dbo.ExpedienteAmpliado'') IS NOT NULL
 THROW 52002, N''Esta ampliación ya existe; no repetir.'', 1;
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE dbo.ExpedienteAmpliado (
 Registro nvarchar(10) PRIMARY KEY REFERENCES dbo.Estudiantes(Registro),
 Identificacion nvarchar(50) NULL, TipoSangre nvarchar(10) NULL,
 Alergias nvarchar(1000) NULL, Padecimientos nvarchar(1000) NULL,
 IndicacionesEmergencia nvarchar(1000) NULL,
 TipoIngreso nvarchar(20) NOT NULL CHECK(TipoIngreso IN (''Nuevo'',''Traslado'')),
 CodigoTraslado nvarchar(100) NULL, CentroProcedencia nvarchar(200) NULL,
 Version rowversion,
 CHECK(TipoIngreso <> ''Traslado'' OR LEN(LTRIM(RTRIM(CodigoTraslado))) > 0 AND CodigoTraslado IS NOT NULL)
);
CREATE TABLE dbo.ResponsableEstudiante (
 Id int IDENTITY PRIMARY KEY, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 Vinculo nvarchar(20) NOT NULL CHECK(Vinculo IN (''Padre'',''Madre'',''Otro'')),
 Nombre nvarchar(200) NOT NULL, Direccion nvarchar(300) NULL,
 CentroTrabajo nvarchar(200) NULL, Telefono nvarchar(30) NULL, Parentesco nvarchar(50) NULL,
 Desde date NOT NULL, Hasta date NULL, CHECK(Hasta IS NULL OR Hasta >= Desde)
);
CREATE TABLE dbo.TutelaEstudiante (
 Id int IDENTITY PRIMARY KEY, ResponsableId int NOT NULL REFERENCES dbo.ResponsableEstudiante(Id),
 Desde date NOT NULL, Hasta date NULL, Motivo nvarchar(500) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
 NombreHistorico nvarchar(200) NOT NULL, DocumentoReferencia nvarchar(200) NULL,
 CHECK(Hasta IS NULL OR Hasta >= Desde)
);
CREATE TABLE dbo.DocumentoEstudiante (
 Id int IDENTITY PRIMARY KEY, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 Tipo nvarchar(100) NOT NULL, Estado nvarchar(20) NOT NULL CHECK(Estado IN (''Pendiente'',''Recibido'',''Verificado'')),
 Fecha date NULL, Observacion nvarchar(500) NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id)
);
CREATE TABLE dbo.AnioLectivo(Id int IDENTITY PRIMARY KEY, Anio int NOT NULL UNIQUE CHECK(Anio BETWEEN 1900 AND 9999), Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.PeriodoAcademico(Id int IDENTITY PRIMARY KEY, AnioId int NOT NULL REFERENCES dbo.AnioLectivo(Id), Nombre nvarchar(80) NOT NULL, Inicio date NOT NULL, Fin date NOT NULL, Cerrado bit NOT NULL DEFAULT 0, CHECK(Fin>=Inicio), UNIQUE(AnioId,Nombre));
CREATE TABLE dbo.ModalidadAcademica(Id int IDENTITY PRIMARY KEY, Nombre nvarchar(80) NOT NULL UNIQUE, Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.TurnoAcademico(Id int IDENTITY PRIMARY KEY, Nombre nvarchar(80) NOT NULL UNIQUE, Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.Aula(Id int IDENTITY PRIMARY KEY, Nombre nvarchar(80) NOT NULL UNIQUE, Ubicacion nvarchar(200) NOT NULL, Capacidad int NOT NULL CHECK(Capacidad>0), Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.Asignatura(Id int IDENTITY PRIMARY KEY, Codigo nvarchar(30) NOT NULL UNIQUE, Nombre nvarchar(100) NOT NULL, Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.Pensum(Id int IDENTITY PRIMARY KEY, AnioId int NOT NULL REFERENCES dbo.AnioLectivo(Id), ModalidadId int NOT NULL REFERENCES dbo.ModalidadAcademica(Id), Nivel nvarchar(50) NOT NULL, UNIQUE(AnioId,ModalidadId,Nivel));
CREATE TABLE dbo.PensumAsignatura(PensumId int NOT NULL REFERENCES dbo.Pensum(Id), AsignaturaId int NOT NULL REFERENCES dbo.Asignatura(Id), PRIMARY KEY(PensumId,AsignaturaId));
CREATE TABLE dbo.GrupoAcademico(Id int IDENTITY PRIMARY KEY, PensumId int NOT NULL REFERENCES dbo.Pensum(Id), PeriodoId int NOT NULL REFERENCES dbo.PeriodoAcademico(Id), TurnoId int NOT NULL REFERENCES dbo.TurnoAcademico(Id), AulaId int NOT NULL REFERENCES dbo.Aula(Id), Seccion nvarchar(30) NOT NULL, UNIQUE(PensumId,PeriodoId,TurnoId,Seccion));
CREATE TABLE dbo.GrupoEstudiante(GrupoId int NOT NULL REFERENCES dbo.GrupoAcademico(Id), Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro), PRIMARY KEY(GrupoId,Registro));
CREATE TABLE dbo.AsignacionDocente(Id int IDENTITY PRIMARY KEY, GrupoId int NOT NULL REFERENCES dbo.GrupoAcademico(Id), AsignaturaId int NOT NULL REFERENCES dbo.Asignatura(Id), UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id), UNIQUE(GrupoId,AsignaturaId));
CREATE TABLE dbo.HorarioClase(Id int IDENTITY PRIMARY KEY, AsignacionId int NOT NULL REFERENCES dbo.AsignacionDocente(Id), Dia tinyint NOT NULL CHECK(Dia BETWEEN 1 AND 7), Inicio time NOT NULL, Fin time NOT NULL, CHECK(Fin>Inicio));
CREATE TABLE dbo.TipoEvaluacion(Id int IDENTITY PRIMARY KEY, Nombre nvarchar(100) NOT NULL UNIQUE, Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.Evaluacion(Id int IDENTITY PRIMARY KEY, AsignacionId int NOT NULL REFERENCES dbo.AsignacionDocente(Id), TipoId int NOT NULL REFERENCES dbo.TipoEvaluacion(Id), Nombre nvarchar(100) NOT NULL, Fecha date NOT NULL, Maximo decimal(7,2) NOT NULL CHECK(Maximo>0), Peso decimal(5,2) NOT NULL CHECK(Peso>0 AND Peso<=100));
CREATE TABLE dbo.Calificacion(EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id), Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro), Nota decimal(7,2) NULL CHECK(Nota>=0), Observacion nvarchar(500) NULL, UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id), Version rowversion, PRIMARY KEY(EvaluacionId,Registro));
CREATE TABLE dbo.Arancel(Id int IDENTITY PRIMARY KEY, Codigo nvarchar(30) NOT NULL UNIQUE, Nombre nvarchar(150) NOT NULL, Activo bit NOT NULL DEFAULT 1);
CREATE TABLE dbo.TarifaArancel(Id int IDENTITY PRIMARY KEY, ArancelId int NOT NULL REFERENCES dbo.Arancel(Id), ModalidadId int NOT NULL REFERENCES dbo.ModalidadAcademica(Id), AnioId int NOT NULL REFERENCES dbo.AnioLectivo(Id), Importe decimal(18,2) NOT NULL CHECK(Importe>=0), UNIQUE(ArancelId,ModalidadId,AnioId));
CREATE TABLE dbo.CargoEstudiante(Id bigint IDENTITY PRIMARY KEY, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro), TarifaId int NOT NULL REFERENCES dbo.TarifaArancel(Id), Referencia nvarchar(80) NOT NULL, DescripcionHistorica nvarchar(200) NOT NULL, Importe decimal(18,2) NOT NULL CHECK(Importe>0), Vencimiento date NOT NULL, Anulado bit NOT NULL DEFAULT 0, UNIQUE(Registro,TarifaId,Referencia));
-- Recibos nuevos separados del modelo heredado de concepto único.
-- La transición exige conciliación antes de activar el nuevo cobro.
CREATE TABLE dbo.ReciboMultiple(Id bigint IDENTITY PRIMARY KEY, Numero nvarchar(25) NOT NULL UNIQUE, Operacion uniqueidentifier NOT NULL UNIQUE, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro), Pagador nvarchar(200) NOT NULL, UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id), Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), Metodo nvarchar(20) NOT NULL CHECK(Metodo IN (''Efectivo'',''Transferencia'')), Referencia nvarchar(100) NULL, Recibido decimal(18,2) NOT NULL CHECK(Recibido>0), Cambio decimal(18,2) NOT NULL CHECK(Cambio>=0), CHECK(Cambio<=Recibido), CHECK(Metodo<>''Transferencia'' OR Referencia IS NOT NULL));
CREATE TABLE dbo.AplicacionPago(ReciboId bigint NOT NULL REFERENCES dbo.ReciboMultiple(Id), CargoId bigint NOT NULL REFERENCES dbo.CargoEstudiante(Id), Importe decimal(18,2) NOT NULL CHECK(Importe>0), DescripcionHistorica nvarchar(200) NOT NULL, PRIMARY KEY(ReciboId,CargoId));
COMMIT;
END TRY
BEGIN CATCH
IF XACT_STATE()<>0 ROLLBACK;
THROW;
END CATCH;');

-- Confirmación 004_RevisionProfesor.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 004_RevisionProfesor.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''004_RevisionProfesor.sql'',''650e6c5215ef542b2564a5f0ed73bf137b2fcb48ee36c30a4c55f404ccc65737'');');

-- 005_ExpedienteVersionado.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'005_ExpedienteVersionado.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' THROW 52100,N''Base incorrecta.'',1;
IF OBJECT_ID(''dbo.ExpedienteAmpliado'',''U'') IS NULL
 THROW 52101,N''Instale 004 primero.'',1;
IF @@TRANCOUNT<>0
 THROW 52102,N''Use una ventana sin transacciones abiertas.'',1;

BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Estudiantes ALTER COLUMN Telefono nvarchar(30) NOT NULL;
 ALTER TABLE dbo.Estudiantes ALTER COLUMN NombreTutor nvarchar(200) NOT NULL;

 IF COL_LENGTH(''dbo.ExpedienteAmpliado'',''FormularioJson'') IS NULL
  EXEC sys.sp_executesql
   N''ALTER TABLE dbo.ExpedienteAmpliado ADD FormularioJson nvarchar(max) NULL;'';

 -- Compilar esta restricción después de crear la columna.
 IF NOT EXISTS(
  SELECT 1 FROM sys.check_constraints
  WHERE name=''CK_Expediente_FormularioJson''
    AND parent_object_id=OBJECT_ID(''dbo.ExpedienteAmpliado''))
  EXEC sys.sp_executesql
   N''ALTER TABLE dbo.ExpedienteAmpliado
     ADD CONSTRAINT CK_Expediente_FormularioJson
     CHECK(FormularioJson IS NULL OR ISJSON(FormularioJson)=1);'';

 IF NOT EXISTS(
  SELECT 1 FROM sys.indexes
  WHERE name=''UQ_Responsable_Vigente''
    AND object_id=OBJECT_ID(''dbo.ResponsableEstudiante''))
  CREATE UNIQUE INDEX UQ_Responsable_Vigente
   ON dbo.ResponsableEstudiante(Registro,Vinculo) WHERE Hasta IS NULL;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 005_ExpedienteVersionado.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 005_ExpedienteVersionado.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''005_ExpedienteVersionado.sql'',''099fd1c10225164b20659f209ffff14a4a253362cbff0b62d73d05759223b3e8'');');

-- 006_Calificaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'006_Calificaciones.sql · lote 1',N'-- Ejecutar una vez después de 004 y 005, en desarrollo.
SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' THROW 52400,N''Base incorrecta.'',1;
IF OBJECT_ID(''dbo.Evaluacion'') IS NULL THROW 52400,N''Instale la migración 004 primero.'',1;
IF COL_LENGTH(''dbo.Evaluacion'',''Modo'') IS NOT NULL THROW 52400,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Evaluacion ADD Modo nvarchar(20) NOT NULL CONSTRAINT DF_Evaluacion_Modo DEFAULT N''Cuantitativa'';
 -- La restricción de Peso fue creada sin nombre en 004; localizarla por columna.
 DECLARE @Nombre sysname,@Sql nvarchar(max);
 SELECT @Nombre=name FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(''dbo.Evaluacion'') AND parent_column_id=COLUMNPROPERTY(OBJECT_ID(''dbo.Evaluacion''),''Peso'',''ColumnId'');
 IF @Nombre IS NULL THROW 52400,N''No se encontró la restricción original de Peso; revisar el esquema.'',1;
 SET @Sql=N''ALTER TABLE dbo.Evaluacion DROP CONSTRAINT ''+QUOTENAME(@Nombre);EXEC sp_executesql @Sql;
 EXEC(N''ALTER TABLE dbo.Evaluacion ADD CONSTRAINT CK_Evaluacion_ModoPeso CHECK ((Modo=N''''Cuantitativa'''' AND Peso>0 AND Peso<=100) OR (Modo=N''''Cualitativa'''' AND Peso=0));'');
 ALTER TABLE dbo.Calificacion ADD Resultado nvarchar(100) NULL;
 EXEC(N''ALTER TABLE dbo.Calificacion ADD CONSTRAINT CK_Calificacion_UnResultado CHECK (Nota IS NULL OR Resultado IS NULL);'');
 CREATE TABLE dbo.OpcionEvaluacion(EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),Valor nvarchar(100) NOT NULL,PRIMARY KEY(EvaluacionId,Valor));
 CREATE TABLE dbo.PublicacionNotas(AsignacionId int PRIMARY KEY REFERENCES dbo.AsignacionDocente(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id));
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 006_Calificaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 006_Calificaciones.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''006_Calificaciones.sql'',''93304ffa127bbe7d2aed5c166401bc2467343012bbe15ee20c98533ba0f8e552'');');

-- 007_HistorialCierreAcademico.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'007_HistorialCierreAcademico.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' THROW 52600,N''Base incorrecta.'',1;
IF OBJECT_ID(''dbo.PublicacionNotas'') IS NULL THROW 52600,N''Instale 006 primero.'',1;
IF OBJECT_ID(''dbo.HistorialCalificacion'') IS NOT NULL THROW 52600,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.PublicacionNotas ADD Vigente bit NOT NULL CONSTRAINT DF_Publicacion_Vigente DEFAULT 1,Version rowversion;
 ALTER TABLE dbo.PeriodoAcademico ADD Version rowversion;
 CREATE TABLE dbo.HistorialCalificacion(
  Id bigint IDENTITY PRIMARY KEY,EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
  NotaAnterior decimal(7,2) NULL,NotaNueva decimal(7,2) NULL,ResultadoAnterior nvarchar(100) NULL,ResultadoNuevo nvarchar(100) NULL,
  ObservacionAnterior nvarchar(500) NULL,ObservacionNueva nvarchar(500) NULL,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Motivo nvarchar(500) NOT NULL
 );
 CREATE INDEX IX_HistorialCalificacion_Evaluacion ON dbo.HistorialCalificacion(EvaluacionId,Id);
 CREATE TABLE dbo.EventoAcademico(
  Id bigint IDENTITY PRIMARY KEY,PeriodoId int NOT NULL REFERENCES dbo.PeriodoAcademico(Id),AsignacionId int NULL REFERENCES dbo.AsignacionDocente(Id),
  Accion nvarchar(30) NOT NULL CHECK(Accion IN (''Publicar'',''ReabrirAsignacion'',''CerrarPeriodo'',''ReabrirPeriodo'')),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Motivo nvarchar(500) NOT NULL,
  Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1)
 );
 CREATE INDEX IX_EventoAcademico_Periodo ON dbo.EventoAcademico(PeriodoId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 007_HistorialCierreAcademico.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 007_HistorialCierreAcademico.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''007_HistorialCierreAcademico.sql'',''9c4e221b663c4c711a1ad2d9fa89067c09667934df74496abee058733ed79908'');');

-- 008_CatalogoFinanciero.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'008_CatalogoFinanciero.sql · lote 1',N'-- Después de 004–007. No transforma pagos ni activa el nuevo libro.
SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' THROW 52800,N''Base incorrecta.'',1;
IF OBJECT_ID(''dbo.TarifaArancel'',''U'') IS NULL THROW 52800,N''Falta la estructura de 004.'',1;
IF OBJECT_ID(''dbo.HistorialTarifa'',''U'') IS NOT NULL THROW 52800,N''Migración ya instalada.'',1;
IF @@TRANCOUNT<>0 THROW 52800,N''Use una ventana sin transacciones abiertas.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Arancel ADD Version rowversion;
 ALTER TABLE dbo.TarifaArancel ADD Activo bit NOT NULL CONSTRAINT DF_Tarifa_Activo DEFAULT 1,Version rowversion;
 CREATE TABLE dbo.HistorialTarifa(
  Id bigint IDENTITY PRIMARY KEY,TarifaId int NOT NULL REFERENCES dbo.TarifaArancel(Id),
  ImporteAnterior decimal(18,2) NULL,ImporteNuevo decimal(18,2) NOT NULL,
  ActivoAnterior bit NULL,ActivoNuevo bit NOT NULL,Motivo nvarchar(500) NOT NULL,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 CREATE TABLE dbo.MapaConceptoLegado(
  Origen nvarchar(30) PRIMARY KEY CHECK(Origen IN (''Matriculas'',''Mensualidades'',''Mantenimientos'',''EvBoTaS'',''Promociones'')),
  ArancelId int NOT NULL REFERENCES dbo.Arancel(Id),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 -- Una fila por obligación original. Es preparación, no un cargo cobrable.
 CREATE TABLE dbo.PreparacionObligacion(
  Origen nvarchar(30) NOT NULL REFERENCES dbo.MapaConceptoLegado(Origen),OrigenId int NOT NULL,
  Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),Anio int NOT NULL,
  Modalidad nvarchar(20) NOT NULL,Importe decimal(18,2) NOT NULL,Estado nvarchar(10) NOT NULL,
  Comprobante nvarchar(25) NULL,ArancelId int NOT NULL REFERENCES dbo.Arancel(Id),
  Capturado datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),
  PRIMARY KEY(Origen,OrigenId));
 CREATE UNIQUE INDEX UQ_Preparacion_Cargo ON dbo.PreparacionObligacion(CargoId) WHERE CargoId IS NOT NULL;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 008_CatalogoFinanciero.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 008_CatalogoFinanciero.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''008_CatalogoFinanciero.sql'',''b7a2d955321c2a1ab34a4437db17e9d7d90744966c6b4a59d1474a2b97585fa7'');');

-- 009_RevisionObligaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'009_RevisionObligaciones.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' THROW 53000,N''Base incorrecta.'',1;
IF OBJECT_ID(''dbo.PreparacionObligacion'',''U'') IS NULL THROW 53000,N''Instale 008 primero.'',1;
IF OBJECT_ID(''dbo.RevisionObligacion'',''U'') IS NOT NULL THROW 53000,N''Migración ya instalada.'',1;
IF @@TRANCOUNT<>0 THROW 53000,N''Use una ventana sin transacciones abiertas.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.RevisionObligacion(
  Id bigint IDENTITY PRIMARY KEY,
  Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,
  TarifaId int NOT NULL REFERENCES dbo.TarifaArancel(Id),
  Decision nvarchar(20) NOT NULL CHECK(Decision IN (''Deuda'',''SinDeuda'',''Rechazada'')),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo)))>0),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
  Registro nvarchar(10) NOT NULL,Anio int NOT NULL,Modalidad nvarchar(20) NOT NULL,
  Importe decimal(18,2) NOT NULL,Estado nvarchar(10) NOT NULL,Comprobante nvarchar(25) NULL,
  FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 CREATE INDEX IX_RevisionObligacion_Origen ON dbo.RevisionObligacion(Origen,OrigenId,Id DESC);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 009_RevisionObligaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 009_RevisionObligaciones.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''009_RevisionObligaciones.sql'',''b4ad4c5d161f736c848a7dd474fc04f7bb818ee34efc4313fec98715652914e5'');');

-- 010_RecapturaObligaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'010_RecapturaObligaciones.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53100,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.RevisionObligacion'',''U'') IS NULL THROW 53100,N''Instale 009 primero.'',1;
IF COL_LENGTH(''dbo.PreparacionObligacion'',''Generacion'') IS NOT NULL THROW 53100,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.PreparacionObligacion ADD Generacion int NOT NULL CONSTRAINT DF_Preparacion_Generacion DEFAULT 1;
 ALTER TABLE dbo.RevisionObligacion ADD Generacion int NOT NULL CONSTRAINT DF_Revision_Generacion DEFAULT 1;
 CREATE TABLE dbo.HistorialCaptura(
 Id bigint IDENTITY PRIMARY KEY,Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,
 GeneracionAnterior int NOT NULL,GeneracionNueva int NOT NULL,
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),
 DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1),
 Motivo nvarchar(500) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
 Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 010_RecapturaObligaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 010_RecapturaObligaciones.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''010_RecapturaObligaciones.sql'',''f207eca680da0b37cbf8343e4c649cb58d91b2e3ffc5e1ec4e35639a2532f3ee'');');

-- 011_RevisionSaldo.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'011_RevisionSaldo.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53200,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.HistorialCaptura'',''U'') IS NULL THROW 53200,N''Instale 010 primero.'',1;
IF OBJECT_ID(''dbo.RevisionSaldo'',''U'') IS NOT NULL THROW 53200,N''Migración ya instalada.'',1;
CREATE TABLE dbo.RevisionSaldo(
 Id bigint IDENTITY PRIMARY KEY,Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 SaldoObservado decimal(18,2) NOT NULL,FilasSaldo int NOT NULL,
 Huella binary(32) NOT NULL,Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1),
 Decision nvarchar(20) NOT NULL CHECK(Decision IN (''Aprobado'',''Rechazado'')),
 Referencia nvarchar(200) NOT NULL,Motivo nvarchar(500) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
CREATE INDEX IX_RevisionSaldo_Registro ON dbo.RevisionSaldo(Registro,Id DESC);');

-- Confirmación 011_RevisionSaldo.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 011_RevisionSaldo.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''011_RevisionSaldo.sql'',''0d9ca93699230dc3f0da1deb053170d8fe65b33675145ec5fda0013582e93ced'');');

-- 012_CorteFinanciero.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'012_CorteFinanciero.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53400,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.RevisionSaldo'',''U'') IS NULL THROW 53400,N''Instale 011 primero.'',1;
IF OBJECT_ID(''dbo.ControlFinanciero'',''U'') IS NOT NULL THROW 53400,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.ControlFinanciero(Id int PRIMARY KEY CHECK(Id=1),Migrado bit NOT NULL DEFAULT 0,Operacion uniqueidentifier NULL,Fecha datetime2 NULL,UsuarioId nvarchar(450) NULL REFERENCES dbo.AspNetUsers(Id));
 INSERT dbo.ControlFinanciero(Id) VALUES(1);
 -- Desconocido no se convierte en fecha de mora inventada.
 ALTER TABLE dbo.CargoEstudiante ALTER COLUMN Vencimiento date NULL;
 CREATE TABLE dbo.SaldoFinanciero(Registro nvarchar(10) PRIMARY KEY REFERENCES dbo.Estudiantes(Registro),RevisionSaldoId bigint NOT NULL UNIQUE REFERENCES dbo.RevisionSaldo(Id),SaldoInicial decimal(18,2) NOT NULL CHECK(SaldoInicial>=0),Disponible decimal(18,2) NOT NULL CHECK(Disponible>=0),Version rowversion);
 CREATE TABLE dbo.ObligacionMigrada(Origen nvarchar(30) NOT NULL,OrigenId int NOT NULL,RevisionId bigint NOT NULL UNIQUE REFERENCES dbo.RevisionObligacion(Id),CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),PRIMARY KEY(Origen,OrigenId),FOREIGN KEY(Origen,OrigenId) REFERENCES dbo.PreparacionObligacion(Origen,OrigenId));
 CREATE UNIQUE INDEX UQ_ObligacionMigrada_Cargo ON dbo.ObligacionMigrada(CargoId) WHERE CargoId IS NOT NULL;
 -- Triggers de transición: permanecen inactivos hasta confirmar el corte.
 DECLARE @Tabla sysname,@Sql nvarchar(max);
 DECLARE Tablas CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM (VALUES
 (''Pagos''),(''Abonos''),(''Matriculas''),(''Mensualidades''),(''Mantenimientos''),(''EvBoTaS''),(''Promociones''),(''Arreglos_Pago''),(''Historial_Comprobantes''),
 (''Costo_Matricula''),(''Costo_Mensualidad''),(''Costo_Mantenimiento''),(''Costo_EvBoTa''),(''Costo_Promocion''),
 (''PreparacionObligacion''),(''RevisionObligacion''),(''RevisionSaldo''),(''MapaConceptoLegado''),(''HistorialCaptura'')) V(T);
 OPEN Tablas;FETCH NEXT FROM Tablas INTO @Tabla;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Sql=N''CREATE TRIGGER dbo.''+QUOTENAME(N''TR_Corte_''+@Tabla)+N'' ON dbo.''+QUOTENAME(@Tabla)+N'' AFTER INSERT,UPDATE,DELETE AS BEGIN SET NOCOUNT ON; IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WITH(READCOMMITTEDLOCK) WHERE Id=1 AND Migrado=1) THROW 53410,N''''El libro anterior está cerrado. No se permiten escrituras.'''',1; END;'';
  EXEC sys.sp_executesql @Sql;
  FETCH NEXT FROM Tablas INTO @Tabla;
 END;
 CLOSE Tablas;DEALLOCATE Tablas;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 012_CorteFinanciero.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 012_CorteFinanciero.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''012_CorteFinanciero.sql'',''fc923feb496ec703bcbb2d03daf16c420e4829dd2615a22b54171088f1e85d8b'');');

-- 013_RecibosMultiples.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'013_RecibosMultiples.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53500,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.SaldoFinanciero'',''U'') IS NULL THROW 53500,N''Instale 012 primero.'',1;
IF COL_LENGTH(''dbo.ReciboMultiple'',''SolicitudHash'') IS NOT NULL THROW 53500,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 -- No reinterpretar recibos existentes con reglas nuevas.
 IF EXISTS(SELECT 1 FROM dbo.ReciboMultiple WITH(TABLOCKX,HOLDLOCK)) THROW 53500,N''Existen recibos: requiere conciliación antes de instalar.'',1;
 DECLARE @Sql nvarchar(max)=N'''';
 SELECT @Sql+=N''ALTER TABLE dbo.ReciboMultiple DROP CONSTRAINT ''+QUOTENAME(name)+N'';'' FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(''dbo.ReciboMultiple'');
 EXEC sys.sp_executesql @Sql;
 ALTER TABLE dbo.ReciboMultiple ADD SolicitudHash binary(32) NOT NULL,NombreEstudiante nvarchar(100) NOT NULL,SaldoAnterior decimal(18,2) NOT NULL,SaldoAplicado decimal(18,2) NOT NULL,SaldoFinal decimal(18,2) NOT NULL,TotalAplicado decimal(18,2) NOT NULL;
 -- SQL dinámico evita compilación anticipada de las columnas agregadas.
 EXEC sys.sp_executesql N''ALTER TABLE dbo.ReciboMultiple ADD CONSTRAINT CK_ReciboMultiple_Balance CHECK (
 Metodo IN (N''''Efectivo'''',N''''Transferencia'''',N''''Saldo'''') AND Recibido>=0 AND Cambio>=0 AND Cambio<=Recibido AND
 SaldoAnterior>=0 AND SaldoAplicado>=0 AND SaldoAplicado<=SaldoAnterior AND SaldoFinal=SaldoAnterior-SaldoAplicado AND
 TotalAplicado>0 AND Recibido+SaldoAplicado=TotalAplicado+Cambio AND
 (Metodo<>N''''Transferencia'''' OR (NULLIF(LTRIM(RTRIM(Referencia)),N'''''''') IS NOT NULL AND Cambio=0 AND Recibido>0)) AND
 (Metodo<>N''''Saldo'''' OR (Recibido=0 AND Cambio=0)) AND (Metodo<>N''''Efectivo'''' OR Recibido>0));'';
 CREATE INDEX IX_AplicacionPago_Cargo ON dbo.AplicacionPago(CargoId) INCLUDE(Importe);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 013_RecibosMultiples.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 013_RecibosMultiples.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''013_RecibosMultiples.sql'',''d84cbb26e8b4cb55a895bef656ab4c08695538b7437262f4b0ca91c9591be9fc'');');

-- 014_GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'014_GeneracionCargos.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53600,N''Use desarrollo sin transacciones abiertas.'',1;
IF COL_LENGTH(''dbo.ReciboMultiple'',''SolicitudHash'') IS NULL THROW 53600,N''Instale 013 primero.'',1;
IF OBJECT_ID(''dbo.ConfiguracionCargo'',''U'') IS NOT NULL THROW 53600,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.ConfiguracionCargo(ArancelId int PRIMARY KEY REFERENCES dbo.Arancel(Id),Periodicidad nvarchar(10) NOT NULL CHECK(Periodicidad IN (''Anual'',''Mensual'',''Eventual'')));
 -- Solo inferir periodicidad cuando todos los mapeos heredados coinciden.
 INSERT dbo.ConfiguracionCargo(ArancelId,Periodicidad)
 SELECT ArancelId,MIN(CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END)
 FROM dbo.MapaConceptoLegado GROUP BY ArancelId
 HAVING MIN(CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END)=MAX(CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END);
 CREATE TABLE dbo.GeneracionCargo(Operacion uniqueidentifier PRIMARY KEY,CargoId bigint NOT NULL UNIQUE REFERENCES dbo.CargoEstudiante(Id),SolicitudHash binary(32) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 014_GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 014_GeneracionCargos.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''014_GeneracionCargos.sql'',''068e7b1dec2500073dc8463a33f1eab72f63b5b9b32d1e310c0a2947450416ec'');');

-- 015_AnulacionRecibos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'015_AnulacionRecibos.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53700,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.GeneracionCargo'',''U'') IS NULL THROW 53700,N''Instale 014 primero.'',1;
IF OBJECT_ID(''dbo.AnulacionRecibo'',''U'') IS NOT NULL THROW 53700,N''Migración ya instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.AnulacionRecibo(
 Id bigint IDENTITY PRIMARY KEY,ReciboId bigint NOT NULL UNIQUE REFERENCES dbo.ReciboMultiple(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL,ReferenciaDevolucion nvarchar(100) NOT NULL,Receptor nvarchar(200) NOT NULL,
 DineroDevuelto decimal(18,2) NOT NULL CHECK(DineroDevuelto>=0),SaldoRestituido decimal(18,2) NOT NULL CHECK(SaldoRestituido>=0),
 SaldoAnterior decimal(18,2) NOT NULL CHECK(SaldoAnterior>=0),SaldoFinal decimal(18,2) NOT NULL,
 TotalRevertido decimal(18,2) NOT NULL CHECK(TotalRevertido>0),CONSTRAINT CK_AnulacionRecibo_Total CHECK(TotalRevertido=DineroDevuelto+SaldoRestituido),
 CONSTRAINT CK_AnulacionRecibo_Saldo CHECK(SaldoFinal=SaldoAnterior+SaldoRestituido));
 -- Crear la vista en la misma transacción, una vez creada la tabla.
 EXEC sys.sp_executesql N''CREATE OR ALTER VIEW dbo.AplicacionPagoVigente
 AS SELECT A.ReciboId,A.CargoId,A.Importe,A.DescripcionHistorica FROM dbo.AplicacionPago A
 WHERE NOT EXISTS(SELECT 1 FROM dbo.AnulacionRecibo R WHERE R.ReciboId=A.ReciboId);'';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 015_AnulacionRecibos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 015_AnulacionRecibos.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''015_AnulacionRecibos.sql'',''e10d4493f2b503bdbd6d281d4e43db4c1d14c57e93823172fc3d295691521043'');');

-- 016_MatriculaAcademica.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'016_MatriculaAcademica.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53800,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.AnulacionRecibo'',''U'') IS NULL THROW 53800,N''Instale 015 primero.'',1;
IF OBJECT_ID(''dbo.MatriculaAcademica'',''U'') IS NOT NULL THROW 53800,N''Migración ya instalada.'',1;
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE dbo.ConfiguracionMatricula(Id int PRIMARY KEY CHECK(Id=1),ArancelId int NOT NULL UNIQUE REFERENCES dbo.Arancel(Id));
INSERT dbo.ConfiguracionMatricula(Id,ArancelId) SELECT 1,ArancelId FROM dbo.MapaConceptoLegado WHERE Origen=''Matriculas'';
CREATE TABLE dbo.MatriculaAcademica(
 Id bigint IDENTITY PRIMARY KEY,Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 Anio int NOT NULL,Modalidad nvarchar(80) NOT NULL,Nivel nvarchar(50) NOT NULL,
 CargoId bigint NULL REFERENCES dbo.CargoEstudiante(Id),MatriculaLegadaId int NULL REFERENCES dbo.Matriculas(Id),
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_MatriculaAcademica_Anio UNIQUE(Registro,Anio),
 CONSTRAINT CK_MatriculaAcademica_Origen CHECK((CargoId IS NOT NULL AND MatriculaLegadaId IS NULL) OR (CargoId IS NULL AND MatriculaLegadaId IS NOT NULL)));

COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 016_MatriculaAcademica.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 016_MatriculaAcademica.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''016_MatriculaAcademica.sql'',''c20af287c77a5d7613cdbd9a751a958ce5f24ed8edfa156e4afe0daff09ece9a'');');

-- 017_LoteMensualidades.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'017_LoteMensualidades.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53900,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.MatriculaAcademica'',''U'') IS NULL THROW 53900,N''Instale 016 primero.'',1;
IF OBJECT_ID(''dbo.LoteMensualidades'',''U'') IS NOT NULL THROW 53900,N''Migración ya instalada.'',1;
CREATE TABLE dbo.LoteMensualidades(Operacion uniqueidentifier PRIMARY KEY,SolicitudHash binary(32) NOT NULL,UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),Cantidad int NOT NULL CHECK(Cantidad BETWEEN 1 AND 12),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME());');

-- Confirmación 017_LoteMensualidades.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 017_LoteMensualidades.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''017_LoteMensualidades.sql'',''10f6b2b0e19664daf5376a2d5f8a8d936bdafbecb6f2ff57997d0e48b07c11f9'');');

-- 018_CancelacionHorarios.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'018_CancelacionHorarios.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 54200,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.HorarioClase'',''U'') IS NULL OR OBJECT_ID(''dbo.LoteMensualidades'',''U'') IS NULL THROW 54200,N''Complete las migraciones anteriores hasta 017.'',1;
IF OBJECT_ID(''dbo.CancelacionHorario'',''U'') IS NOT NULL OR COL_LENGTH(''dbo.HorarioClase'',''Version'') IS NOT NULL THROW 54200,N''Etapa 018 instalada o parcial. Revise antes de repetir.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.HorarioClase ADD Version rowversion;
 CREATE TABLE dbo.CancelacionHorario(
  HorarioId int NOT NULL CONSTRAINT PK_CancelacionHorario PRIMARY KEY REFERENCES dbo.HorarioClase(Id),
  Operacion uniqueidentifier NOT NULL CONSTRAINT UQ_CancelacionHorario_Operacion UNIQUE,
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),VersionHorario binary(8) NOT NULL,
  Instantanea nvarchar(max) NOT NULL CHECK(ISJSON(Instantanea)=1)
 );
 EXEC sys.sp_executesql N''CREATE OR ALTER VIEW dbo.HorarioClaseVigente AS
 SELECT H.Id,H.AsignacionId,H.Dia,H.Inicio,H.Fin,H.Version FROM dbo.HorarioClase H
 WHERE NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario C WHERE C.HorarioId=H.Id);'';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 018_CancelacionHorarios.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 018_CancelacionHorarios.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''018_CancelacionHorarios.sql'',''906e04f4bcd77a4cbc97e2007cd013786fae8d898d6eb4759a678b64b4c9c917'');');

-- 019_CambiosPlanificacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'019_CambiosPlanificacion.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>N''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 54300,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.CancelacionHorario'',''U'') IS NULL THROW 54300,N''Instale 018 primero.'',1;
IF OBJECT_ID(''dbo.CambioPlanificacion'',''U'') IS NOT NULL OR COL_LENGTH(''dbo.AsignacionDocente'',''Version'') IS NOT NULL OR COL_LENGTH(''dbo.GrupoEstudiante'',''Version'') IS NOT NULL THROW 54300,N''Etapa 019 instalada o parcial. Revise antes de repetir.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.AsignacionDocente ADD Version rowversion;
 ALTER TABLE dbo.GrupoEstudiante ADD Version rowversion;
 CREATE TABLE dbo.CambioPlanificacion(
 Id bigint IDENTITY PRIMARY KEY,Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 Tipo nvarchar(20) NOT NULL CHECK(Tipo IN (''Docente'',''Estudiante'')),OrigenId int NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1)
 );
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 019_CambiosPlanificacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 019_CambiosPlanificacion.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''019_CambiosPlanificacion.sql'',''f7be2b95656eee82bf15f95fb465665b1156f3ea0efef79a3a77fe076191ac76'');');

-- 020_EdicionEvaluaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'020_EdicionEvaluaciones.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 54400,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.CambioPlanificacion'',''U'') IS NULL THROW 54400,N''Instale 019 primero.'',1;
IF COL_LENGTH(''dbo.Evaluacion'',''Version'') IS NOT NULL OR OBJECT_ID(''dbo.HistorialEvaluacion'',''U'') IS NOT NULL THROW 54400,N''Etapa 020 instalada o parcial. Revise antes de repetir.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.Evaluacion ADD Version rowversion;
 CREATE TABLE dbo.HistorialEvaluacion(
 Id bigint IDENTITY PRIMARY KEY,EvaluacionId int NOT NULL REFERENCES dbo.Evaluacion(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1));
 CREATE INDEX IX_HistorialEvaluacion_Evaluacion ON dbo.HistorialEvaluacion(EvaluacionId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 020_EdicionEvaluaciones.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 020_EdicionEvaluaciones.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''020_EdicionEvaluaciones.sql'',''a7208d480228f768bf960593694f3d21c19eaa7c0d20dd530589164968ecdb92'');');

-- 021_AdministracionPersonal.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'021_AdministracionPersonal.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 54500,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.HistorialEvaluacion'',''U'') IS NULL THROW 54500,N''Instale 020 primero.'',1;
IF OBJECT_ID(''dbo.EstadoCuentaPersonal'',''U'') IS NOT NULL OR OBJECT_ID(''dbo.HistorialCuentaPersonal'',''U'') IS NOT NULL THROW 54500,N''Etapa 021 instalada o parcial. Revise antes de repetir.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 CREATE TABLE dbo.EstadoCuentaPersonal(
  UsuarioId nvarchar(450) NOT NULL PRIMARY KEY REFERENCES dbo.AspNetUsers(Id),
  Activa bit NOT NULL);
 CREATE TABLE dbo.HistorialCuentaPersonal(
  Id bigint IDENTITY PRIMARY KEY, CuentaId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
  Operacion uniqueidentifier NOT NULL UNIQUE, SolicitudHash binary(32) NOT NULL,
  Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
  Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
  AntesJson nvarchar(max) NOT NULL CHECK(ISJSON(AntesJson)=1),
  DespuesJson nvarchar(max) NOT NULL CHECK(ISJSON(DespuesJson)=1));
 CREATE INDEX IX_HistorialCuentaPersonal_Cuenta ON dbo.HistorialCuentaPersonal(CuentaId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 021_AdministracionPersonal.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 021_AdministracionPersonal.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''021_AdministracionPersonal.sql'',''2714de7bc56c9e3592e15d7989cce5759b1f093d68b1da2f262196dc181f8d14'');');

-- 022_TiposEvaluacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'022_TiposEvaluacion.sql · lote 1',N'SET XACT_ABORT ON;
IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 54600,N''Use desarrollo sin transacciones abiertas.'',1;
IF OBJECT_ID(''dbo.EstadoCuentaPersonal'',''U'') IS NULL THROW 54600,N''Instale 021 primero.'',1;
IF COL_LENGTH(''dbo.TipoEvaluacion'',''Version'') IS NOT NULL OR OBJECT_ID(''dbo.HistorialTipoEvaluacion'',''U'') IS NOT NULL
 THROW 54600,N''Etapa 022 instalada o parcial. Revise antes de repetir.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 ALTER TABLE dbo.TipoEvaluacion ADD Version rowversion;
 CREATE TABLE dbo.HistorialTipoEvaluacion(
 Id bigint IDENTITY PRIMARY KEY,TipoId int NOT NULL REFERENCES dbo.TipoEvaluacion(Id),
 Operacion uniqueidentifier NOT NULL UNIQUE,SolicitudHash binary(32) NOT NULL,
 UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id),
 Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Motivo nvarchar(500) NOT NULL CHECK(LEN(LTRIM(RTRIM(Motivo))) BETWEEN 10 AND 500),
 NombreAnterior nvarchar(100) NOT NULL,NombreNuevo nvarchar(100) NOT NULL,
 ActivoAnterior bit NOT NULL,ActivoNuevo bit NOT NULL);
 CREATE INDEX IX_HistorialTipoEvaluacion_Tipo ON dbo.HistorialTipoEvaluacion(TipoId,Id);
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 022_TiposEvaluacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 022_TiposEvaluacion.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''022_TiposEvaluacion.sql'',''770b0d49de2b7aad90759a1c660ca7a863f9afb1c1088737288a0b6a9fd75512'');');

-- 023_Anticipos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'023_Anticipos.sql · lote 1',N'SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54700,N''Cierra las transacciones antes de instalar 023.'',1;
IF OBJECT_ID(''dbo.AnulacionRecibo'',''U'') IS NULL OR COL_LENGTH(''dbo.ReciboMultiple'',''TotalAplicado'') IS NULL
 THROW 54700,N''Instala primero las etapas de recibos y anulaciones.'',1;
IF COL_LENGTH(''dbo.ReciboMultiple'',''Anticipo'') IS NOT NULL
 THROW 54700,N''La migración 023 ya está instalada.'',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Uq sysname=(SELECT kc.name FROM sys.key_constraints kc
  JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id AND ic.key_ordinal=1
  JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
  WHERE kc.parent_object_id=OBJECT_ID(''dbo.SaldoFinanciero'') AND kc.type=''UQ'' AND c.name=''RevisionSaldoId'');
 IF @Uq IS NULL THROW 54700,N''No se encontró la restricción de revisión de saldo.'',1;
 DECLARE @Sql nvarchar(max)=N''ALTER TABLE dbo.SaldoFinanciero DROP CONSTRAINT ''+QUOTENAME(@Uq);
 EXEC sys.sp_executesql @Sql;
 ALTER TABLE dbo.SaldoFinanciero ALTER COLUMN RevisionSaldoId bigint NULL;
 CREATE UNIQUE INDEX UX_SaldoFinanciero_RevisionSaldo ON dbo.SaldoFinanciero(RevisionSaldoId) WHERE RevisionSaldoId IS NOT NULL;

 ALTER TABLE dbo.ReciboMultiple ADD Anticipo decimal(18,2) NOT NULL CONSTRAINT DF_ReciboMultiple_Anticipo DEFAULT 0 WITH VALUES;
 ALTER TABLE dbo.ReciboMultiple DROP CONSTRAINT CK_ReciboMultiple_Balance;
 EXEC sys.sp_executesql N''ALTER TABLE dbo.ReciboMultiple ADD CONSTRAINT CK_ReciboMultiple_Balance CHECK (
 Metodo IN (N''''Efectivo'''',N''''Transferencia'''',N''''Saldo'''') AND Recibido>=0 AND Cambio>=0 AND Cambio<=Recibido AND
 SaldoAnterior>=0 AND SaldoAplicado>=0 AND SaldoAplicado<=SaldoAnterior AND SaldoFinal=SaldoAnterior-SaldoAplicado+Anticipo AND
 Anticipo>=0 AND ((Anticipo=0 AND TotalAplicado>0) OR
 (Anticipo>0 AND TotalAplicado=0 AND Cambio=0 AND SaldoAplicado=0 AND Metodo<>N''''Saldo'''')) AND
 Recibido+SaldoAplicado=TotalAplicado+Cambio+Anticipo AND
 (Metodo<>N''''Transferencia'''' OR (NULLIF(LTRIM(RTRIM(Referencia)),N'''''''') IS NOT NULL AND Cambio=0 AND Recibido>0)) AND
 (Metodo<>N''''Saldo'''' OR (Recibido=0 AND Cambio=0)) AND (Metodo<>N''''Efectivo'''' OR Recibido>0));'';

 ALTER TABLE dbo.AnulacionRecibo ADD SaldoRetirado decimal(18,2) NOT NULL CONSTRAINT DF_AnulacionRecibo_SaldoRetirado DEFAULT 0 WITH VALUES;
 ALTER TABLE dbo.AnulacionRecibo DROP CONSTRAINT CK_AnulacionRecibo_Saldo;
 EXEC sys.sp_executesql N''ALTER TABLE dbo.AnulacionRecibo ADD CONSTRAINT CK_AnulacionRecibo_Saldo CHECK (
 SaldoRetirado>=0 AND SaldoRetirado<=SaldoAnterior AND SaldoFinal=SaldoAnterior+SaldoRestituido-SaldoRetirado);'';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;');

-- Confirmación 023_Anticipos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Confirmación 023_Anticipos.sql · lote 1',N'INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N''023_Anticipos.sql'',''18646c17685e18d07ef5374b63df5cd771cb9b14a0228861d97dd221fa145031'');');

-- PROCEDURE dbo.Buscar_Estudiantes_Mensualidad · Mensualidades_Legado.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Buscar_Estudiantes_Mensualidad · Mensualidades_Legado.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Buscar_Estudiantes_Mensualidad @TextoBusqueda nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (4) Registro,NombreEstudiante,Grado
    FROM dbo.Estudiantes
    WHERE Estado=N''Activo'' AND LEN(TRIM(@TextoBusqueda))>=2
      AND (CHARINDEX(TRIM(@TextoBusqueda),NombreEstudiante COLLATE Latin1_General_100_CI_AI)>0 OR Registro=TRIM(@TextoBusqueda))
    ORDER BY NombreEstudiante,Registro;
END;');

-- PROCEDURE dbo.Cargos_Autorizar · GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_Autorizar · GeneracionCargos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53601,N''Solo administración puede generar cargos.'',1;
END;');

-- PROCEDURE dbo.CierreAcademico_Consultar · CierreAcademico.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CierreAcademico_Consultar · CierreAcademico.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CierreAcademico_Consultar @UsuarioId nvarchar(450),@PeriodoId int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52601,N''Solo administración puede consultar este historial.'',1;
 SELECT P.Id,CONCAT(A.Anio,'' / '',P.Nombre) Etiqueta,P.Cerrado,CONVERT(varchar(18),CONVERT(binary(8),P.Version),1) Version FROM dbo.PeriodoAcademico P JOIN dbo.AnioLectivo A ON A.Id=P.AnioId ORDER BY A.Anio DESC,P.Inicio;
 SELECT A.Id,CONCAT(P.Nivel,'' '',G.Seccion,'' / '',S.Nombre) Etiqueta,ISNULL(N.Vigente,0) Publicado,CONVERT(varchar(18),CONVERT(binary(8),N.Version),1) Version
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.Asignatura S ON S.Id=A.AsignaturaId LEFT JOIN dbo.PublicacionNotas N ON N.AsignacionId=A.Id WHERE G.PeriodoId=@PeriodoId ORDER BY P.Nivel,G.Seccion,S.Nombre;
 SELECT TOP(200) H.Id,H.Fecha,E.Nombre Evaluacion,H.Registro,H.NotaAnterior,H.NotaNueva,H.ResultadoAnterior,H.ResultadoNuevo,H.ObservacionAnterior,H.ObservacionNueva,H.Motivo,U.UserName Responsable FROM dbo.HistorialCalificacion H JOIN dbo.Evaluacion E ON E.Id=H.EvaluacionId JOIN dbo.AsignacionDocente A ON A.Id=E.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId WHERE G.PeriodoId=@PeriodoId ORDER BY H.Id DESC;
 SELECT TOP(200) E.Id,E.Fecha,E.AsignacionId,E.Accion,E.Motivo,U.UserName Responsable FROM dbo.EventoAcademico E JOIN dbo.AspNetUsers U ON U.Id=E.UsuarioId WHERE E.PeriodoId=@PeriodoId ORDER BY E.Id DESC;
END;');

-- PROCEDURE dbo.Evaluacion_ConsultarEdicion · Evaluacion_ConsultarEdicion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Evaluacion_ConsultarEdicion · Evaluacion_ConsultarEdicion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Evaluacion_ConsultarEdicion @UsuarioId nvarchar(450),@EvaluacionId int,@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId
 WHERE E.Id=@EvaluacionId AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND (R.Name=''Administrador'' OR (R.Name=''Profesor'' AND D.UsuarioId=@UsuarioId)))) THROW 54401,N''Evaluación no disponible para tu cuenta.'',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54402,N''Página inválida.'',1;
 SELECT E.Id,E.AsignacionId,E.TipoId,E.Nombre,E.Fecha,E.Modo,E.Maximo,E.Peso,CONVERT(varchar(18),CONVERT(binary(8),E.Version),1) Version,
 CONVERT(bit,CASE WHEN P.Cerrado=1 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=E.AsignacionId)
 OR EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=E.Id) OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion WHERE EvaluacionId=E.Id) THEN 1 ELSE 0 END) Bloqueada
 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE E.Id=@EvaluacionId;
 SELECT T.Id,T.Nombre Etiqueta FROM dbo.TipoEvaluacion T WHERE T.Activo=1 ORDER BY T.Nombre;
 SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId ORDER BY Valor;
 SELECT H.Id,H.Fecha,H.Motivo,H.AntesJson,H.DespuesJson,U.UserName Responsable INTO #Historial FROM dbo.HistorialEvaluacion H LEFT JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId WHERE H.EvaluacionId=@EvaluacionId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT DATEADD(hour,-6,Fecha) FechaLocal,Motivo,AntesJson,DespuesJson,Responsable FROM #Historial ORDER BY Id DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;');

-- PROCEDURE dbo.Expediente_Obtener · Expediente.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Expediente_Obtener · Expediente.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Expediente_Obtener @Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Json nvarchar(max), @Version varchar(18);
 SELECT @Json=FormularioJson,@Version=CONVERT(varchar(18),CONVERT(binary(8),Version),1)
 FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro;
 IF @Json IS NOT NULL
 BEGIN
  SELECT JSON_MODIFY(JSON_MODIFY(@Json,''$.Registro'',@Registro),''$.Version'',@Version); RETURN;
 END;
 SELECT (SELECT E.Registro,E.NombreEstudiante,E.Modalidad,E.Grado,
 CONVERT(varchar(10),E.FechaNacimiento,23) FechaNacimiento,E.Sexo,E.Direccion,
 @Version Version,''Nuevo'' TipoIngreso,''Otro'' Tutor,''Ampliación de expediente existente'' Motivo,
 JSON_QUERY((SELECT E.NombreTutor Nombre,E.Telefono Telefono FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Otro
 FROM dbo.Estudiantes E WHERE E.Registro=@Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
END;');

-- PROCEDURE dbo.Finanzas_Autorizar · CobroMultiple.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Finanzas_Autorizar · CobroMultiple.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Finanzas_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name IN (''Administrador'',''Cajero'')) THROW 53501,N''Acceso financiero requerido.'',1;
END;');

-- PROCEDURE dbo.Horario_Consultar · Horario_Consultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Horario_Consultar · Horario_Consultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Horario_Consultar @UsuarioId nvarchar(450),@HorarioId int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54201,N''Se requiere administrador.'',1;
 SELECT H.Id,CONVERT(varchar(18),CONVERT(binary(8),H.Version),1) Version,Y.Anio,P.Nombre Periodo,P.Cerrado,G.Seccion,
 S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin,
 CONVERT(bit,CASE WHEN C.HorarioId IS NULL THEN 0 ELSE 1 END) Cancelado
 FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId
 JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId
 LEFT JOIN dbo.CancelacionHorario C ON C.HorarioId=H.Id WHERE H.Id=@HorarioId;
END;');

-- PROCEDURE dbo.Horario_Historial · Horario_Historial.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Horario_Historial · Horario_Historial.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Horario_Historial @UsuarioId nvarchar(450),@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54201,N''Se requiere administrador.'',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54202,N''Página inválida.'',1;
 -- Una consulta para el total y la página: conservar la misma instantánea.
 SELECT C.HorarioId,C.Fecha,C.Motivo,U.UserName Responsable,C.Instantanea INTO #Historial
 FROM dbo.CancelacionHorario C LEFT JOIN dbo.AspNetUsers U ON U.Id=C.UsuarioId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT HorarioId,DATEADD(hour,-6,Fecha) FechaLocal,Motivo,Responsable,
 JSON_VALUE(Instantanea,''$.Anio'') Anio,JSON_VALUE(Instantanea,''$.Periodo'') Periodo,
 JSON_VALUE(Instantanea,''$.Seccion'') Seccion,JSON_VALUE(Instantanea,''$.Asignatura'') Asignatura,
 JSON_VALUE(Instantanea,''$.Docente'') Docente,JSON_VALUE(Instantanea,''$.Aula'') Aula,
 JSON_VALUE(Instantanea,''$.Dia'') Dia,JSON_VALUE(Instantanea,''$.Inicio'') Inicio,JSON_VALUE(Instantanea,''$.Fin'') Fin
 FROM #Historial ORDER BY Fecha DESC,HorarioId DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;');

-- PROCEDURE dbo.Notas_Consultar · Notas.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Notas_Consultar · Notas.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Notas_Consultar @UsuarioId nvarchar(450),@AsignacionId int=0,@EvaluacionId int=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Admin bit=0,@Profesor bit=0;
 SELECT @Admin=MAX(CASE WHEN R.Name=''Administrador'' THEN 1 ELSE 0 END),@Profesor=MAX(CASE WHEN R.Name=''Profesor'' THEN 1 ELSE 0 END)
 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId;
 IF ISNULL(@Admin,0)=0 AND ISNULL(@Profesor,0)=0 THROW 52401,N''Acceso académico denegado.'',1;
 IF @AsignacionId<>0 AND NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE Id=@AsignacionId AND (@Admin=1 OR UsuarioId=@UsuarioId)) THROW 52401,N''Asignación no disponible para tu cuenta.'',1;
 IF @EvaluacionId<>0 AND NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE Id=@EvaluacionId AND AsignacionId=@AsignacionId) THROW 52401,N''Evaluación ajena a la asignación.'',1;
 SELECT A.Id,PS.AnioId,G.PensumId,A.GrupoId,CONCAT(Y.Anio,'' / '',P.Nombre,'' / '',PS.Nivel,'' '',G.Seccion,'' / '',S.Nombre) Etiqueta,P.Cerrado,
 CONVERT(bit,CASE WHEN PN.AsignacionId IS NULL THEN 0 ELSE 1 END) Publicado
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId
 JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.Pensum PS ON PS.Id=G.PensumId JOIN dbo.Asignatura S ON S.Id=A.AsignaturaId
 LEFT JOIN dbo.PublicacionNotas PN ON PN.AsignacionId=A.Id AND PN.Vigente=1 WHERE @Admin=1 OR A.UsuarioId=@UsuarioId ORDER BY Y.Anio DESC,P.Nombre,PS.Nivel,G.Seccion,S.Nombre;
 SELECT Id,Nombre Etiqueta FROM dbo.TipoEvaluacion WHERE Activo=1 ORDER BY Nombre;
 SELECT E.Id,E.Nombre,E.Fecha,T.Nombre Tipo,E.Modo,E.Maximo,E.Peso,CONVERT(varchar(18),CONVERT(binary(8),E.Version),1) Version FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.AsignacionId=@AsignacionId ORDER BY E.Fecha,E.Id;
 SELECT G.Registro,S.NombreEstudiante,C.Nota,C.Resultado,C.Observacion,CONVERT(varchar(18),CONVERT(binary(8),C.Version),1) Version
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoEstudiante G ON G.GrupoId=A.GrupoId
 JOIN dbo.Estudiantes S ON S.Registro=G.Registro LEFT JOIN dbo.Calificacion C ON C.Registro=G.Registro AND C.EvaluacionId=@EvaluacionId WHERE A.Id=@AsignacionId AND @EvaluacionId<>0 ORDER BY G.Registro;
 SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId ORDER BY Valor;
 -- Pendientes se muestran explícitamente; el acumulado parcial no es una nota final.
 SELECT G.Registro,S.NombreEstudiante,COUNT(E.Id) Evaluaciones,SUM(CASE WHEN E.Id IS NOT NULL AND ((E.Modo=''Cuantitativa'' AND C.Nota IS NULL) OR (E.Modo=''Cualitativa'' AND C.Resultado IS NULL)) THEN 1 ELSE 0 END) Pendientes,
 CAST(SUM(CASE WHEN E.Modo=''Cuantitativa'' THEN C.Nota/NULLIF(E.Maximo,0)*E.Peso END) AS decimal(7,2)) AcumuladoNumerico,
 SUM(CASE WHEN E.Modo=''Cuantitativa'' THEN E.Peso ELSE 0 END) PesoConfigurado
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoEstudiante G ON G.GrupoId=A.GrupoId JOIN dbo.Estudiantes S ON S.Registro=G.Registro LEFT JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id
 LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=G.Registro WHERE A.Id=@AsignacionId GROUP BY G.Registro,S.NombreEstudiante ORDER BY S.NombreEstudiante,G.Registro;
END;');

-- VIEW dbo.ObligacionLegada · Aranceles.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'VIEW dbo.ObligacionLegada · Aranceles.sql · lote 1',N'CREATE OR ALTER VIEW dbo.ObligacionLegada
AS
 SELECT N''Matriculas'' Origen,Id OrigenId,Registro_Estudiante Registro,Anio,Modalidad,Costo_Matricula Importe,CAST(N''Cancelado'' AS nvarchar(10)) Estado,Id_Comprobante Comprobante FROM dbo.Matriculas
 UNION ALL SELECT N''Mensualidades'',Id,Registro_Estudiante,Anio,Modalidad,Costo_Mensualidad,Estado,Id_Comprobante FROM dbo.Mensualidades
 UNION ALL SELECT N''Mantenimientos'',Id,Registro_Estudiante,Anio,Modalidad,Costo_Mantenimiento,Estado,Id_Comprobante FROM dbo.Mantenimientos
 UNION ALL SELECT N''EvBoTaS'',Id,Registro_Estudiante,Anio,Modalidad,Costo_EvBoTa,Estado,Id_Comprobante FROM dbo.EvBoTaS
 UNION ALL SELECT N''Promociones'',Id,Registro_Estudiante,Anio,Modalidad,Costo_Promocion,Estado,Id_Comprobante FROM dbo.Promociones;');

-- PROCEDURE dbo.Obtener_ComprobanteHistorico · Obtener_ComprobanteHistorico.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Obtener_ComprobanteHistorico · Obtener_ComprobanteHistorico.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Obtener_ComprobanteHistorico
    @IdComprobante nvarchar(25)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT P.Id_Comprobante AS IdComprobante, P.Registro_Estudiante AS Registro,
        P.Fecha_Pago AS FechaPago, P.Concepto, P.Metodo_Pago AS MetodoPago,
        P.Referencia_Transaccion AS Referencia, P.Descripcion,
        H.NombreEstudiante, H.Modalidad, H.Grado, H.UsuarioNombre AS RecibidoPor,
        H.DineroRecibido, H.SaldoAnterior, H.SaldoUtilizado,
        H.DeudaCancelada, H.CambioDevuelto, H.SaldoFinal,
        CASE WHEN H.Id_Comprobante IS NULL THEN NULL
            ELSE H.DineroRecibido - H.CambioDevuelto END AS IngresoNeto,
        CONVERT(bit, CASE WHEN H.Id_Comprobante IS NULL THEN 0 ELSE 1 END)
            AS DatosHistoricosDisponibles,
        P.Monto AS MontoRegistradoOriginal
    FROM dbo.Pagos P
    LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante = P.Id_Comprobante
    WHERE P.Id_Comprobante = @IdComprobante;
END;');

-- PROCEDURE dbo.Personal_Autorizar · Personal_Autorizar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Personal_Autorizar · Personal_Autorizar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Personal_Autorizar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 54500,N''Se requiere una transacción.'',1;
 DECLARE @Resultado int;
 EXEC @Resultado=sys.sp_getapplock @Resource=N''Liceo.Personal'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Resultado<0 THROW 54502,N''Personal ocupado; vuelva a intentar.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U
 JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
 LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE U.Id=@UsuarioId AND R.Name=N''Administrador'' AND ISNULL(E.Activa,1)=1
 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
 THROW 54501,N''Acceso denegado.'',1;
END;');

-- PROCEDURE dbo.Personal_Consultar · Personal_Consultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Personal_Consultar · Personal_Consultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Personal_Consultar
 @UsuarioId nvarchar(450), @CuentaId nvarchar(450)=NULL, @Pagina int=1, @Busqueda nvarchar(100)=N''''
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U
 JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
 LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE U.Id=@UsuarioId AND R.Name=N''Administrador'' AND ISNULL(E.Activa,1)=1
 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
 THROW 54501,N''Acceso denegado.'',1;
 IF @Pagina<1 OR @Pagina>100000 THROW 54503,N''Página inválida.'',1;
 SELECT COUNT_BIG(*) Total FROM dbo.AspNetUsers U WHERE CHARINDEX(@Busqueda,ISNULL(U.Email,N''''))>0 OR @Busqueda=N'''';
 SELECT U.Id,U.Email,U.EmailConfirmed,U.ConcurrencyStamp Version,ISNULL(E.Activa,1) Activa,
  CASE WHEN U.LockoutEnabled=1 AND U.LockoutEnd>SYSUTCDATETIME() THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END Bloqueada,
  (SELECT STRING_AGG(CONVERT(nvarchar(max),R.Name),N'', '') FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id) Roles
 FROM dbo.AspNetUsers U LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
 WHERE CHARINDEX(@Busqueda,ISNULL(U.Email,N''''))>0 OR @Busqueda=N''''
 ORDER BY U.Email,U.Id OFFSET (@Pagina-1)*50 ROWS FETCH NEXT 50 ROWS ONLY;
 SELECT U.Id,U.Email,U.ConcurrencyStamp Version,ISNULL(E.Activa,1) Activa,
  (SELECT STRING_AGG(CONVERT(nvarchar(max),R.Name),N'', '') FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id) Roles
 FROM dbo.AspNetUsers U LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@CuentaId;
 SELECT TOP(50) H.Fecha,H.Motivo,U.UserName Responsable,H.AntesJson,H.DespuesJson
 FROM dbo.HistorialCuentaPersonal H JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId
 WHERE H.CuentaId=@CuentaId ORDER BY H.Id DESC;
END;');

-- PROCEDURE dbo.Planificacion_CambioConsultar · Planificacion_CambioConsultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Planificacion_CambioConsultar · Planificacion_CambioConsultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Planificacion_CambioConsultar @UsuarioId nvarchar(450),@Tipo nvarchar(20),@OrigenId int,@Registro nvarchar(10)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54301,N''Se requiere administrador.'',1;
 IF @Tipo IS NULL OR @Tipo NOT IN (''Docente'',''Estudiante'') THROW 54302,N''Tipo de cambio inválido.'',1;
 IF @Tipo=''Docente''
 BEGIN
  SELECT D.Id,CONVERT(binary(8),D.Version) Version,CONCAT(Y.Anio,'' / '',P.Nombre,'' / '',N.Nivel,'' '',G.Seccion,'' / '',S.Nombre,'' / '',U.UserName) Descripcion
   FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId WHERE D.Id=@OrigenId;
  SELECT U.Id,U.UserName Etiqueta,C.Detalle Conflicto FROM dbo.AspNetUsers U
   OUTER APPLY (
    SELECT TOP(1) CONCAT(CHOOSE(X.Dia,N''lunes'',N''martes'',N''miércoles'',N''jueves'',N''viernes'',N''sábado'',N''domingo''),
       N'' '',CONVERT(char(5),X.Inicio,108),N''–'',CONVERT(char(5),X.Fin,108),N'' · '',S.Nombre,N'' · '',N.Nivel,N'' '',G.Seccion,N'' · '',P.Nombre) Detalle
    FROM dbo.HorarioClaseVigente H JOIN dbo.HorarioClaseVigente X
     ON X.AsignacionId<>H.AsignacionId AND X.Dia=H.Dia AND X.Inicio<H.Fin AND H.Inicio<X.Fin
    JOIN dbo.AsignacionDocente D ON D.Id=X.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Pensum N ON N.Id=G.PensumId
    JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
    JOIN dbo.AsignacionDocente A ON A.Id=H.AsignacionId JOIN dbo.GrupoAcademico GA ON GA.Id=A.GrupoId
    JOIN dbo.PeriodoAcademico O ON O.Id=GA.PeriodoId
    WHERE H.AsignacionId=@OrigenId AND D.UsuarioId=U.Id AND P.Inicio<=O.Fin AND O.Inicio<=P.Fin
    ORDER BY X.Dia,X.Inicio,X.Id
   ) C
   WHERE (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND U.EmailConfirmed=1 AND NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0)
   AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id AND R.Name=''Profesor'')
   AND NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente D WHERE D.Id=@OrigenId AND D.UsuarioId=U.Id) ORDER BY U.UserName;
 END
 ELSE
 BEGIN
  SELECT E.GrupoId Id,CONVERT(binary(8),E.Version) Version,CONCAT(E.Registro,'' / '',S.NombreEstudiante,'' / '',Y.Anio,'' / '',P.Nombre,'' / '',N.Nivel,'' '',G.Seccion) Descripcion
   FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro;
  SELECT G.Id,CONCAT(G.Id,'' / sección '',G.Seccion,'' / '',T.Nombre,'' / aula '',A.Nombre,'' / ocupación '',(SELECT COUNT(*) FROM dbo.GrupoEstudiante E WHERE E.GrupoId=G.Id),'' de '',A.Capacidad) Etiqueta
   FROM dbo.GrupoAcademico G JOIN dbo.GrupoAcademico O ON O.Id=@OrigenId AND G.PeriodoId=O.PeriodoId AND G.PensumId=O.PensumId
   JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico T ON T.Id=G.TurnoId WHERE G.Id<>O.Id AND A.Activo=1 AND T.Activo=1 ORDER BY G.Seccion,G.Id;
 END;
END;');

-- PROCEDURE dbo.Planificacion_CambiosHistorial · Planificacion_CambiosHistorial.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Planificacion_CambiosHistorial · Planificacion_CambiosHistorial.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Planificacion_CambiosHistorial @UsuarioId nvarchar(450),@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54301,N''Se requiere administrador.'',1;
 IF @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54302,N''Página inválida.'',1;
 SELECT C.Id,C.Tipo,C.Fecha,C.Motivo,C.AntesJson,C.DespuesJson,U.UserName Responsable INTO #Historial FROM dbo.CambioPlanificacion C LEFT JOIN dbo.AspNetUsers U ON U.Id=C.UsuarioId;
 SELECT COUNT_BIG(*) Total FROM #Historial;
 SELECT Id,Tipo,DATEADD(hour,-6,Fecha) FechaLocal,Responsable,Motivo,
 CASE WHEN Tipo=''Docente'' THEN CONCAT(N''Asignación '',JSON_VALUE(AntesJson,''$.AsignacionId''),N'' / '',JSON_VALUE(AntesJson,''$.Asignatura'')) ELSE CONCAT(JSON_VALUE(AntesJson,''$.Registro''),N'' / '',JSON_VALUE(AntesJson,''$.NombreEstudiante'')) END Registro,
 CONCAT(JSON_VALUE(AntesJson,''$.Anio''),N'' / '',JSON_VALUE(AntesJson,''$.Periodo'')) Periodo,
 CASE WHEN Tipo=''Docente'' THEN JSON_VALUE(AntesJson,''$.Docente'') ELSE CONCAT(N''Grupo '',JSON_VALUE(AntesJson,''$.GrupoId''),N'' / '',JSON_VALUE(AntesJson,''$.Seccion'')) END Anterior,
 CASE WHEN Tipo=''Docente'' THEN JSON_VALUE(DespuesJson,''$.Docente'') ELSE CONCAT(N''Grupo '',JSON_VALUE(DespuesJson,''$.GrupoId''),N'' / '',JSON_VALUE(DespuesJson,''$.Seccion'')) END Nuevo
 FROM #Historial ORDER BY Fecha DESC,Id DESC OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 50 ROWS ONLY;
END;');

-- PROCEDURE dbo.Planificacion_Consultar · Planificacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Planificacion_Consultar · Planificacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Planificacion_Consultar @UsuarioId nvarchar(450),@SoloDocente bit=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THEN 1 ELSE 0 END;
 IF @Admin=0 AND (@SoloDocente=0 OR NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Profesor'')) THROW 52301,N''Acceso denegado.'',1;
 IF @SoloDocente=1
 BEGIN
  SELECT Y.Anio,P.Nombre Periodo,G.Seccion,S.Nombre Asignatura,A.Nombre Aula,A.Ubicacion,H.Dia,H.Inicio,H.Fin
  FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=N.AnioId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.Aula A ON A.Id=G.AulaId LEFT JOIN dbo.HorarioClaseVigente H ON H.AsignacionId=D.Id
  WHERE D.UsuarioId=@UsuarioId ORDER BY Y.Anio DESC,P.Inicio,H.Dia,H.Inicio;
  RETURN;
 END;
 SELECT Id,Anio,Activo,CONVERT(nvarchar(10),Anio) Etiqueta FROM dbo.AnioLectivo ORDER BY Anio DESC;
 SELECT P.Id,P.AnioId,P.Nombre,P.Inicio,P.Fin,P.Cerrado,CONCAT(Y.Anio,'' / '',P.Nombre) Etiqueta,
 CONVERT(bit,CASE WHEN Y.Activo=1 AND P.Cerrado=0 THEN 1 ELSE 0 END) Disponible
 FROM dbo.PeriodoAcademico P JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId ORDER BY P.Inicio DESC;
 SELECT Id,Nombre,Activo,Nombre Etiqueta FROM dbo.ModalidadAcademica ORDER BY Nombre;
 SELECT Id,Nombre,Activo,Nombre Etiqueta FROM dbo.TurnoAcademico ORDER BY Nombre;
 SELECT Id,Nombre,Ubicacion,Capacidad,Activo,CONCAT(Nombre,'' / '',Ubicacion) Etiqueta FROM dbo.Aula ORDER BY Nombre;
 SELECT Id,Codigo,Nombre,Activo,CONCAT(Codigo,'' / '',Nombre) Etiqueta FROM dbo.Asignatura ORDER BY Nombre;
 SELECT P.Id,P.AnioId,P.ModalidadId,P.Nivel,CONCAT(Y.Anio,'' / '',M.Nombre,'' / '',P.Nivel) Etiqueta,CONVERT(bit,CASE WHEN Y.Activo=1 AND M.Activo=1 THEN 1 ELSE 0 END) Activo FROM dbo.Pensum P JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId ORDER BY Y.Anio DESC,M.Nombre,P.Nivel;
 SELECT P.PensumId,P.AsignaturaId,A.Nombre Asignatura FROM dbo.PensumAsignatura P JOIN dbo.Asignatura A ON A.Id=P.AsignaturaId ORDER BY P.PensumId,A.Nombre;
 SELECT G.Id,G.PensumId,G.PeriodoId,G.TurnoId,G.AulaId,G.Seccion,CONCAT(Y.Anio,'' / '',P.Nivel,'' '',G.Seccion,'' / '',T.Nombre) Etiqueta,
 CONVERT(bit,CASE WHEN Y.Activo=1 AND M.Activo=1 AND A.Activo=1 AND TA.Activo=1 AND T.Cerrado=0 THEN 1 ELSE 0 END) Activo
 FROM dbo.GrupoAcademico G JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId
 JOIN dbo.PeriodoAcademico T ON T.Id=G.PeriodoId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId
 JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico TA ON TA.Id=G.TurnoId ORDER BY Y.Anio DESC,P.Nivel,G.Seccion;
 SELECT U.Id,U.UserName Etiqueta FROM dbo.AspNetUsers U WHERE NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0) AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id AND R.Name=''Profesor'') ORDER BY U.UserName;
 SELECT D.Id,D.GrupoId,D.AsignaturaId,S.Nombre Asignatura,U.UserName Docente,CONCAT(S.Nombre,'' / '',U.UserName) Etiqueta,CONVERT(bit,CASE WHEN S.Activo=1 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0) AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=U.Id AND R.Name=''Profesor'') THEN 1 ELSE 0 END) Activo FROM dbo.AsignacionDocente D JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId;
 SELECT H.Id,H.AsignacionId,CONVERT(varchar(18),H.Version,1) VersionHorario,G.Seccion,S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin FROM dbo.HorarioClaseVigente H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId ORDER BY H.Dia,H.Inicio;
 SELECT E.GrupoId,E.Registro,S.NombreEstudiante FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro ORDER BY E.GrupoId,S.NombreEstudiante;
END;');

-- PROCEDURE dbo.Registrar_Auditoria · Registrar_Auditoria.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Registrar_Auditoria · Registrar_Auditoria.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Registrar_Auditoria
    @UsuarioId nvarchar(450),
    @Accion nvarchar(50),
    @Entidad nvarchar(80),
    @RegistroId nvarchar(100),
    @IdOperacion uniqueidentifier,
    @AntesJson nvarchar(max) = NULL,
    @DespuesJson nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF DB_NAME() <> N''__LICEO_BASE__''
        THROW 51100, N''Base incorrecta.'', 1;
    IF @@TRANCOUNT = 0 OR XACT_STATE() <> 1
        THROW 51101, N''La auditoria debe registrarse dentro de la transaccion del negocio.'', 1;
    IF @IdOperacion IS NULL OR NULLIF(LTRIM(RTRIM(@Accion)), N'''') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Entidad)), N'''') IS NULL
       OR NULLIF(LTRIM(RTRIM(@RegistroId)), N'''') IS NULL
        THROW 51102, N''Faltan datos de auditoria.'', 1;

    DECLARE @UsuarioNombre nvarchar(256);
    SELECT @UsuarioNombre = UserName FROM dbo.AspNetUsers WHERE Id = @UsuarioId;
    IF @UsuarioNombre IS NULL
        THROW 51103, N''Usuario de Identity inexistente.'', 1;
    IF (@AntesJson IS NOT NULL AND ISJSON(@AntesJson) <> 1)
       OR (@DespuesJson IS NOT NULL AND ISJSON(@DespuesJson) <> 1)
        THROW 51104, N''La auditoria requiere JSON valido.'', 1;

    INSERT dbo.Auditoria (
        UsuarioId, UsuarioNombre, Accion, Entidad, RegistroId,
        IdOperacion, AntesJson, DespuesJson)
    VALUES (
        @UsuarioId, @UsuarioNombre, @Accion, @Entidad, @RegistroId,
        @IdOperacion, @AntesJson, @DespuesJson);
END;');

-- PROCEDURE dbo.Saldo_Instantanea · ConciliacionSaldos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Saldo_Instantanea · ConciliacionSaldos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Saldo_Instantanea @UsuarioId nvarchar(450),@Registro nvarchar(10),@Json nvarchar(max) OUTPUT,@Saldo decimal(18,2) OUTPUT,@Filas int OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53201,N''Se requiere administrador.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro) THROW 53200,N''Estudiante inexistente.'',1;
 SELECT @Saldo=ISNULL(SUM(Abono_Disponible),0),@Filas=COUNT(*) FROM dbo.Abonos WITH(HOLDLOCK) WHERE Registro_Estudiante=@Registro;
 SET @Json=(SELECT @Registro Registro,@Saldo Saldo,@Filas FilasSaldo,
 JSON_QUERY((SELECT P.Id_Comprobante,P.Fecha_Pago,P.Concepto,P.Monto,P.Metodo_Pago,P.Referencia_Transaccion,
 H.DineroRecibido,H.CambioDevuelto,H.SaldoAnterior,H.SaldoUtilizado,H.DeudaCancelada,H.SaldoFinal
 FROM dbo.Pagos P WITH(HOLDLOCK) LEFT JOIN dbo.Historial_Comprobantes H WITH(HOLDLOCK) ON H.Id_Comprobante=P.Id_Comprobante
 WHERE P.Registro_Estudiante=@Registro ORDER BY P.Id_Comprobante FOR JSON PATH,INCLUDE_NULL_VALUES)) Pagos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
END;');

-- PROCEDURE dbo.TipoEvaluacion_Consultar · TipoEvaluacion_Consultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.TipoEvaluacion_Consultar · TipoEvaluacion_Consultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.TipoEvaluacion_Consultar
 @UsuarioId nvarchar(450),@Id int=0,@Pagina int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'')
 OR EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
 THROW 54601,N''Acceso exclusivo de administración activa.'',1;
 IF @Id<0 OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54602,N''Consulta inválida.'',1;
 SELECT T.Id,T.Nombre,T.Activo,CONVERT(varchar(18),CONVERT(binary(8),T.Version),1) Version,
 CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.TipoId=T.Id) THEN 1 ELSE 0 END) Utilizado
 FROM dbo.TipoEvaluacion T ORDER BY T.Nombre,T.Id;
 SELECT COUNT_BIG(*) Total FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id;
 SELECT Id,Fecha,UsuarioId,Motivo,NombreAnterior,NombreNuevo,ActivoAnterior,ActivoNuevo
 FROM dbo.HistorialTipoEvaluacion WHERE TipoId=@Id ORDER BY Id DESC
 OFFSET (@Pagina-1)*25 ROWS FETCH NEXT 25 ROWS ONLY;
END;');

-- PROCEDURE dbo.Ver_Estado_Mensualidad_Cuenta · Mensualidades_Legado.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Ver_Estado_Mensualidad_Cuenta · Mensualidades_Legado.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Ver_Estado_Mensualidad_Cuenta @TextoBusqueda nvarchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT E.NombreEstudiante,E.Modalidad,E.Grado,ISNULL(A.Abono_Disponible,0) SaldoFavor,
           M.Anio,M.Mes,M.Costo_Mensualidad,M.Estado
    FROM dbo.Estudiantes E LEFT JOIN dbo.Abonos A ON A.Registro_Estudiante=E.Registro
    LEFT JOIN dbo.Mensualidades M ON M.Registro_Estudiante=E.Registro AND M.Estado IN (N''Pendiente'',N''Vencido'')
    WHERE E.Registro=@TextoBusqueda AND E.Estado=N''Activo''
    ORDER BY M.Anio,M.Numero_Mes;
END;');

-- PROCEDURE dbo.Anticipo_Registrar · Anticipos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Anticipo_Registrar · Anticipos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Anticipo_Registrar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@Pagador nvarchar(200),
 @Metodo nvarchar(20),@Referencia nvarchar(100)=NULL,@Importe decimal(28,8)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 54700,N''No usar transacción externa.'',1;
 SET @Pagador=NULLIF(TRIM(@Pagador),N'''');
 SET @Referencia=NULLIF(TRIM(@Referencia),N'''');
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Pagador IS NULL OR @Metodo IS NULL OR @Metodo NOT IN (''Efectivo'',''Transferencia'')
 OR (@Metodo=''Transferencia'' AND @Referencia IS NULL)
 OR @Importe IS NULL OR @Importe<=0 OR @Importe>9999999999999999.99 OR ROUND(@Importe,2)<>@Importe
 THROW 54702,N''Revisa pagador, método, importe positivo y referencia de transferencia.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT N''Anticipo'' Tipo,@UsuarioId UsuarioId,@Registro Registro,@Pagador Pagador,
 @Metodo Metodo,@Referencia Referencia,@Importe Importe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Id bigint,@Nombre nvarchar(100),@Saldo decimal(18,2)=0,@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54703,N''Finanzas está ocupado. Reintenta desde el mismo formulario.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54702,N''El libro nuevo requiere el corte financiero aprobado.'',1;
 SELECT @Id=Id FROM dbo.ReciboMultiple WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId AND Anticipo>0)
   THROW 54702,N''La operación ya se usó con otros datos. Consulta los recibos.'',1;
  COMMIT;SELECT @Id;RETURN;
 END;
 SELECT @Nombre=NombreEstudiante FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro AND Estado=''Activo'';
 IF @Nombre IS NULL THROW 54702,N''El anticipo requiere un estudiante activo.'',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Saldo+@Importe>9999999999999999.99 THROW 54702,N''El saldo resultante excede el límite permitido.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.SaldoFinanciero WHERE Registro=@Registro)
  INSERT dbo.SaldoFinanciero(Registro,RevisionSaldoId,SaldoInicial,Disponible) VALUES(@Registro,NULL,0,0);
 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible+@Importe WHERE Registro=@Registro;
 DECLARE @Secuencia bigint=NEXT VALUE FOR dbo.Secuencia_Comprobantes;
 DECLARE @Numero nvarchar(25)=N''RC-''+CONVERT(nvarchar(20),@Secuencia);
 INSERT dbo.ReciboMultiple(Numero,Operacion,Registro,Pagador,UsuarioId,Metodo,Referencia,Recibido,Cambio,SolicitudHash,
  NombreEstudiante,SaldoAnterior,SaldoAplicado,SaldoFinal,TotalAplicado,Anticipo)
 VALUES(@Numero,@Operacion,@Registro,@Pagador,@UsuarioId,@Metodo,@Referencia,@Importe,0,@Hash,@Nombre,@Saldo,0,@Saldo+@Importe,0,@Importe);
 SET @Id=SCOPE_IDENTITY();
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Id),
  @Json nvarchar(max)=(SELECT @Registro Registro,@Numero Numero,@Importe Anticipo,@Saldo SaldoAnterior,@Saldo+@Importe SaldoFinal FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''RegistrarAnticipo'',''ReciboMultiple'',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;SELECT @Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Aranceles_Consultar · Aranceles_Consultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Aranceles_Consultar · Aranceles_Consultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Aranceles_Consultar @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52801,N''Acceso exclusivo de administración.'',1;
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
 CASE WHEN O.OrigenId IS NULL THEN N''ORIGEN_AUSENTE''
 WHEN EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N''ORIGEN_CAMBIO''
 ELSE N''CAPTURADO_SIN_CONCILIAR'' END Revision
 FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId ORDER BY P.Origen,P.OrigenId;
 SELECT (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada) OrigenesActuales,(SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion) FilasPreparadas,
 (SELECT COUNT_BIG(*) FROM dbo.ObligacionLegada O WHERE NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P WHERE P.Origen=O.Origen AND P.OrigenId=O.OrigenId)) SinPreparar,
 (SELECT COUNT_BIG(*) FROM dbo.PreparacionObligacion P LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId WHERE O.OrigenId IS NULL OR EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante)) FuentesCambiadas;
END;');

-- PROCEDURE dbo.Aranceles_Guardar · Aranceles.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Aranceles_Guardar · Aranceles.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Aranceles_Guardar @UsuarioId nvarchar(450),@Datos nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52801,N''Solo administración puede modificar estos datos.'',1;
 IF ISJSON(@Datos)<>1 THROW 52800,N''Datos inválidos.'',1;
 DECLARE @Accion nvarchar(20)=JSON_VALUE(@Datos,''$.Accion''),@Id int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Id'')),
 @Codigo nvarchar(30)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Codigo'')),''''),@Nombre nvarchar(150)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Nombre'')),''''),
 @Arancel int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.ArancelId'')),@Modalidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.ModalidadId'')),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AnioId'')),
 @Importe decimal(18,2)=TRY_CONVERT(decimal(18,2),JSON_VALUE(@Datos,''$.Importe'')),@Activo bit=CASE JSON_VALUE(@Datos,''$.Activo'') WHEN ''true'' THEN 1 WHEN ''false'' THEN 0 END,
 @Origen nvarchar(30)=JSON_VALUE(@Datos,''$.Origen''),@Motivo nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Motivo'')),''''),
 @Version binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,''$.Version''),1),@Lock int,@Operacion uniqueidentifier=NEWID(),@Antes nvarchar(max),@Despues nvarchar(max);
 IF @Accion IS NULL OR @Accion NOT IN (''Arancel'',''Tarifa'',''Mapeo'',''Preparar'') OR @Motivo IS NULL OR @Id IS NULL OR @Id<0 THROW 52800,N''Operación o motivo inválido.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52802,N''Hay otra operación en curso. Reintenta.'',1;
 IF @Accion IN (''Mapeo'',''Preparar'') AND NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=0)
  THROW 52804,N''La preparación de obligaciones requiere que el libro anterior siga abierto.'',1;
 IF @Accion=''Arancel''
 BEGIN
  IF @Codigo IS NULL OR @Nombre IS NULL OR @Activo IS NULL THROW 52800,N''Completa código, nombre y estado.'',1;
  IF @Id=0
  BEGIN
   INSERT dbo.Arancel(Codigo,Nombre,Activo) VALUES(@Codigo,@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N''El arancel cambió. Recarga antes de editar.'',1;
   SET @Antes=(SELECT Codigo,Nombre,Activo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   IF EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE ArancelId=@Id) OR EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@Id)
    IF EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Id AND (Codigo<>@Codigo OR Nombre<>@Nombre)) THROW 52804,N''El arancel está referenciado. Solo puede cambiar su estado.'',1;
   UPDATE dbo.Arancel SET Codigo=@Codigo,Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Codigo,Nombre,Activo,@Motivo Motivo FROM dbo.Arancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion=''Tarifa''
 BEGIN
  IF @Importe IS NULL OR @Importe<0 OR @Activo IS NULL THROW 52800,N''Importe o estado inválido.'',1;
  IF TRY_CONVERT(decimal(38,10),JSON_VALUE(@Datos,''$.Importe''))<>@Importe THROW 52800,N''El importe admite hasta dos decimales.'',1;
  IF @Id=0
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Arancel AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Modalidad AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Anio AND Activo=1) THROW 52804,N''Selecciona arancel, modalidad y año activos.'',1;
   INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe,Activo) VALUES(@Arancel,@Modalidad,@Anio,@Importe,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());
   INSERT dbo.HistorialTarifa(TarifaId,ImporteNuevo,ActivoNuevo,Motivo,UsuarioId) VALUES(@Id,@Importe,@Activo,@Motivo,@UsuarioId);
  END
  ELSE
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id AND Version=@Version) THROW 52803,N''La tarifa cambió. Recarga antes de editar.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE Id=@Id AND ArancelId=@Arancel AND ModalidadId=@Modalidad AND AnioId=@Anio) THROW 52804,N''No se cambia el arancel, modalidad ni año de una tarifa. Crea otra combinación.'',1;
   SET @Antes=(SELECT Importe,Activo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   INSERT dbo.HistorialTarifa(TarifaId,ImporteAnterior,ImporteNuevo,ActivoAnterior,ActivoNuevo,Motivo,UsuarioId) SELECT Id,Importe,@Importe,Activo,@Activo,@Motivo,@UsuarioId FROM dbo.TarifaArancel WHERE Id=@Id;
   UPDATE dbo.TarifaArancel SET Importe=@Importe,Activo=@Activo WHERE Id=@Id;
  END;
  SET @Despues=(SELECT Importe,Activo,@Motivo Motivo FROM dbo.TarifaArancel WHERE Id=@Id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion=''Mapeo''
 BEGIN
  IF @Origen IS NULL OR @Origen NOT IN (''Matriculas'',''Mensualidades'',''Mantenimientos'',''EvBoTaS'',''Promociones'') OR NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@Arancel AND Activo=1) THROW 52804,N''Origen o arancel inválido.'',1;
  IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE Origen=@Origen AND ArancelId<>@Arancel) THROW 52804,N''El origen ya está vinculado. La corrección del mapeo requiere revisión de sus dependencias.'',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE Origen=@Origen)
   INSERT dbo.MapaConceptoLegado(Origen,ArancelId,UsuarioId) VALUES(@Origen,@Arancel,@UsuarioId);
  SET @Despues=(SELECT @Origen Origen,@Arancel ArancelId,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF @Accion=''Preparar''
 BEGIN
  IF (SELECT COUNT(*) FROM dbo.MapaConceptoLegado)<>5 THROW 52804,N''Vincula los cinco conceptos antes de preparar.'',1;
  -- HOLDLOCK conserva una lectura consistente durante esta captura; no es el corte financiero.
  INSERT dbo.PreparacionObligacion(Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante,ArancelId,UsuarioId)
  SELECT O.Origen,O.OrigenId,O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante,M.ArancelId,@UsuarioId
  FROM dbo.ObligacionLegada O WITH(HOLDLOCK) JOIN dbo.MapaConceptoLegado M ON M.Origen=O.Origen
  WHERE NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P WITH(UPDLOCK,HOLDLOCK) WHERE P.Origen=O.Origen AND P.OrigenId=O.OrigenId);
  DECLARE @Cantidad int=@@ROWCOUNT;
  SET @Despues=(SELECT @Cantidad NuevasFilas,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 DECLARE @AccionAudit nvarchar(50)=N''Finanzas_''+@Accion,@RegistroAudit nvarchar(100)=CASE WHEN @Accion=''Mapeo'' THEN @Origen ELSE CONVERT(nvarchar(100),@Id) END;
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N''CatalogoFinanciero'',@RegistroId=@RegistroAudit,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Cargos_Configurar · GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_Configurar · GeneracionCargos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_Configurar @UsuarioId nvarchar(450),@ArancelId int,@Periodicidad nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @Periodicidad IS NULL OR @Periodicidad NOT IN (''Anual'',''Mensual'',''Eventual'') THROW 53602,N''Periodicidad inválida.'',1;
 IF @@TRANCOUNT<>0 THROW 53600,N''No usar transacción externa.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Arancel WHERE Id=@ArancelId AND Activo=1) THROW 53602,N''Arancel inexistente o inactivo.'',1;
 IF EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId AND Periodicidad<>@Periodicidad) THROW 53602,N''La periodicidad ya fue definida. Su cambio requiere revisar cargos e historial.'',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@ArancelId AND CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END<>@Periodicidad) THROW 53602,N''La periodicidad contradice el mapeo histórico. Revise la conciliación.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionCargo WHERE ArancelId=@ArancelId)
 BEGIN
  INSERT dbo.ConfiguracionCargo VALUES(@ArancelId,@Periodicidad);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@ArancelId),@Op uniqueidentifier=NEWID(),@Json nvarchar(max)=(SELECT @Periodicidad Periodicidad FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,''ConfigurarCargo'',''Arancel'',@Id,@Op,NULL,@Json;
 END;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Cargos_ConfigurarMatricula · Cargos_ConfigurarMatricula.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_ConfigurarMatricula · Cargos_ConfigurarMatricula.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_ConfigurarMatricula @UsuarioId nvarchar(450),@ArancelId int
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53600,N''No usar transacción externa.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado.'',1;
 IF EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula WHERE Id=1 AND ArancelId<>@ArancelId) THROW 53602,N''El arancel de matrícula ya está definido. No se puede sustituir sin revisar el historial.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Arancel A JOIN dbo.ConfiguracionCargo C ON C.ArancelId=A.Id WHERE A.Id=@ArancelId AND A.Activo=1 AND C.Periodicidad=''Anual'') THROW 53602,N''Selecciona un arancel activo con periodicidad anual.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula WHERE Id=1)
 BEGIN
  INSERT dbo.ConfiguracionMatricula(Id,ArancelId) VALUES(1,@ArancelId);
  DECLARE @Operacion uniqueidentifier=NEWID(),@Json nvarchar(max)=(SELECT @ArancelId ArancelId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,''ConfigurarMatricula'',''ConfiguracionMatricula'',''1'',@Operacion,NULL,@Json;
 END;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Cargos_Generar · GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_Generar · GeneracionCargos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_Generar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@TarifaId int,@VersionTarifa binary(8),@Mes int=NULL,@Evento nvarchar(30)=NULL,@Vencimiento date=NULL,@PermitirTransaccion bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 AND ISNULL(@PermitirTransaccion,0)=0 THROW 53600,N''No usar transacción externa.'',1;
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR @VersionTarifa IS NULL THROW 53602,N''Falta operación o versión de tarifa.'',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),'''');
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@TarifaId TarifaId,CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Mes Mes,@Evento Evento,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@CargoId bigint,@Lock int,@Anio int,@ArancelId int,@AnioId int,@Importe decimal(18,2),@Nombre nvarchar(150),@Periodicidad nvarchar(10),@Referencia nvarchar(80),@Descripcion nvarchar(200);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado. Reintente la misma operación.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N''Aplique y valide el corte financiero antes de generar cargos.'',1;
 SELECT @CargoId=CargoId FROM dbo.GeneracionCargo WHERE Operacion=@Operacion;
 IF @CargoId IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.GeneracionCargo WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53602,N''La operación ya se usó con otros datos. Consulte la cuenta.'',1;
  COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;RETURN;
 END;
 -- El precio procede siempre de la tarifa y la modalidad debe coincidir con el expediente.
 SELECT @ArancelId=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Importe=T.Importe,@Nombre=A.Nombre,@Periodicidad=F.Periodicidad
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Arancel A ON A.Id=T.ArancelId
 JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.Estudiantes E ON E.Registro=@Registro AND E.Modalidad=M.Nombre
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND E.Estado=''Activo'';
 IF @Importe IS NULL OR @Importe<=0 THROW 53602,N''Revise estudiante activo, modalidad, periodicidad y tarifa vigente. Si cambió la tarifa, vuelva a consultar.'',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@ArancelId AND CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END<>@Periodicidad) THROW 53602,N''La periodicidad contradice los conceptos históricos.'',1;
 IF @Periodicidad=''Mensual'' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL) THROW 53602,N''El cargo mensual requiere mes de 1 a 12 y ningún evento.'',1;
 IF @Periodicidad=''Anual'' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL) THROW 53602,N''El cargo anual no lleva mes ni evento.'',1;
 IF @Periodicidad=''Eventual'' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Z0-9_-]%'') THROW 53602,N''El evento requiere código de letras, números, guion o guion bajo; no lleva mes.'',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N''El vencimiento debe pertenecer al año de la tarifa.'',1;
 SET @Referencia=CASE @Periodicidad WHEN ''Anual'' THEN ''ANUAL'' WHEN ''Mensual'' THEN ''MES:''+RIGHT(''0''+CONVERT(varchar(2),@Mes),2) ELSE ''EVENTO:''+@Evento END;
 IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante C WITH(UPDLOCK,HOLDLOCK) JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId WHERE C.Registro=@Registro AND T.ArancelId=@ArancelId AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THROW 53602,N''Ya existe ese cargo, incluso si fue anulado. Consulte la cuenta.'',1;
 -- Incluye obligaciones antiguas pagadas (CargoId nulo): no volver a facturarlas.
 IF EXISTS(SELECT 1 FROM dbo.ObligacionMigrada O JOIN dbo.RevisionObligacion R ON R.Id=O.RevisionId JOIN dbo.TarifaArancel T ON T.Id=R.TarifaId
 LEFT JOIN dbo.Mensualidades M ON O.Origen=''Mensualidades'' AND M.Id=O.OrigenId
 WHERE R.Registro=@Registro AND T.ArancelId=@ArancelId AND T.AnioId=@AnioId AND (O.Origen<>''Mensualidades'' OR @Periodicidad<>''Mensual'' OR M.Numero_Mes=@Mes OR M.Id IS NULL))
 THROW 53602,N''Existe una obligación histórica para este concepto y período; consulte la cuenta y la conciliación.'',1;
 SET @Descripcion=LEFT(@Nombre,150)+N'' · ''+CONVERT(nvarchar(4),@Anio)+N'' · ''+@Referencia;
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento) VALUES(@Registro,@TarifaId,@Referencia,@Descripcion,@Importe,@Vencimiento);
 SET @CargoId=SCOPE_IDENTITY();
 INSERT dbo.GeneracionCargo(Operacion,CargoId,SolicitudHash,UsuarioId) VALUES(@Operacion,@CargoId,@Hash,@UsuarioId);
 DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@CargoId),@Json nvarchar(max)=(SELECT @Registro Registro,@TarifaId TarifaId,@Referencia Referencia,@Descripcion Descripcion,@Importe Importe,@Vencimiento Vencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''GenerarCargo'',''CargoEstudiante'',@Id,@Operacion,NULL,@Json;
 COMMIT;IF @PermitirTransaccion=0 SELECT @CargoId CargoId;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Cargos_Pantalla · GeneracionCargos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_Pantalla · GeneracionCargos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_Pantalla @UsuarioId nvarchar(450),@Registro nvarchar(10)=NULL,@Global bit=0
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 SELECT CONVERT(bit,ISNULL((SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1),0)) Migrado;
 SELECT A.Id,A.Nombre,F.Periodicidad FROM dbo.Arancel A LEFT JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id WHERE A.Activo=1 ORDER BY A.Nombre;
 SELECT Registro,NombreEstudiante,Modalidad,Estado FROM dbo.Estudiantes WHERE Registro=@Registro;
 SELECT T.Id,A.Nombre,Y.Anio,M.Nombre Modalidad,T.Importe,F.Periodicidad,CONVERT(binary(8),T.Version) VersionTarifa
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 WHERE T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND T.Importe>0
 AND (@Global=1 OR EXISTS(SELECT 1 FROM dbo.Estudiantes E WHERE E.Registro=@Registro AND E.Modalidad=M.Nombre AND E.Estado=''Activo''))
 ORDER BY Y.Anio DESC,M.Nombre,A.Nombre;
 SELECT C.ArancelId,A.Nombre FROM dbo.ConfiguracionMatricula C JOIN dbo.Arancel A ON A.Id=C.ArancelId WHERE C.Id=1;
END;');

-- PROCEDURE dbo.CatalogoAcademico_Guardar · Planificacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CatalogoAcademico_Guardar · Planificacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CatalogoAcademico_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450),@ResultadoId int=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52300,N''Datos inválidos.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52301,N''Se requiere administrador.'',1;
 DECLARE @Tipo nvarchar(30)=JSON_VALUE(@Datos,''$.Tipo''),@Id int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Id'')),
 @Nombre nvarchar(100)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@Datos,''$.Nombre''))),''''),@Codigo nvarchar(30)=NULLIF(JSON_VALUE(@Datos,''$.Codigo''),''''),
 @Ubicacion nvarchar(200)=NULLIF(JSON_VALUE(@Datos,''$.Ubicacion''),''''),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Anio'')),
 @AnioId int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AnioId'')),@Capacidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Capacidad'')),
 @Inicio date=TRY_CONVERT(date,JSON_VALUE(@Datos,''$.Inicio'')),@Fin date=TRY_CONVERT(date,JSON_VALUE(@Datos,''$.Fin'')),
 @Activo bit=CASE WHEN JSON_VALUE(@Datos,''$.Activo'')=''true'' THEN 1 ELSE 0 END,
 @SoloEstado bit=CASE WHEN JSON_VALUE(@Datos,''$.SoloEstado'')=''true'' THEN 1 ELSE 0 END;
 IF @Id IS NULL OR @Id<0 OR @Tipo IS NULL OR @Tipo NOT IN (''Anios'',''Periodos'',''Modalidades'',''Turnos'',''Aulas'',''Asignaturas'') THROW 52302,N''Catálogo inválido.'',1;
 IF @SoloEstado=1 AND (@Id=0 OR @Tipo=''Periodos'') THROW 52302,N''Operación de estado inválida.'',1;
 IF @SoloEstado=0 AND @Tipo<>''Anios'' AND (@Nombre IS NULL OR (@Tipo<>''Asignaturas'' AND LEN(@Nombre)>80)) THROW 52302,N''Nombre inválido.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52303,N''Planificación ocupada. Intente nuevamente.'',1;
 IF @Tipo=''Anios''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  IF @SoloEstado=1 UPDATE dbo.AnioLectivo SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Anio IS NULL OR @Anio NOT BETWEEN 1900 AND 9999 THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE AnioId=@Id) OR EXISTS(SELECT 1 FROM dbo.Pensum WHERE AnioId=@Id) OR EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE AnioId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.AnioLectivo(Anio,Activo) VALUES(@Anio,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.AnioLectivo SET Anio=@Anio,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo=''Periodos''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  BEGIN
   IF @Inicio IS NULL OR @Fin IS NULL OR @Fin<@Inicio OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@AnioId AND Activo=1 AND YEAR(@Inicio)=Anio AND YEAR(@Fin)=Anio) THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PeriodoId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin) VALUES(@AnioId,@Nombre,@Inicio,@Fin);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.PeriodoAcademico SET AnioId=@AnioId,Nombre=@Nombre,Inicio=@Inicio,Fin=@Fin WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo=''Modalidades''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  IF @SoloEstado=1 UPDATE dbo.ModalidadAcademica SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF 1=0 THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.Pensum WHERE ModalidadId=@Id) OR EXISTS(SELECT 1 FROM dbo.TarifaArancel WHERE ModalidadId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.ModalidadAcademica(Nombre,Activo) VALUES(@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.ModalidadAcademica SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo=''Turnos''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.TurnoAcademico WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  IF @SoloEstado=1 UPDATE dbo.TurnoAcademico SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF 1=0 THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE TurnoId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.TurnoAcademico(Nombre,Activo) VALUES(@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.TurnoAcademico SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo=''Aulas''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.Aula WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  IF @SoloEstado=1 UPDATE dbo.Aula SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Capacidad IS NULL OR @Capacidad<=0 OR @Ubicacion IS NULL THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE AulaId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.Aula(Nombre,Ubicacion,Capacidad,Activo) VALUES(@Nombre,@Ubicacion,@Capacidad,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.Aula SET Nombre=@Nombre,Ubicacion=@Ubicacion,Capacidad=@Capacidad,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 ELSE IF @Tipo=''Asignaturas''
 BEGIN
  IF @Id>0 AND NOT EXISTS(SELECT 1 FROM dbo.Asignatura WHERE Id=@Id) THROW 52304,N''Registro inexistente.'',1;
  IF @SoloEstado=1 UPDATE dbo.Asignatura SET Activo=@Activo WHERE Id=@Id;
  ELSE
  BEGIN
   IF @Codigo IS NULL THROW 52302,N''Revise los campos del catálogo.'',1;
   IF @Id>0 AND (EXISTS(SELECT 1 FROM dbo.PensumAsignatura WHERE AsignaturaId=@Id) OR EXISTS(SELECT 1 FROM dbo.AsignacionDocente WHERE AsignaturaId=@Id)) THROW 52305,N''El registro ya se utiliza: conserve su definición histórica. Puede inactivarlo cuando corresponda.'',1;
   IF @Id=0 BEGIN INSERT dbo.Asignatura(Codigo,Nombre,Activo) VALUES(@Codigo,@Nombre,@Activo);SET @Id=CONVERT(int,SCOPE_IDENTITY());END
   ELSE UPDATE dbo.Asignatura SET Codigo=@Codigo,Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
  END;
 END;
 DECLARE @Operacion uniqueidentifier=NEWID(),@Registro nvarchar(100)=CONVERT(nvarchar(100),@Id);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''GuardarCatalogoAcademico'',@Entidad=@Tipo,@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 SET @ResultadoId=@Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.CierreAcademico_Guardar · CierreAcademico.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CierreAcademico_Guardar · CierreAcademico.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CierreAcademico_Guardar @UsuarioId nvarchar(450),@Accion nvarchar(30),@PeriodoId int,@AsignacionId int=0,@Version varchar(18),@Motivo nvarchar(500)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52601,N''Solo administración puede realizar esta operación.'',1;
 IF @Accion IS NULL OR @Accion NOT IN (''CerrarPeriodo'',''ReabrirPeriodo'',''ReabrirAsignacion'') OR NULLIF(TRIM(@Motivo),'''') IS NULL THROW 52600,N''Operación o motivo inválido.'',1;
 DECLARE @Token binary(8)=TRY_CONVERT(binary(8),@Version,1),@Lock int,@Foto nvarchar(max),@Operacion uniqueidentifier=NEWID(),@RegistroId nvarchar(100)=CONCAT(@PeriodoId,'':'',@AsignacionId);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52602,N''Hay otra operación académica en curso; vuelve a intentarlo.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId) THROW 52600,N''Período inexistente.'',1;
 IF @Accion=''ReabrirAsignacion''
 BEGIN
  IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=1) THROW 52603,N''Primero reabre el período.'',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.PublicacionNotas N JOIN dbo.AsignacionDocente A ON A.Id=N.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId WHERE A.Id=@AsignacionId AND G.PeriodoId=@PeriodoId AND N.Vigente=1 AND N.Version=@Token)
   THROW 52604,N''La publicación cambió o ya no está vigente. Recarga la página.'',1;
  UPDATE dbo.PublicacionNotas SET Vigente=0 WHERE AsignacionId=@AsignacionId;
 END
 ELSE
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Version=@Token) THROW 52604,N''El período cambió. Recarga la página.'',1;
  IF @Accion=''ReabrirPeriodo''
  BEGIN
   IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=0) THROW 52603,N''El período ya está abierto.'',1;
   UPDATE dbo.PeriodoAcademico SET Cerrado=0 WHERE Id=@PeriodoId;
  END
  ELSE
  BEGIN
   IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@PeriodoId AND Cerrado=1) THROW 52603,N''El período ya está cerrado.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PeriodoId=@PeriodoId) THROW 52605,N''El período no tiene grupos.'',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico G WHERE G.PeriodoId=@PeriodoId AND (NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante GE WHERE GE.GrupoId=G.Id) OR NOT EXISTS(SELECT 1 FROM dbo.PensumAsignatura PA WHERE PA.PensumId=G.PensumId))) THROW 52605,N''Hay grupos sin estudiantes o sin materias.'',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PensumAsignatura PA ON PA.PensumId=G.PensumId LEFT JOIN dbo.AsignacionDocente A ON A.GrupoId=G.Id AND A.AsignaturaId=PA.AsignaturaId WHERE G.PeriodoId=@PeriodoId AND A.Id IS NULL) THROW 52605,N''Faltan docentes asignados a materias del pensum.'',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId LEFT JOIN dbo.PublicacionNotas N ON N.AsignacionId=A.Id AND N.Vigente=1 WHERE G.PeriodoId=@PeriodoId AND N.AsignacionId IS NULL) THROW 52605,N''Hay asignaturas sin publicación vigente.'',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId WHERE G.PeriodoId=@PeriodoId AND (NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id) OR (EXISTS(SELECT 1 FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id AND E.Modo=''Cuantitativa'') AND (SELECT SUM(E.Peso) FROM dbo.Evaluacion E WHERE E.AsignacionId=A.Id AND E.Modo=''Cuantitativa'')<>100))) THROW 52605,N''Hay evaluaciones o pesos incompletos.'',1;
   IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.GrupoEstudiante GE ON GE.GrupoId=G.Id JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=GE.Registro WHERE G.PeriodoId=@PeriodoId AND ((E.Modo=''Cuantitativa'' AND (C.Nota IS NULL OR C.Nota<0 OR C.Nota>E.Maximo)) OR (E.Modo=''Cualitativa'' AND (C.Resultado IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.OpcionEvaluacion O WHERE O.EvaluacionId=E.Id AND O.Valor=C.Resultado))))) THROW 52605,N''Hay calificaciones pendientes o inválidas.'',1;
   UPDATE dbo.PeriodoAcademico SET Cerrado=1 WHERE Id=@PeriodoId;
  END;
 END;
 -- Instantánea de resultados que permite revisar cada cierre/reapertura sin depender del estado posterior.
 SET @Foto=(SELECT A.Id AsignacionId,E.Id EvaluacionId,E.Nombre,E.Modo,E.Maximo,E.Peso,C.Registro,C.Nota,C.Resultado,C.Observacion
 FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId JOIN dbo.Evaluacion E ON E.AsignacionId=A.Id JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id
 WHERE G.PeriodoId=@PeriodoId AND (@Accion<>''ReabrirAsignacion'' OR A.Id=@AsignacionId) FOR JSON PATH,INCLUDE_NULL_VALUES);
 INSERT dbo.EventoAcademico(PeriodoId,AsignacionId,Accion,UsuarioId,Motivo,Instantanea) VALUES(@PeriodoId,CASE WHEN @Accion=''ReabrirAsignacion'' THEN @AsignacionId END,@Accion,@UsuarioId,TRIM(@Motivo),@Foto);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@Accion,@Entidad=N''PeriodoAcademico'',@RegistroId=@RegistroId,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.CobroMultiple_Registrar · CobroMultiple.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CobroMultiple_Registrar · CobroMultiple.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CobroMultiple_Registrar
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@Pagador nvarchar(200),
 @Metodo nvarchar(20),@Referencia nvarchar(100)=NULL,@Recibido decimal(28,8),@SaldoAplicado decimal(28,8),@Aplicaciones nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53500,N''No usar transacción externa.'',1;
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR NULLIF(LTRIM(RTRIM(@Pagador)),'''') IS NULL OR @Metodo NOT IN (''Efectivo'',''Transferencia'',''Saldo'') OR @Metodo IS NULL THROW 53502,N''Datos incompletos.'',1;
 IF @Recibido IS NULL OR @SaldoAplicado IS NULL OR @Recibido<0 OR @SaldoAplicado<0 OR @Recibido>9999999999999999.99 OR @SaldoAplicado>9999999999999999.99 OR ROUND(@Recibido,2)<>@Recibido OR ROUND(@SaldoAplicado,2)<>@SaldoAplicado THROW 53502,N''Importes inválidos: use hasta dos decimales.'',1;
 IF ISJSON(@Aplicaciones)<>1 OR LEFT(LTRIM(@Aplicaciones),1)<>''['' THROW 53502,N''Aplicaciones inválidas.'',1;
 DECLARE @Items TABLE(CargoId bigint,Importe decimal(28,8));
 INSERT @Items SELECT TRY_CONVERT(bigint,JSON_VALUE(value,''$.CargoId'')),TRY_CONVERT(decimal(28,8),JSON_VALUE(value,''$.Importe'')) FROM OPENJSON(@Aplicaciones);
 IF (SELECT COUNT(*) FROM @Items) NOT BETWEEN 1 AND 50 OR EXISTS(SELECT 1 FROM @Items WHERE CargoId IS NULL OR Importe IS NULL OR Importe<=0 OR ROUND(Importe,2)<>Importe OR Importe>9999999999999999.99) OR EXISTS(SELECT CargoId FROM @Items GROUP BY CargoId HAVING COUNT(*)>1) THROW 53502,N''Seleccione entre 1 y 50 cargos distintos con importes positivos.'',1;
 DECLARE @Total decimal(38,8)=(SELECT SUM(Importe) FROM @Items);
 IF @Total>9999999999999999.99 OR @SaldoAplicado>@Total OR @Recibido+@SaldoAplicado<@Total THROW 53502,N''El dinero y saldo no cubren el importe seleccionado.'',1;
 DECLARE @Cambio decimal(18,2)=@Recibido+@SaldoAplicado-@Total;
 IF (@Metodo=''Transferencia'' AND (NULLIF(LTRIM(RTRIM(@Referencia)),'''') IS NULL OR @Cambio<>0 OR @Recibido<=0)) OR (@Metodo=''Saldo'' AND @Recibido<>0) OR (@Metodo=''Efectivo'' AND @Recibido<=0) THROW 53502,N''Revise método, referencia e importe recibido. Transferencias sin vuelto; saldo sin dinero recibido.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@Pagador Pagador,@Metodo Metodo,@Referencia Referencia,@Recibido Recibido,@SaldoAplicado SaldoAplicado,JSON_QUERY((SELECT CargoId,Importe FROM @Items ORDER BY CargoId FOR JSON PATH)) Aplicaciones FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Id bigint,@Numero nvarchar(25),@Saldo decimal(18,2)=0,@Nombre nvarchar(100),@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Mismo orden que configuración/corte; serializa cobros de este colegio pequeño.
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53503,N''Finanzas está ocupado. Reintente con la misma operación.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53502,N''El libro nuevo requiere el corte financiero aprobado.'',1;
 SELECT @Id=Id,@Numero=Numero FROM dbo.ReciboMultiple WITH(UPDLOCK,HOLDLOCK) WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53502,N''Esta operación ya se usó con otros datos. Consulte el recibo antes de continuar.'',1;
  COMMIT;SELECT @Id Id,@Numero Numero;RETURN;
 END;
 SELECT @Nombre=NombreEstudiante FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Nombre IS NULL THROW 53502,N''Estudiante inexistente.'',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @SaldoAplicado>@Saldo THROW 53502,N''Saldo a favor insuficiente. Actualice la consulta.'',1;
 IF EXISTS(SELECT 1 FROM @Items I LEFT JOIN dbo.CargoEstudiante C WITH(UPDLOCK,HOLDLOCK) ON C.Id=I.CargoId WHERE C.Id IS NULL OR C.Registro<>@Registro OR C.Anulado=1 OR I.Importe>C.Importe-ISNULL((SELECT SUM(A.Importe) FROM dbo.AplicacionPagoVigente A WITH(UPDLOCK,HOLDLOCK) WHERE A.CargoId=C.Id),0)) THROW 53502,N''Un cargo no pertenece al estudiante, está anulado o su deuda cambió.'',1;
 DECLARE @Secuencia bigint=NEXT VALUE FOR dbo.Secuencia_Comprobantes;
 SET @Numero=N''RC-''+CONVERT(nvarchar(20),@Secuencia);
 IF EXISTS(SELECT 1 FROM dbo.Pagos WHERE Id_Comprobante=@Numero) THROW 53502,N''Numeración ocupada. Revise la secuencia con administración.'',1;
 INSERT dbo.ReciboMultiple(Numero,Operacion,Registro,Pagador,UsuarioId,Metodo,Referencia,Recibido,Cambio,SolicitudHash,NombreEstudiante,SaldoAnterior,SaldoAplicado,SaldoFinal,TotalAplicado)
 VALUES(@Numero,@Operacion,@Registro,@Pagador,@UsuarioId,@Metodo,@Referencia,@Recibido,@Cambio,@Hash,@Nombre,@Saldo,@SaldoAplicado,@Saldo-@SaldoAplicado,@Total);
 SET @Id=SCOPE_IDENTITY();
 INSERT dbo.AplicacionPago(ReciboId,CargoId,Importe,DescripcionHistorica) SELECT @Id,I.CargoId,I.Importe,C.DescripcionHistorica FROM @Items I JOIN dbo.CargoEstudiante C ON C.Id=I.CargoId;
 IF @SaldoAplicado>0 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible-@SaldoAplicado WHERE Registro=@Registro;
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Id),@Json nvarchar(max)=(SELECT @Numero Numero,@Registro Registro,@Total TotalAplicado,@Recibido Recibido,@Cambio Cambio,@SaldoAplicado SaldoAplicado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''CobroMultiple'',''ReciboMultiple'',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;
 SELECT @Id Id,@Numero Numero;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Conciliacion_Consultar · Conciliacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Conciliacion_Consultar · Conciliacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Conciliacion_Consultar @UsuarioId nvarchar(450),@DespuesDeRevision bigint=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53001,N''Se requiere administrador.'',1;
 SELECT TOP(200) R.Id,R.Origen,R.OrigenId,R.Registro,R.TarifaId,R.Decision,R.Motivo,R.UsuarioId,R.Fecha,R.Generacion,
 CASE WHEN R.Generacion<>(SELECT P.Generacion FROM dbo.PreparacionObligacion P WHERE P.Origen=R.Origen AND P.OrigenId=R.OrigenId) THEN N''CAPTURA_REEMPLAZADA''
 WHEN O.OrigenId IS NULL THEN N''ORIGEN_AUSENTE''
 WHEN EXISTS(SELECT R.Registro,R.Anio,R.Modalidad,R.Importe,R.Estado,R.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N''ORIGEN_CAMBIO''
 ELSE N''COINCIDE_CON_ORIGEN'' END EstadoFuente,
 CONVERT(bit,CASE WHEN R.Generacion<>(SELECT P.Generacion FROM dbo.PreparacionObligacion P WHERE P.Origen=R.Origen AND P.OrigenId=R.OrigenId) THEN 0 WHEN EXISTS(SELECT 1 FROM dbo.RevisionObligacion X WHERE X.Origen=R.Origen AND X.OrigenId=R.OrigenId AND X.Id>R.Id) THEN 0 ELSE 1 END) UltimaRevision
 FROM dbo.RevisionObligacion R LEFT JOIN dbo.ObligacionLegada O ON O.Origen=R.Origen AND O.OrigenId=R.OrigenId
 WHERE R.Id>@DespuesDeRevision ORDER BY R.Id;
END;');

-- PROCEDURE dbo.Conciliacion_Pantalla · Conciliacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Conciliacion_Pantalla · Conciliacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Conciliacion_Pantalla
 @UsuarioId nvarchar(450),@Pagina int=1,@Registro nvarchar(10)=N'''',@Origen nvarchar(30)=N'''',@OrigenId int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53001,N''Se requiere administrador.'',1;
 IF @Pagina NOT BETWEEN 1 AND 100000 THROW 53000,N''Página inválida.'',1;
 SELECT P.Origen,P.OrigenId,P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante,
 ISNULL(R.Id,0) RevisionAnterior,CASE WHEN R.Generacion=P.Generacion THEN R.Decision ELSE N''REQUIERE_NUEVA_REVISION'' END Decision,
 CASE WHEN O.OrigenId IS NULL THEN N''ORIGEN_AUSENTE''
 WHEN EXISTS(SELECT P.Registro,P.Anio,P.Modalidad,P.Importe,P.Estado,P.Comprobante EXCEPT SELECT O.Registro,O.Anio,O.Modalidad,O.Importe,O.Estado,O.Comprobante) THEN N''ORIGEN_CAMBIO''
 ELSE N''COINCIDE_CON_ORIGEN'' END EstadoFuente
 FROM dbo.PreparacionObligacion P
 OUTER APPLY(SELECT TOP(1) Id,Decision,Generacion FROM dbo.RevisionObligacion R WHERE R.Origen=P.Origen AND R.OrigenId=P.OrigenId ORDER BY Id DESC) R
 LEFT JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId
 WHERE @Registro=N'''' OR P.Registro=@Registro
 ORDER BY P.Origen,P.OrigenId OFFSET ((@Pagina-1)*50) ROWS FETCH NEXT 51 ROWS ONLY;
 SELECT P.*,ISNULL(R.Id,0) RevisionAnterior,CASE WHEN R.Generacion=P.Generacion THEN R.Decision ELSE N''REQUIERE_NUEVA_REVISION'' END Decision
 FROM dbo.PreparacionObligacion P OUTER APPLY(SELECT TOP(1) Id,Decision,Generacion FROM dbo.RevisionObligacion R WHERE R.Origen=P.Origen AND R.OrigenId=P.OrigenId ORDER BY Id DESC) R
 WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId;
 SELECT T.Id,CONCAT(A.Nombre,N'' / '',Y.Anio,N'' / '',M.Nombre,N'' / precio actual '',T.Importe) Etiqueta
 FROM dbo.TarifaArancel T JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 JOIN dbo.PreparacionObligacion P ON P.ArancelId=T.ArancelId AND P.Anio=Y.Anio AND P.Modalidad=M.Nombre
 WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 ORDER BY T.Id;
 SELECT TOP(200) R.Id,R.Generacion,R.TarifaId,R.Decision,R.Motivo,U.UserName Responsable,R.Fecha
 FROM dbo.RevisionObligacion R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId
 WHERE R.Origen=@Origen AND R.OrigenId=@OrigenId ORDER BY R.Id DESC;
 SELECT TOP(200) H.Id,H.GeneracionAnterior,H.GeneracionNueva,H.Motivo,U.UserName Responsable,H.Fecha,H.AntesJson,H.DespuesJson
 FROM dbo.HistorialCaptura H JOIN dbo.AspNetUsers U ON U.Id=H.UsuarioId WHERE H.Origen=@Origen AND H.OrigenId=@OrigenId ORDER BY H.Id DESC;
END;');

-- PROCEDURE dbo.Conciliacion_Recapturar · Conciliacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Conciliacion_Recapturar · Conciliacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Conciliacion_Recapturar
 @UsuarioId nvarchar(450),@Origen nvarchar(30),@OrigenId int,@GeneracionEsperada int,@RevisionAnterior bigint,@Motivo nvarchar(500)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53001,N''Se requiere administrador.'',1;
 IF NULLIF(LTRIM(RTRIM(@Motivo)),'''') IS NULL THROW 53000,N''Indica el motivo.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Antes nvarchar(max),@Despues nvarchar(max),@Operacion uniqueidentifier=NEWID(),@Clave nvarchar(100)=CONCAT(@Origen,'':'',@OrigenId);
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53002,N''Hay otra operación en curso.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion WITH(UPDLOCK,HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId AND Generacion=@GeneracionEsperada AND CargoId IS NULL) THROW 53003,N''Captura modificada o vinculada a un cargo. Recarga.'',1;
 IF ISNULL((SELECT MAX(Id) FROM dbo.RevisionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId),0)<>@RevisionAnterior OR @RevisionAnterior IS NULL THROW 53003,N''La revisión cambió. Recarga.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N''El origen no existe; requiere investigación, no recaptura.'',1;
 IF EXISTS(SELECT 1 FROM dbo.PreparacionObligacion P JOIN dbo.ObligacionLegada O WITH(HOLDLOCK) ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId AND P.Registro<>O.Registro) THROW 53004,N''El estudiante de origen cambió. Requiere investigación.'',1;
 IF NOT EXISTS(SELECT Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.PreparacionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId EXCEPT SELECT Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N''No hay diferencias para recapturar.'',1;
 SET @Antes=(SELECT * FROM dbo.PreparacionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 UPDATE P SET Anio=O.Anio,Modalidad=O.Modalidad,Importe=O.Importe,Estado=O.Estado,Comprobante=O.Comprobante,Generacion=P.Generacion+1,Capturado=SYSUTCDATETIME(),UsuarioId=@UsuarioId
 FROM dbo.PreparacionObligacion P JOIN dbo.ObligacionLegada O ON O.Origen=P.Origen AND O.OrigenId=P.OrigenId WHERE P.Origen=@Origen AND P.OrigenId=@OrigenId;
 SET @Despues=(SELECT * FROM dbo.PreparacionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 INSERT dbo.HistorialCaptura(Origen,OrigenId,GeneracionAnterior,GeneracionNueva,AntesJson,DespuesJson,Motivo,UsuarioId) VALUES(@Origen,@OrigenId,@GeneracionEsperada,@GeneracionEsperada+1,@Antes,@Despues,@Motivo,@UsuarioId);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''RecapturarObligacion'',@Entidad=N''Conciliacion'',@RegistroId=@Clave,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Conciliacion_Revisar · Conciliacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Conciliacion_Revisar · Conciliacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Conciliacion_Revisar
 @UsuarioId nvarchar(450),@Origen nvarchar(30),@OrigenId int,@TarifaId int,
 @Decision nvarchar(20),@Motivo nvarchar(500),@RevisionAnterior bigint=0,@GeneracionEsperada int=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53001,N''Se requiere administrador.'',1;
 IF @Decision IS NULL OR @Decision NOT IN (''Deuda'',''SinDeuda'',''Rechazada'') OR NULLIF(LTRIM(RTRIM(@Motivo)),'''') IS NULL THROW 53000,N''Decisión o motivo inválido.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53002,N''Hay otra operación en curso.'',1;
 DECLARE @Registro nvarchar(10),@Anio int,@Modalidad nvarchar(20),@Importe decimal(18,2),@Estado nvarchar(10),@Comprobante nvarchar(25),@Arancel int,@Cargo bigint;
 SELECT @Registro=Registro,@Anio=Anio,@Modalidad=Modalidad,@Importe=Importe,@Estado=Estado,@Comprobante=Comprobante,@Arancel=ArancelId,@Cargo=CargoId
 FROM dbo.PreparacionObligacion WITH(UPDLOCK,HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId;
 IF NOT EXISTS(SELECT 1 FROM dbo.PreparacionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId AND Generacion=@GeneracionEsperada) THROW 53003,N''La captura cambió. Recarga la página.'',1;
 IF @Registro IS NULL OR @Cargo IS NOT NULL THROW 53000,N''Obligación no disponible para revisión.'',1;
 IF ISNULL((SELECT MAX(Id) FROM dbo.RevisionObligacion WHERE Origen=@Origen AND OrigenId=@OrigenId),0)<>@RevisionAnterior OR @RevisionAnterior IS NULL THROW 53003,N''Otra persona revisó esta obligación. Recarga antes de continuar.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N''La obligación de origen ya no existe.'',1;
 IF EXISTS(SELECT @Registro,@Anio,@Modalidad,@Importe,@Estado,@Comprobante EXCEPT SELECT Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada WITH(HOLDLOCK) WHERE Origen=@Origen AND OrigenId=@OrigenId) THROW 53004,N''El origen cambió desde la captura. No se aprobó.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel T WITH(HOLDLOCK) JOIN dbo.AnioLectivo A ON A.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.Arancel C ON C.Id=T.ArancelId WHERE T.Id=@TarifaId AND T.ArancelId=@Arancel AND A.Anio=@Anio AND M.Nombre=@Modalidad AND T.Activo=1 AND C.Activo=1 AND A.Activo=1 AND M.Activo=1) THROW 53005,N''La tarifa debe corresponder al arancel, año y modalidad originales.'',1;
 -- El precio actual no reemplaza el importe histórico ni las becas.
 IF @Decision<>''Rechazada'' AND @Importe<0 THROW 53005,N''No se aprueban importes negativos.'',1;
 IF @Decision=''Deuda'' AND (@Estado NOT IN (''Pendiente'',''Vencido'') OR @Importe<=0 OR @Comprobante IS NOT NULL OR @Origen=''Matriculas'') THROW 53005,N''Solo puede aprobarse como deuda una obligación pendiente positiva sin comprobante.'',1;
 IF @Decision=''SinDeuda'' AND NOT (@Estado=''Cancelado'' OR @Importe=0) THROW 53005,N''Una obligación pendiente positiva no puede marcarse sin deuda.'',1;
 IF @Decision<>''Rechazada'' AND @Comprobante IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Pagos WITH(HOLDLOCK) WHERE Id_Comprobante=@Comprobante AND Registro_Estudiante=@Registro) THROW 53005,N''El comprobante no corresponde al estudiante.'',1;
 INSERT dbo.RevisionObligacion(Origen,OrigenId,TarifaId,Decision,Motivo,UsuarioId,Registro,Anio,Modalidad,Importe,Estado,Comprobante,Generacion)
 VALUES(@Origen,@OrigenId,@TarifaId,@Decision,@Motivo,@UsuarioId,@Registro,@Anio,@Modalidad,@Importe,@Estado,@Comprobante,@GeneracionEsperada);
 DECLARE @Id bigint=CONVERT(bigint,SCOPE_IDENTITY()),@Operacion uniqueidentifier=NEWID(),@Clave nvarchar(100)=CONCAT(@Origen,'':'',@OrigenId),@Json nvarchar(max);
 SET @Json=(SELECT @Id RevisionId,@TarifaId TarifaId,@Decision Decision,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''RevisarObligacion'',@Entidad=N''Conciliacion'',@RegistroId=@Clave,@IdOperacion=@Operacion,@DespuesJson=@Json;
 COMMIT;
 SELECT @Id RevisionId;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.CorteFinanciero_Ejecutar · CorteFinanciero.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CorteFinanciero_Ejecutar · CorteFinanciero.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CorteFinanciero_Ejecutar @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Aplicar bit=0,@Confirmacion nvarchar(60)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF DB_NAME()<>''__LICEO_BASE__'' OR @@TRANCOUNT<>0 THROW 53400,N''Use desarrollo sin transacciones abiertas.'',1;
 IF @Operacion IS NULL OR @Aplicar IS NULL THROW 53400,N''Indique operación y modalidad.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53401,N''Se requiere administrador.'',1;
 IF @Aplicar=1 AND ISNULL(@Confirmacion,N'''')<>N''APLICAR CORTE EN DESARROLLO'' THROW 53400,N''Falta confirmación explícita.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Tabla sysname,@Sql nvarchar(max),@N bigint;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53402,N''Hay otra operación financiera en curso.'',1;
 IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Operacion=@Operacion) THROW 53403,N''El corte ya fue aplicado con otra operación.'',1;
  COMMIT;SELECT N''YA_APLICADO'' Estado;RETURN;
 END;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1) THROW 53400,N''Falta control de corte.'',1;
 -- Bloquear primero fuentes: los procedimientos heredados no conocen el applock.
 DECLARE Bloqueos CURSOR LOCAL FAST_FORWARD FOR SELECT T FROM (VALUES
 (''Estudiantes''),(''Pagos''),(''Abonos''),(''Matriculas''),(''Mensualidades''),(''Mantenimientos''),(''EvBoTaS''),(''Promociones''),(''Arreglos_Pago''),(''Historial_Comprobantes''),
 (''Costo_Matricula''),(''Costo_Mensualidad''),(''Costo_Mantenimiento''),(''Costo_EvBoTa''),(''Costo_Promocion''),
 (''PreparacionObligacion''),(''RevisionObligacion''),(''RevisionSaldo''),(''MapaConceptoLegado''),(''HistorialCaptura''),
 (''Arancel''),(''TarifaArancel''),(''AnioLectivo''),(''ModalidadAcademica''),(''CargoEstudiante''),(''ReciboMultiple''),(''AplicacionPago''),(''SaldoFinanciero''),(''ObligacionMigrada'')) V(T);
 OPEN Bloqueos;FETCH NEXT FROM Bloqueos INTO @Tabla;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Sql=N''SELECT @N=COUNT_BIG(*) FROM dbo.''+QUOTENAME(@Tabla)+N'' WITH(TABLOCKX,HOLDLOCK);'';EXEC sys.sp_executesql @Sql,N''@N bigint OUTPUT'',@N OUTPUT;
  FETCH NEXT FROM Bloqueos INTO @Tabla;
 END;
 CLOSE Bloqueos;DEALLOCATE Bloqueos;
 -- Verificar que las barreras realmente existen y están habilitadas.
 IF EXISTS(SELECT 1 FROM (VALUES(''Pagos''),(''Abonos''),(''Matriculas''),(''Mensualidades''),(''Mantenimientos''),(''EvBoTaS''),(''Promociones''),(''Arreglos_Pago''),(''Historial_Comprobantes''),(''Costo_Matricula''),(''Costo_Mensualidad''),(''Costo_Mantenimiento''),(''Costo_EvBoTa''),(''Costo_Promocion''),(''PreparacionObligacion''),(''RevisionObligacion''),(''RevisionSaldo''),(''MapaConceptoLegado''),(''HistorialCaptura'')) V(T)
 WHERE NOT EXISTS(SELECT 1 FROM sys.triggers WHERE name=N''TR_Corte_''+V.T AND parent_id=OBJECT_ID(N''dbo.''+V.T) AND is_disabled=0)) THROW 53404,N''Faltan barreras de escritura; reinstale correctamente la infraestructura.'',1;
 IF EXISTS(SELECT 1 FROM dbo.CargoEstudiante) OR EXISTS(SELECT 1 FROM dbo.ReciboMultiple) OR EXISTS(SELECT 1 FROM dbo.SaldoFinanciero) OR EXISTS(SELECT 1 FROM dbo.ObligacionMigrada) THROW 53404,N''El destino financiero no está vacío. Requiere investigación.'',1;
 IF EXISTS(SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada EXCEPT SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.PreparacionObligacion)
 OR EXISTS(SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.PreparacionObligacion EXCEPT SELECT Origen,OrigenId,Registro,Anio,Modalidad,Importe,Estado,Comprobante FROM dbo.ObligacionLegada) THROW 53404,N''Hay obligaciones sin capturar, cambiadas o eliminadas.'',1;
 SELECT P.*,R.Id RevisionId,R.TarifaId,R.Decision,R.Generacion GeneracionRevisada INTO #Obligaciones
 FROM dbo.PreparacionObligacion P OUTER APPLY(SELECT TOP(1) * FROM dbo.RevisionObligacion X WHERE X.Origen=P.Origen AND X.OrigenId=P.OrigenId ORDER BY Id DESC) R;
 IF EXISTS(SELECT 1 FROM #Obligaciones WHERE RevisionId IS NULL OR Generacion<>GeneracionRevisada OR Decision=''Rechazada'' OR CargoId IS NOT NULL OR Importe<0) THROW 53404,N''Faltan revisiones vigentes y aprobadas de obligaciones.'',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones P WHERE NOT EXISTS(SELECT 1 FROM dbo.TarifaArancel T JOIN dbo.AnioLectivo A ON A.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId WHERE T.Id=P.TarifaId AND T.ArancelId=P.ArancelId AND A.Anio=P.Anio AND M.Nombre=P.Modalidad)) THROW 53404,N''Las tarifas ya no coinciden con las obligaciones.'',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones WHERE (Decision=''Deuda'' AND (Estado NOT IN (''Pendiente'',''Vencido'') OR Importe<=0 OR Comprobante IS NOT NULL OR Origen=''Matriculas'')) OR (Decision=''SinDeuda'' AND Estado<>''Cancelado'' AND Importe<>0)) THROW 53404,N''Decisión incompatible con estado o importe.'',1;
 IF EXISTS(SELECT 1 FROM #Obligaciones O WHERE Comprobante IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Pagos P WHERE P.Id_Comprobante=O.Comprobante AND P.Registro_Estudiante=O.Registro)) THROW 53404,N''Hay comprobantes incompatibles con la obligación.'',1;
 -- Todos los estudiantes con actividad financiera requieren saldo revisado, incluso cero.
 DECLARE @Registro nvarchar(10),@Json nvarchar(max),@Saldo decimal(18,2),@Filas int,@Revision bigint;
 DECLARE Saldos CURSOR LOCAL FAST_FORWARD FOR SELECT Registro_Estudiante FROM dbo.Pagos UNION SELECT Registro_Estudiante FROM dbo.Abonos UNION SELECT Registro FROM dbo.PreparacionObligacion;
 OPEN Saldos;FETCH NEXT FROM Saldos INTO @Registro;
 WHILE @@FETCH_STATUS=0
 BEGIN
  EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
  SET @Revision=NULL;
  SELECT @Revision=Id FROM dbo.RevisionSaldo WHERE Id=(SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro) AND Decision=''Aprobado'' AND Huella=HASHBYTES(''SHA2_256'',@Json) AND SaldoObservado=@Saldo AND FilasSaldo=@Filas;
  IF @Revision IS NULL OR @Saldo<0 OR @Filas>1 THROW 53404,N''Falta aprobación vigente de un saldo. Consulte Conciliación de saldos.'',1;
  INSERT dbo.SaldoFinanciero(Registro,RevisionSaldoId,SaldoInicial,Disponible) VALUES(@Registro,@Revision,@Saldo,@Saldo);
  FETCH NEXT FROM Saldos INTO @Registro;
 END;
 CLOSE Saldos;DEALLOCATE Saldos;
 INSERT dbo.CargoEstudiante(Registro,TarifaId,Referencia,DescripcionHistorica,Importe,Vencimiento)
 SELECT O.Registro,O.TarifaId,CONCAT(N''LEGADO:'',O.Origen,'':'',O.OrigenId),CONCAT(A.Nombre,N'' / '',O.Anio,N'' / '',O.Origen,N'' #'',O.OrigenId),O.Importe,NULL FROM #Obligaciones O JOIN dbo.Arancel A ON A.Id=O.ArancelId WHERE O.Decision=''Deuda'';
 INSERT dbo.ObligacionMigrada(Origen,OrigenId,RevisionId,CargoId)
 SELECT O.Origen,O.OrigenId,O.RevisionId,C.Id FROM #Obligaciones O LEFT JOIN dbo.CargoEstudiante C ON C.Registro=O.Registro AND C.TarifaId=O.TarifaId AND C.Referencia=CONCAT(N''LEGADO:'',O.Origen,'':'',O.OrigenId);
 UPDATE P SET CargoId=M.CargoId FROM dbo.PreparacionObligacion P JOIN dbo.ObligacionMigrada M ON M.Origen=P.Origen AND M.OrigenId=P.OrigenId;
 IF ISNULL((SELECT SUM(Importe) FROM dbo.CargoEstudiante),0)<>ISNULL((SELECT SUM(Importe) FROM #Obligaciones WHERE Decision=''Deuda''),0) THROW 53404,N''No coinciden los totales de deuda.'',1;
 DECLARE @Cargos bigint=(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante),@TotalDeuda decimal(38,2)=ISNULL((SELECT SUM(Importe) FROM dbo.CargoEstudiante),0),@TotalSaldo decimal(38,2)=ISNULL((SELECT SUM(SaldoInicial) FROM dbo.SaldoFinanciero),0);
 IF @Aplicar=0
 BEGIN
  ROLLBACK;SELECT N''SIMULACION_REVERTIDA'' Estado,@Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial;RETURN;
 END;
 UPDATE dbo.ControlFinanciero SET Migrado=1,Operacion=@Operacion,Fecha=SYSUTCDATETIME(),UsuarioId=@UsuarioId WHERE Id=1;
 DECLARE @Detalle nvarchar(max)=(SELECT @Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''CorteFinanciero'',@Entidad=N''ControlFinanciero'',@RegistroId=N''1'',@IdOperacion=@Operacion,@DespuesJson=@Detalle;
 COMMIT;
 SELECT N''APLICADO'' Estado,@Cargos Cargos,@TotalDeuda Deuda,@TotalSaldo SaldoInicial;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.CuentaEstudiante_Consultar · CobroMultiple.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.CuentaEstudiante_Consultar · CobroMultiple.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.CuentaEstudiante_Consultar @UsuarioId nvarchar(450),@Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Shared'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53503,N''Finanzas está ocupado.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WHERE Registro=@Registro) THROW 53502,N''Estudiante inexistente.'',1;
 SELECT E.Registro,E.NombreEstudiante,ISNULL(S.Disponible,0) SaldoFavor,CONVERT(bit,ISNULL((SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1),0)) Migrado FROM dbo.Estudiantes E LEFT JOIN dbo.SaldoFinanciero S ON S.Registro=E.Registro WHERE E.Registro=@Registro;
 SELECT C.Id,C.DescripcionHistorica,C.Vencimiento,C.Importe,ISNULL(A.Pagado,0) Pagado,C.Importe-ISNULL(A.Pagado,0) Pendiente FROM dbo.CargoEstudiante C OUTER APPLY(SELECT SUM(Importe) Pagado FROM dbo.AplicacionPagoVigente WHERE CargoId=C.Id) A WHERE C.Registro=@Registro AND C.Anulado=0 ORDER BY C.Id;
 SELECT R.Id,R.Numero,R.Fecha,R.Metodo,R.Recibido,R.Cambio,R.SaldoAplicado,R.TotalAplicado,R.Anticipo,
 CONVERT(bit,CASE WHEN X.Id IS NULL THEN 0 ELSE 1 END) Anulado,ISNULL(X.DineroDevuelto,0) DineroDevuelto,ISNULL(X.SaldoRestituido,0) SaldoRestituido
 FROM dbo.ReciboMultiple R LEFT JOIN dbo.AnulacionRecibo X ON X.ReciboId=R.Id WHERE R.Registro=@Registro ORDER BY R.Id DESC;
 -- Solo referencia histórica. NO sumarla a ingresos ni deuda del libro nuevo.
 SELECT Id_Comprobante,Fecha_Pago,Concepto,Monto FROM dbo.Pagos WHERE Registro_Estudiante=@Registro ORDER BY Fecha_Pago DESC,Id_Comprobante;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Estudiante_DarBaja · Expediente.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Estudiante_DarBaja · Expediente.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Estudiante_DarBaja @Registro nvarchar(10), @Motivo nvarchar(500), @UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@UsuarioId AND R.Name=N''Administrador'') THROW 52111,N''Se requiere administrador.'',1;
 IF NULLIF(LTRIM(RTRIM(@Motivo)),'''') IS NULL THROW 52112,N''Indique el motivo de la baja.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Estado nvarchar(10);
 SELECT @Estado=Estado FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Estado IS NULL THROW 52115,N''Estudiante inexistente.'',1;
 IF @Estado<>''Activo'' THROW 52112,N''El estudiante ya está inactivo.'',1;
 UPDATE dbo.Estudiantes SET Estado=''Inactivo'' WHERE Registro=@Registro;
 INSERT dbo.Historial_Bajas(RegistroEstudiante,Motivo,FechaBaja)
 VALUES(@Registro,@Motivo,CONVERT(datetime,SYSUTCDATETIME() AT TIME ZONE ''UTC'' AT TIME ZONE ''Central America Standard Time''));
 DECLARE @Operacion uniqueidentifier=NEWID();
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''DarBajaEstudiante'',@Entidad=N''Estudiantes'',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Evaluacion_Editar · Evaluacion_Editar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Evaluacion_Editar · Evaluacion_Editar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Evaluacion_Editar @UsuarioId nvarchar(450),@EvaluacionId int,@Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max),@Datos nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 OR @Datos IS NULL THROW 54402,N''Definición inválida.'',1;
 SET @Motivo=NULLIF(TRIM(@Motivo),N'''');
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>''0x'' OR TRY_CONVERT(binary(8),@Version,1) IS NULL THROW 54402,N''Indica operación, versión y motivo de 10 a 500 caracteres.'',1;
 DECLARE @Tipo int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.TipoId'')),@Nombre nvarchar(max)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Nombre'')),''''),
 @Fecha date=TRY_CONVERT(date,JSON_VALUE(@Datos,''$.Fecha'')),@Modo nvarchar(20)=JSON_VALUE(@Datos,''$.Modo''),
 @Maximo decimal(28,10)=TRY_CONVERT(decimal(28,10),JSON_VALUE(@Datos,''$.Maximo'')),@Peso decimal(28,10)=TRY_CONVERT(decimal(28,10),JSON_VALUE(@Datos,''$.Peso'')),
 @Valores nvarchar(max)=JSON_QUERY(@Datos,''$.Valores''),@Lock int,@Asignacion int,@Actual binary(8),@Antes nvarchar(max),@Despues nvarchar(max);
 IF @Nombre IS NULL OR LEN(@Nombre)>100 OR @Fecha IS NULL OR @Tipo IS NULL OR @Modo IS NULL OR @Modo NOT IN (''Cuantitativa'',''Cualitativa'') THROW 54402,N''Revisa nombre, tipo, fecha y modalidad.'',1;
 IF @Modo=''Cuantitativa''
 BEGIN
  IF @Maximo IS NULL OR @Maximo<=0 OR @Maximo>99999.99 OR ROUND(@Maximo,2)<>@Maximo OR @Peso IS NULL OR @Peso<=0 OR @Peso>100 OR ROUND(@Peso,2)<>@Peso THROW 54402,N''Puntos y peso positivos, con hasta dos decimales; peso máximo 100%.'',1;
  SET @Valores=N''[]'';
 END
 ELSE
 BEGIN
  SET @Maximo=1;SET @Peso=0;
  IF @Valores IS NULL OR LEFT(LTRIM(@Valores),1)<>''['' THROW 54402,N''Define la escala cualitativa.'',1;
  IF (SELECT COUNT(*) FROM OPENJSON(@Valores)) NOT BETWEEN 2 AND 20 OR EXISTS(SELECT 1 FROM OPENJSON(@Valores) WHERE type<>1 OR LEN(TRIM(value)) NOT BETWEEN 1 AND 100)
   OR EXISTS(SELECT TRIM(value) FROM OPENJSON(@Valores) GROUP BY TRIM(value) HAVING COUNT(*)>1) THROW 54402,N''Define de 2 a 20 resultados diferentes de hasta 100 caracteres.'',1;
 END;
 DECLARE @Solicitud nvarchar(max)=(SELECT @EvaluacionId EvaluacionId,@Tipo TipoId,@Nombre Nombre,@Fecha Fecha,@Modo Modo,@Maximo Maximo,@Peso Peso,JSON_QUERY(@Valores) Valores,@Version Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54403,N''La planificación está ocupada. Reintenta.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion E JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId
 WHERE E.Id=@EvaluacionId AND EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND (R.Name=''Administrador'' OR (R.Name=''Profesor'' AND D.UsuarioId=@UsuarioId)))) THROW 54401,N''Evaluación no disponible para tu cuenta.'',1;
 IF EXISTS(SELECT 1 FROM dbo.HistorialEvaluacion WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.HistorialEvaluacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 54404,N''La operación ya se utilizó con otros datos.'',1;
  COMMIT;RETURN;
 END;
 SELECT @Asignacion=AsignacionId,@Actual=Version FROM dbo.Evaluacion WITH(UPDLOCK,HOLDLOCK) WHERE Id=@EvaluacionId;
 IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54405,N''Otra persona cambió la evaluación. Recarga antes de guardar.'',1;
 IF EXISTS(SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND P.Cerrado=1)
 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion) THROW 54406,N''No se puede editar una definición de un período cerrado o una asignatura con publicaciones.'',1;
 IF EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@EvaluacionId) OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion WHERE EvaluacionId=@EvaluacionId) THROW 54407,N''La evaluación tiene registros de calificaciones. Se conserva su definición.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Tipo AND Activo=1) THROW 54402,N''Selecciona un tipo de evaluación activo.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND @Fecha BETWEEN P.Inicio AND P.Fin) THROW 54402,N''La fecha debe estar dentro del período.'',1;
 IF @Modo=''Cuantitativa'' AND @Peso+ISNULL((SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Id<>@EvaluacionId AND Modo=''Cuantitativa''),0)>100 THROW 54408,N''Los pesos de la asignatura no pueden superar 100%.'',1;
 SET @Antes=(SELECT E.Nombre,T.Nombre Tipo,E.TipoId,E.Fecha,E.Modo,E.Maximo,E.Peso,
 JSON_QUERY((SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=E.Id ORDER BY Valor FOR JSON PATH)) Valores
 FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.Id=@EvaluacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 UPDATE dbo.Evaluacion SET TipoId=@Tipo,Nombre=@Nombre,Fecha=@Fecha,Modo=@Modo,Maximo=@Maximo,Peso=@Peso WHERE Id=@EvaluacionId;
 DELETE dbo.OpcionEvaluacion WHERE EvaluacionId=@EvaluacionId;
 IF @Modo=''Cualitativa'' INSERT dbo.OpcionEvaluacion(EvaluacionId,Valor) SELECT @EvaluacionId,TRIM(value) FROM OPENJSON(@Valores);
 SET @Despues=(SELECT E.Nombre,T.Nombre Tipo,E.TipoId,E.Fecha,E.Modo,E.Maximo,E.Peso,
 JSON_QUERY((SELECT Valor FROM dbo.OpcionEvaluacion WHERE EvaluacionId=E.Id ORDER BY Valor FOR JSON PATH)) Valores
 FROM dbo.Evaluacion E JOIN dbo.TipoEvaluacion T ON T.Id=E.TipoId WHERE E.Id=@EvaluacionId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT dbo.HistorialEvaluacion(EvaluacionId,Operacion,SolicitudHash,UsuarioId,Motivo,AntesJson,DespuesJson) VALUES(@EvaluacionId,@Operacion,@Hash,@UsuarioId,@Motivo,@Antes,@Despues);
 DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@EvaluacionId);
 EXEC dbo.Registrar_Auditoria @UsuarioId,N''EditarEvaluacion'',N''Evaluacion'',@Id,@Operacion,@Antes,@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Expediente_Guardar · Expediente.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Expediente_Guardar · Expediente.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Expediente_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52110,N''Formulario inválido.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@UsuarioId AND R.Name=N''Administrador'')
 THROW 52111,N''Se requiere administrador.'',1;
 DECLARE @Registro nvarchar(10)=NULLIF(JSON_VALUE(@Datos,''$.Registro''),''''),
 @Nombre nvarchar(100)=JSON_VALUE(@Datos,''$.NombreEstudiante''),
 @Modalidad nvarchar(20)=JSON_VALUE(@Datos,''$.Modalidad''),@Grado nvarchar(50)=JSON_VALUE(@Datos,''$.Grado''),
 @Nacimiento date=TRY_CONVERT(date,JSON_VALUE(@Datos,''$.FechaNacimiento'')),
 @Sexo char(1)=JSON_VALUE(@Datos,''$.Sexo''),@Direccion nvarchar(200)=JSON_VALUE(@Datos,''$.Direccion''),
 @Tutor nvarchar(20)=JSON_VALUE(@Datos,''$.Tutor''),@Motivo nvarchar(500)=JSON_VALUE(@Datos,''$.Motivo''),
 @Hoy date=CONVERT(date,SYSUTCDATETIME() AT TIME ZONE ''UTC'' AT TIME ZONE ''Central America Standard Time''),
 @Ingreso nvarchar(20)=JSON_VALUE(@Datos,''$.TipoIngreso''),@Codigo nvarchar(100)=JSON_VALUE(@Datos,''$.CodigoTraslado''),
 @Centro nvarchar(200)=JSON_VALUE(@Datos,''$.CentroProcedencia''),@Version nvarchar(4000)=NULLIF(JSON_VALUE(@Datos,''$.Version''),N'''');
 IF NULLIF(LTRIM(RTRIM(@Nombre)),'''') IS NULL OR @Nacimiento IS NULL OR @Nacimiento>@Hoy OR @Nacimiento<DATEADD(year,-100,@Hoy)
 OR @Tutor IS NULL OR @Tutor NOT IN (''Padre'',''Madre'',''Otro'') OR NULLIF(LTRIM(RTRIM(@Motivo)),'''') IS NULL
 THROW 52112,N''Revise nombre, fecha de nacimiento, tutor y motivo.'',1;
 IF @Ingreso IS NULL OR @Ingreso NOT IN (''Nuevo'',''Traslado'') OR (@Ingreso=''Traslado'' AND (NULLIF(LTRIM(RTRIM(@Codigo)),'''') IS NULL OR NULLIF(LTRIM(RTRIM(@Centro)),'''') IS NULL))
 THROW 52113,N''Revise los datos del traslado.'',1;
 DECLARE @Familia TABLE(Vinculo nvarchar(20),Nombre nvarchar(200),Direccion nvarchar(300),CentroTrabajo nvarchar(200),Telefono nvarchar(30),Parentesco nvarchar(50));
 INSERT @Familia SELECT J.[key],F.* FROM OPENJSON(@Datos) J
 CROSS APPLY OPENJSON(CASE WHEN J.type=5 THEN J.value ELSE N''{}'' END) WITH(Nombre nvarchar(200),Direccion nvarchar(300),CentroTrabajo nvarchar(200),Telefono nvarchar(30),Parentesco nvarchar(50)) F
 WHERE J.[key] IN (''Padre'',''Madre'',''Otro'') AND J.type=5 AND NULLIF(LTRIM(RTRIM(F.Nombre)),'''') IS NOT NULL;
 DECLARE @TutorNombre nvarchar(200),@Telefono nvarchar(30);
 SELECT @TutorNombre=Nombre,@Telefono=Telefono FROM @Familia WHERE Vinculo=@Tutor;
 IF @TutorNombre IS NULL OR NULLIF(LTRIM(RTRIM(@Telefono)),'''') IS NULL OR (@Tutor=''Otro'' AND NOT EXISTS(SELECT 1 FROM @Familia WHERE Vinculo=''Otro'' AND NULLIF(LTRIM(RTRIM(Parentesco)),'''') IS NOT NULL))
 THROW 52114,N''El tutor requiere nombre, teléfono y parentesco si es un tercero.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Anterior nvarchar(max),@VersionActual binary(8),@VersionEnviada binary(8),@Existe bit=0;
 IF @Version IS NOT NULL
 BEGIN
  SET @VersionEnviada=TRY_CONVERT(binary(8),@Version,1);
  IF DATALENGTH(@Version)<>36 OR LEFT(@Version,2) COLLATE Latin1_General_100_BIN2<>N''0x'' OR @VersionEnviada IS NULL
   THROW 52116,N''La versión del expediente no es válida. Vuelva a abrirlo antes de guardar.'',1;
 END;
 IF @Registro IS NOT NULL
 BEGIN
  SELECT @Existe=1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
  IF @Existe=0 THROW 52115,N''Estudiante inexistente.'',1;
  SELECT @Anterior=FormularioJson,@VersionActual=Version FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro;
  IF (@VersionActual IS NULL AND @VersionEnviada IS NOT NULL)
   OR (@VersionActual IS NOT NULL AND (@VersionEnviada IS NULL OR @VersionActual<>@VersionEnviada))
   THROW 52116,N''La versión del expediente cambió o no se cargó. Vuelva a abrirlo antes de guardar.'',1;
  UPDATE dbo.Estudiantes SET NombreEstudiante=@Nombre,Modalidad=@Modalidad,Grado=@Grado,FechaNacimiento=@Nacimiento,Sexo=@Sexo,Direccion=@Direccion,NombreTutor=@TutorNombre,Telefono=@Telefono WHERE Registro=@Registro;
 END
 ELSE
 BEGIN
  DECLARE @Creado TABLE(Registro nvarchar(10));
  INSERT dbo.Estudiantes(NombreEstudiante,Modalidad,Grado,FechaNacimiento,Sexo,Direccion,NombreTutor,Telefono)
  OUTPUT inserted.Registro INTO @Creado VALUES(@Nombre,@Modalidad,@Grado,@Nacimiento,@Sexo,@Direccion,@TutorNombre,@Telefono);
  SELECT @Registro=Registro FROM @Creado;
 END;
 IF NOT EXISTS(SELECT 1 FROM dbo.ExpedienteAmpliado WHERE Registro=@Registro)
  INSERT dbo.ExpedienteAmpliado(Registro,TipoIngreso,CodigoTraslado) VALUES(@Registro,@Ingreso,@Codigo);
 UPDATE dbo.ExpedienteAmpliado SET Identificacion=JSON_VALUE(@Datos,''$.Identificacion''),TipoSangre=JSON_VALUE(@Datos,''$.TipoSangre''),
 Alergias=JSON_VALUE(@Datos,''$.Alergias''),Padecimientos=JSON_VALUE(@Datos,''$.Padecimientos''),IndicacionesEmergencia=JSON_VALUE(@Datos,''$.IndicacionesEmergencia''),
 TipoIngreso=@Ingreso,CodigoTraslado=CASE WHEN @Ingreso=''Traslado'' THEN @Codigo END,CentroProcedencia=CASE WHEN @Ingreso=''Traslado'' THEN @Centro END,
 FormularioJson=JSON_MODIFY(JSON_MODIFY(@Datos,''$.Registro'',@Registro),''$.Version'',NULL) WHERE Registro=@Registro;
 -- Cambiar responsables conserva las versiones previas, incluso cambios el mismo día.
 IF @Anterior IS NULL OR ISNULL(JSON_QUERY(@Anterior,''$.Padre''),'''')<>ISNULL(JSON_QUERY(@Datos,''$.Padre''),'''')
 OR ISNULL(JSON_QUERY(@Anterior,''$.Madre''),'''')<>ISNULL(JSON_QUERY(@Datos,''$.Madre''),'''')
 OR ISNULL(JSON_QUERY(@Anterior,''$.Otro''),'''')<>ISNULL(JSON_QUERY(@Datos,''$.Otro''),'''')
 OR ISNULL(JSON_VALUE(@Anterior,''$.Tutor''),'''')<>@Tutor
 OR ISNULL(JSON_VALUE(@Anterior,''$.DocumentoTutela''),'''')<>ISNULL(JSON_VALUE(@Datos,''$.DocumentoTutela''),'''')
 BEGIN
  UPDATE T SET Hasta=@Hoy FROM dbo.TutelaEstudiante T JOIN dbo.ResponsableEstudiante R ON R.Id=T.ResponsableId WHERE R.Registro=@Registro AND T.Hasta IS NULL;
  UPDATE dbo.ResponsableEstudiante SET Hasta=@Hoy WHERE Registro=@Registro AND Hasta IS NULL;
  INSERT dbo.ResponsableEstudiante(Registro,Vinculo,Nombre,Direccion,CentroTrabajo,Telefono,Parentesco,Desde)
  SELECT @Registro,Vinculo,Nombre,Direccion,CentroTrabajo,Telefono,Parentesco,@Hoy FROM @Familia;
  INSERT dbo.TutelaEstudiante(ResponsableId,Desde,Motivo,UsuarioId,NombreHistorico,DocumentoReferencia)
  SELECT Id,@Hoy,@Motivo,@UsuarioId,Nombre,JSON_VALUE(@Datos,''$.DocumentoTutela'') FROM dbo.ResponsableEstudiante WHERE Registro=@Registro AND Hasta IS NULL AND Vinculo=@Tutor;
 END;
 INSERT dbo.DocumentoEstudiante(Registro,Tipo,Estado,Fecha,UsuarioId)
 SELECT @Registro,V.Tipo,CASE WHEN JSON_VALUE(@Datos,V.Ruta)=''true'' THEN ''Recibido'' ELSE ''Pendiente'' END,@Hoy,@UsuarioId
 FROM (VALUES(''Partida de nacimiento'',''$.PartidaRecibida''),(''Identificación tutor'',''$.IdentificacionTutorRecibida''),(''Boletín'',''$.BoletinRecibido''),(''Traslado'',''$.TrasladoRecibido'')) V(Tipo,Ruta)
 WHERE @Anterior IS NULL OR ISNULL(JSON_VALUE(@Anterior,V.Ruta),''false'')<>ISNULL(JSON_VALUE(@Datos,V.Ruta),''false'');
 DECLARE @Operacion uniqueidentifier=NEWID();
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''GuardarExpediente'',@Entidad=N''Estudiantes'',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 SELECT @Registro;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Horario_Cancelar · Horario_Cancelar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Horario_Cancelar · Horario_Cancelar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Horario_Cancelar
 @UsuarioId nvarchar(450),@HorarioId int,@Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54201,N''Se requiere administrador.'',1;
 SET @Motivo=NULLIF(LTRIM(RTRIM(@Motivo)),N'''');
 IF @HorarioId IS NULL OR @HorarioId<=0 OR @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>''0x'' OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54202,N''Indica horario, versión, operación y motivo de 10 a 500 caracteres.'',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock int,@Esperada binary(8)=CONVERT(binary(8),@Version,1),@Actual binary(8),@Cerrado bit,@Antes nvarchar(max);
  EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
  IF @Lock<0 THROW 54203,N''Planificación ocupada. Intente nuevamente.'',1;
  IF EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE Operacion=@Operacion AND HorarioId=@HorarioId AND UsuarioId=@UsuarioId AND Motivo COLLATE Latin1_General_100_BIN2=@Motivo COLLATE Latin1_General_100_BIN2 AND VersionHorario=@Esperada)
    THROW 54204,N''La operación ya se utilizó con otros datos.'',1;
   COMMIT;RETURN;
  END;
  SELECT @Actual=H.Version,@Cerrado=P.Cerrado FROM dbo.HorarioClase H WITH(UPDLOCK,HOLDLOCK)
  JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
  JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE H.Id=@HorarioId;
  IF @Actual IS NULL THROW 54205,N''El horario no existe.'',1;
  IF EXISTS(SELECT 1 FROM dbo.CancelacionHorario WHERE HorarioId=@HorarioId) THROW 54206,N''El horario ya fue cancelado. Consulte el historial.'',1;
  IF @Actual<>@Esperada THROW 54207,N''El horario cambió desde que abrió la página. Recargue antes de confirmar.'',1;
  IF @Cerrado=1 THROW 54208,N''El período está cerrado. Su reapertura requiere el proceso académico correspondiente.'',1;
  SELECT @Antes=(SELECT H.Id,H.AsignacionId,D.GrupoId,G.PeriodoId,Y.Anio,P.Nombre Periodo,G.Seccion,
   S.Nombre Asignatura,U.UserName Docente,A.Nombre Aula,H.Dia,H.Inicio,H.Fin
   FROM dbo.HorarioClase H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
   JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId
   JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId JOIN dbo.Aula A ON A.Id=G.AulaId
   WHERE H.Id=@HorarioId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT dbo.CancelacionHorario(HorarioId,Operacion,UsuarioId,Motivo,VersionHorario,Instantanea)
  VALUES(@HorarioId,@Operacion,@UsuarioId,@Motivo,@Actual,@Antes);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),@HorarioId),@Despues nvarchar(max)=(SELECT @HorarioId HorarioId,@Motivo Motivo,N''Cancelado'' Estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Registrar_Auditoria @UsuarioId,N''CancelarHorario'',N''HorarioClase'',@Id,@Operacion,@Antes,@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Notas_Guardar · Notas.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Notas_Guardar · Notas.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Notas_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450),@ResultadoId int=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52400,N''Datos inválidos.'',1;
 DECLARE @Admin bit=0,@Profesor bit=0;
 SELECT @Admin=MAX(CASE WHEN R.Name=''Administrador'' THEN 1 ELSE 0 END),@Profesor=MAX(CASE WHEN R.Name=''Profesor'' THEN 1 ELSE 0 END)
 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId;
 IF ISNULL(@Admin,0)=0 AND ISNULL(@Profesor,0)=0 THROW 52401,N''Acceso académico denegado.'',1;
 DECLARE @Accion nvarchar(20)=JSON_VALUE(@Datos,''$.Accion''),@Asignacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AsignacionId'')),
 @Evaluacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.EvaluacionId'')),@Tipo int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.TipoId'')),
 @Nombre nvarchar(100)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Nombre'')),''''),@Fecha date=TRY_CONVERT(date,JSON_VALUE(@Datos,''$.Fecha'')),
 @Modo nvarchar(20)=JSON_VALUE(@Datos,''$.Modo''),@Maximo decimal(7,2)=TRY_CONVERT(decimal(7,2),JSON_VALUE(@Datos,''$.Maximo'')),
 @Peso decimal(5,2)=TRY_CONVERT(decimal(5,2),JSON_VALUE(@Datos,''$.Peso'')),@Registro nvarchar(10)=JSON_VALUE(@Datos,''$.Registro''),
 @Nota decimal(7,2)=TRY_CONVERT(decimal(7,2),JSON_VALUE(@Datos,''$.Nota'')),@Resultado nvarchar(100)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Resultado'')),''''),
 @Observacion nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Observacion'')),''''),@Version binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,''$.Version''),1),
 @Motivo nvarchar(500)=NULLIF(TRIM(JSON_VALUE(@Datos,''$.Motivo'')),''''),@Grupo int,@Periodo int,@Lock int,@Operacion uniqueidentifier=NEWID();
 IF @Accion IS NULL OR @Accion NOT IN (''Tipo'',''Evaluacion'',''Nota'',''Publicar'') THROW 52400,N''Operación inválida.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Orden único con Planificacion_Guardar: evita inscripción durante publicación.
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52402,N''La planificación está ocupada; vuelve a intentarlo.'',1;
 IF @Accion=''Tipo''
 BEGIN
  IF ISNULL(@Admin,0)=0 THROW 52401,N''Solo administración puede crear tipos.'',1;
  IF @Nombre IS NULL THROW 52400,N''Escribe el nombre del tipo.'',1;
  INSERT dbo.TipoEvaluacion(Nombre) VALUES(@Nombre);
  SET @ResultadoId=CONVERT(int,SCOPE_IDENTITY());
 END
 ELSE
 BEGIN
  SELECT @Grupo=A.GrupoId,@Periodo=G.PeriodoId FROM dbo.AsignacionDocente A JOIN dbo.GrupoAcademico G ON G.Id=A.GrupoId
  WHERE A.Id=@Asignacion AND (@Admin=1 OR A.UsuarioId=@UsuarioId);
  IF @Grupo IS NULL THROW 52401,N''Asignación no disponible para tu cuenta.'',1;
  IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Periodo AND Cerrado=1) THROW 52403,N''El período está cerrado.'',1;
  IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion AND Vigente=1) THROW 52403,N''Las notas ya fueron publicadas; no se pueden modificar.'',1;
  IF @Accion=''Evaluacion''
  BEGIN
   IF @Nombre IS NULL OR @Modo IS NULL OR @Modo NOT IN (''Cuantitativa'',''Cualitativa'') OR NOT EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Id=@Tipo AND Activo=1) THROW 52400,N''Nombre, modalidad o tipo inválido.'',1;
   IF @Fecha IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.PeriodoAcademico WHERE Id=@Periodo AND @Fecha BETWEEN Inicio AND Fin) THROW 52404,N''La fecha debe pertenecer al período.'',1;
   IF @Modo=''Cuantitativa''
   BEGIN
    IF @Maximo IS NULL OR @Maximo<=0 OR @Peso IS NULL OR @Peso<=0 OR @Peso>100 THROW 52405,N''Máximo o peso inválido.'',1;
    IF @Peso+ISNULL((SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo=''Cuantitativa''),0)>100 THROW 52405,N''Los pesos no pueden superar 100 %.'',1;
   END
   ELSE BEGIN SET @Maximo=1;SET @Peso=0;END;
   INSERT dbo.Evaluacion(AsignacionId,TipoId,Nombre,Fecha,Maximo,Peso,Modo) VALUES(@Asignacion,@Tipo,@Nombre,@Fecha,@Maximo,@Peso,@Modo);
   SET @Evaluacion=SCOPE_IDENTITY();
   IF @Modo=''Cualitativa''
   BEGIN
    DECLARE @Opciones nvarchar(max)=JSON_QUERY(@Datos,''$.Valores'');
    IF @Opciones IS NULL OR LEFT(LTRIM(@Opciones),1)<>''['' THROW 52406,N''Define la escala cualitativa.'',1;
    IF (SELECT COUNT(*) FROM OPENJSON(@Opciones)) NOT BETWEEN 2 AND 20 OR EXISTS(SELECT 1 FROM OPENJSON(@Opciones) WHERE type<>1 OR LEN(TRIM(value)) NOT BETWEEN 1 AND 100)
     THROW 52406,N''Define entre 2 y 20 resultados válidos.'',1;
    IF EXISTS(SELECT TRIM(value) FROM OPENJSON(@Opciones) GROUP BY TRIM(value) HAVING COUNT(*)>1) THROW 52406,N''Los resultados de la escala deben ser diferentes.'',1;
    INSERT dbo.OpcionEvaluacion(EvaluacionId,Valor) SELECT @Evaluacion,TRIM(value) FROM OPENJSON(@Opciones);
   END;
  END;
  IF @Accion=''Nota''
  BEGIN
   SET @Modo=NULL;
   DECLARE @VersionEvaluacion binary(8)=TRY_CONVERT(binary(8),JSON_VALUE(@Datos,''$.VersionEvaluacion''),1),@VersionActualEvaluacion binary(8);
   SELECT @Modo=Modo,@Maximo=Maximo,@VersionActualEvaluacion=Version FROM dbo.Evaluacion WHERE Id=@Evaluacion AND AsignacionId=@Asignacion;
   IF @VersionEvaluacion IS NULL OR @VersionActualEvaluacion<>@VersionEvaluacion THROW 52408,N''La definición de la evaluación cambió o falta su versión. Recarga antes de calificar.'',1;
   IF @Modo IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo AND Registro=@Registro) THROW 52401,N''Evaluación o estudiante ajeno al grupo.'',1;
   IF @Modo=''Cuantitativa'' AND (@Resultado IS NOT NULL OR @Nota<0 OR @Nota>@Maximo) THROW 52407,N''La nota debe estar entre cero y el máximo de la evaluación.'',1;
   IF JSON_VALUE(@Datos,''$.Nota'') IS NOT NULL AND @Nota IS NULL THROW 52407,N''Nota numérica inválida.'',1;
   IF @Modo=''Cualitativa'' AND (@Nota IS NOT NULL OR (@Resultado IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.OpcionEvaluacion WHERE EvaluacionId=@Evaluacion AND Valor=@Resultado))) THROW 52407,N''El resultado no pertenece a la escala cualitativa.'',1;
   IF EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro)
   BEGIN
    IF @Version IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro AND Version=@Version) THROW 52408,N''Otra persona modificó esta nota. Recarga antes de guardar.'',1;
    IF @Motivo IS NULL THROW 52400,N''Indica el motivo de la modificación.'',1;
    INSERT dbo.HistorialCalificacion(EvaluacionId,Registro,NotaAnterior,NotaNueva,ResultadoAnterior,ResultadoNuevo,ObservacionAnterior,ObservacionNueva,UsuarioId,Motivo)
     SELECT EvaluacionId,Registro,Nota,@Nota,Resultado,@Resultado,Observacion,@Observacion,@UsuarioId,@Motivo FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro;
    UPDATE dbo.Calificacion SET Nota=@Nota,Resultado=@Resultado,Observacion=@Observacion,UsuarioId=@UsuarioId WHERE EvaluacionId=@Evaluacion AND Registro=@Registro;
   END
   ELSE
   BEGIN
    IF @Version IS NOT NULL THROW 52408,N''La nota cambió. Recarga antes de guardar.'',1;
    INSERT dbo.HistorialCalificacion(EvaluacionId,Registro,NotaNueva,ResultadoNuevo,ObservacionNueva,UsuarioId,Motivo)
     VALUES(@Evaluacion,@Registro,@Nota,@Resultado,@Observacion,@UsuarioId,N''Registro inicial'');
    INSERT dbo.Calificacion(EvaluacionId,Registro,Nota,Resultado,Observacion,UsuarioId) VALUES(@Evaluacion,@Registro,@Nota,@Resultado,@Observacion,@UsuarioId);
   END;
  END;
  IF @Accion=''Publicar''
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion) OR NOT EXISTS(SELECT 1 FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo) THROW 52409,N''Agrega evaluaciones y estudiantes antes de publicar.'',1;
   IF EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo=''Cuantitativa'') AND (SELECT SUM(Peso) FROM dbo.Evaluacion WHERE AsignacionId=@Asignacion AND Modo=''Cuantitativa'')<>100 THROW 52409,N''Los pesos numéricos deben sumar exactamente 100 %.'',1;
   IF EXISTS(SELECT 1 FROM dbo.Evaluacion E CROSS JOIN dbo.GrupoEstudiante G LEFT JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id AND C.Registro=G.Registro
    WHERE E.AsignacionId=@Asignacion AND G.GrupoId=@Grupo AND ((E.Modo=''Cuantitativa'' AND C.Nota IS NULL) OR (E.Modo=''Cualitativa'' AND C.Resultado IS NULL))) THROW 52409,N''Hay resultados pendientes. No se publicaron las notas.'',1;
   IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@Asignacion)
    UPDATE dbo.PublicacionNotas SET Vigente=1,Fecha=SYSUTCDATETIME(),UsuarioId=@UsuarioId WHERE AsignacionId=@Asignacion;
   ELSE INSERT dbo.PublicacionNotas(AsignacionId,UsuarioId) VALUES(@Asignacion,@UsuarioId);
   DECLARE @Foto nvarchar(max)=(SELECT E.Id,E.Nombre,E.Modo,E.Maximo,E.Peso,C.Registro,C.Nota,C.Resultado,C.Observacion FROM dbo.Evaluacion E JOIN dbo.Calificacion C ON C.EvaluacionId=E.Id WHERE E.AsignacionId=@Asignacion FOR JSON PATH,INCLUDE_NULL_VALUES);
   INSERT dbo.EventoAcademico(PeriodoId,AsignacionId,Accion,UsuarioId,Motivo,Instantanea) VALUES(@Periodo,@Asignacion,N''Publicar'',@UsuarioId,N''Publicación de resultados completos'',@Foto);
  END;
 END;
 DECLARE @AccionAudit nvarchar(100)=N''Notas_''+@Accion,@Id nvarchar(100)=CONCAT(@Asignacion,'':'',@Evaluacion,'':'',@Registro);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N''Calificaciones'',@RegistroId=@Id,@IdOperacion=@Operacion;
 COMMIT;
 IF @Accion=''Evaluacion'' SET @ResultadoId=@Evaluacion;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Personal_Guardar · Personal_Guardar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Personal_Guardar · Personal_Guardar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Personal_Guardar
 @UsuarioId nvarchar(450),@CuentaId nvarchar(450),@Version nvarchar(max),
 @Rol nvarchar(max),@Activa bit,@Motivo nvarchar(max),@Operacion uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @CuentaId IS NULL OR @CuentaId=@UsuarioId THROW 54504,N''No puede modificar su propia cuenta.'',1;
 IF @Rol IS NULL OR @Rol COLLATE Latin1_General_100_BIN2 NOT IN(N''Administrador'',N''Profesor'',N''Cajero'') OR DATALENGTH(@Rol)>26 OR DATALENGTH(@Rol)<>DATALENGTH(RTRIM(@Rol))
  OR @Activa IS NULL OR @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
  OR @Version IS NULL OR LEN(@Version)=0 OR DATALENGTH(@Version)>256
  OR @Motivo IS NULL OR LEN(LTRIM(RTRIM(@Motivo)))<10 OR DATALENGTH(@Motivo)>1000
  THROW 54503,N''Datos inválidos; indique rol, versión y motivo de 10 a 500 caracteres.'',1;
 BEGIN TRY
  BEGIN TRANSACTION;
  EXEC dbo.Personal_Autorizar @UsuarioId;
  -- Mismo orden siempre: Personal, Planificacion, filas de Identity.
  DECLARE @Resultado int;
  EXEC @Resultado=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
  IF @Resultado<0 THROW 54502,N''Planificación ocupada; vuelva a intentar.'',1;
  DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@CuentaId CuentaId,@Version Version,@Rol Rol,@Activa Activa,LTRIM(RTRIM(@Motivo)) Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud);
  IF EXISTS(SELECT 1 FROM dbo.HistorialCuentaPersonal WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.HistorialCuentaPersonal WHERE Operacion=@Operacion AND SolicitudHash=@Hash)
    THROW 54505,N''La operación ya fue usada con otros datos.'',1;
   COMMIT; RETURN;
  END;
  DECLARE @VersionActual nvarchar(max),@RolAnterior nvarchar(256),@ActivaAnterior bit;
  SELECT @VersionActual=U.ConcurrencyStamp,@ActivaAnterior=ISNULL(E.Activa,1)
  FROM dbo.AspNetUsers U WITH(UPDLOCK,HOLDLOCK) LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@CuentaId;
  IF @VersionActual IS NULL THROW 54506,N''Cuenta inexistente o sin versión; requiere revisión técnica.'',1;
  IF @VersionActual COLLATE Latin1_General_100_BIN2<>@Version COLLATE Latin1_General_100_BIN2
   THROW 54507,N''La cuenta cambió. Recargue antes de confirmar.'',1;
  IF (SELECT COUNT(*) FROM dbo.AspNetUserRoles WHERE UserId=@CuentaId)<>1
   THROW 54508,N''Esta cuenta no tiene un único rol. Requiere revisión técnica.'',1;
  SELECT @RolAnterior=R.Name FROM dbo.AspNetUserRoles UR JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE UR.UserId=@CuentaId;
  IF @RolAnterior NOT IN(N''Administrador'',N''Profesor'',N''Cajero'') THROW 54508,N''Rol existente no administrable desde esta pantalla.'',1;
  DECLARE @RolId nvarchar(450)=(SELECT Id FROM dbo.AspNetRoles WHERE Name=@Rol);
  IF @RolId IS NULL THROW 54508,N''El rol solicitado no existe.'',1;
  IF @RolAnterior=@Rol AND @ActivaAnterior=@Activa THROW 54509,N''No hay cambios para guardar.'',1;
  IF (@Activa=0 OR @Rol<>N''Profesor'') AND EXISTS(
   SELECT 1 FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
   JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.UsuarioId=@CuentaId AND P.Cerrado=0)
   THROW 54510,N''Reasigne primero las clases de los períodos abiertos de esta cuenta.'',1;
  IF @RolAnterior=N''Administrador'' AND (@Rol<>N''Administrador'' OR @Activa=0) AND NOT EXISTS(
   SELECT 1 FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId
   LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id
   WHERE U.Id<>@CuentaId AND R.Name=N''Administrador'' AND ISNULL(E.Activa,1)=1 AND U.EmailConfirmed=1
   AND U.PasswordHash IS NOT NULL AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()))
   THROW 54511,N''Debe conservar al menos un administrador habilitado con contraseña y correo confirmado.'',1;
  DECLARE @Antes nvarchar(max)=(SELECT @RolAnterior Rol,@ActivaAnterior Activa FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @Despues nvarchar(max)=(SELECT @Rol Rol,@Activa Activa FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  IF @RolAnterior<>@Rol
  BEGIN
   DELETE FROM dbo.AspNetUserRoles WHERE UserId=@CuentaId;
   INSERT dbo.AspNetUserRoles(UserId,RoleId) VALUES(@CuentaId,@RolId);
  END;
  UPDATE dbo.EstadoCuentaPersonal SET Activa=@Activa WHERE UsuarioId=@CuentaId;
  IF @@ROWCOUNT=0 INSERT dbo.EstadoCuentaPersonal(UsuarioId,Activa) VALUES(@CuentaId,@Activa);
  UPDATE dbo.AspNetUsers SET SecurityStamp=CONVERT(nvarchar(36),NEWID()),ConcurrencyStamp=CONVERT(nvarchar(36),NEWID()) WHERE Id=@CuentaId;
  INSERT dbo.HistorialCuentaPersonal(CuentaId,UsuarioId,Operacion,SolicitudHash,Motivo,AntesJson,DespuesJson)
   VALUES(@CuentaId,@UsuarioId,@Operacion,@Hash,LTRIM(RTRIM(@Motivo)),@Antes,@Despues);
  EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''AdministrarCuentaPersonal'',@Entidad=N''AspNetUsers'',@RegistroId=@CuentaId,@IdOperacion=@Operacion,@AntesJson=@Antes,@DespuesJson=@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Planificacion_Cambiar · Planificacion_Cambiar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Planificacion_Cambiar · Planificacion_Cambiar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Planificacion_Cambiar
 @UsuarioId nvarchar(450),@Tipo nvarchar(20),@OrigenId int,@Registro nvarchar(10)=NULL,
 @DocenteId nvarchar(450)=NULL,@GrupoDestino int=NULL,@Version varchar(max)=NULL,
 @Operacion uniqueidentifier=NULL,@Motivo nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 54301,N''Se requiere administrador.'',1;
 SET @Motivo=NULLIF(LTRIM(RTRIM(@Motivo)),N'''');
 IF @Tipo IS NULL OR @Tipo NOT IN (''Docente'',''Estudiante'') OR @OrigenId IS NULL OR @OrigenId<=0
 OR @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Version IS NULL OR LEN(@Version)<>18 OR LEFT(@Version,2)<>''0x'' OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54302,N''Complete la operación, versión y motivo de 10 a 500 caracteres.'',1;
 IF (@Tipo=''Docente'' AND (@DocenteId IS NULL OR @Registro IS NOT NULL OR @GrupoDestino IS NOT NULL))
 OR (@Tipo=''Estudiante'' AND (@Registro IS NULL OR @GrupoDestino IS NULL OR @GrupoDestino<=0 OR @DocenteId IS NOT NULL))
 THROW 54302,N''Datos de destino inválidos.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @Tipo Tipo,@OrigenId OrigenId,@Registro Registro,@DocenteId DocenteId,@GrupoDestino GrupoDestino,CONVERT(varchar(18),CONVERT(binary(8),@Version,1),1) Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Lock int,@Actual binary(8),@Periodo int,@Pensum int,@Cerrado bit,@Antes nvarchar(max),@Despues nvarchar(max);
 BEGIN TRY
  BEGIN TRANSACTION;
  IF @Tipo=''Estudiante''
  BEGIN
   EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
   IF @Lock<0 THROW 54303,N''Finanzas ocupada. Intente nuevamente.'',1;
  END;
  EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
  IF @Lock<0 THROW 54303,N''Planificación ocupada. Intente nuevamente.'',1;
  IF EXISTS(SELECT 1 FROM dbo.CambioPlanificacion WHERE Operacion=@Operacion)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.CambioPlanificacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 54304,N''La operación ya se utilizó con otros datos.'',1;
   COMMIT;RETURN;
  END;
  IF @Tipo=''Docente''
  BEGIN
   DECLARE @AnteriorDocente nvarchar(450);
   SELECT @Actual=D.Version,@AnteriorDocente=D.UsuarioId,@Periodo=G.PeriodoId,@Cerrado=P.Cerrado
   FROM dbo.AsignacionDocente D WITH(UPDLOCK,HOLDLOCK) JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@OrigenId;
   IF @Actual IS NULL THROW 54305,N''La asignación no existe.'',1;
   IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54306,N''La asignación cambió. Recargue antes de confirmar.'',1;
   IF @Cerrado=1 OR EXISTS(SELECT 1 FROM dbo.PublicacionNotas WHERE AsignacionId=@OrigenId) THROW 54307,N''No se permite cambiar docente en períodos cerrados o asignaturas con publicaciones.'',1;
   IF @AnteriorDocente=@DocenteId THROW 54302,N''Seleccione un docente diferente.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE U.Id=@DocenteId AND R.Name=''Profesor'' AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME()) AND U.EmailConfirmed=1 AND NOT EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal E WHERE E.UsuarioId=U.Id AND E.Activa=0)) THROW 54308,N''El destino debe ser una cuenta Profesor habilitada.'',1;
   DECLARE @CruceNuevoDocente nvarchar(1000);
   SELECT TOP(1) @CruceNuevoDocente=CONCAT(CHOOSE(X.Dia,N''lunes'',N''martes'',N''miércoles'',N''jueves'',N''viernes'',N''sábado'',N''domingo''),
       N'' '',CONVERT(char(5),X.Inicio,108),N''–'',CONVERT(char(5),X.Fin,108),N'' · '',S.Nombre,N'' · '',N.Nivel,N'' '',G.Seccion,N'' · '',P.Nombre)
    FROM dbo.HorarioClaseVigente H JOIN dbo.HorarioClaseVigente X
     ON X.AsignacionId<>H.AsignacionId AND X.Dia=H.Dia AND X.Inicio<H.Fin AND H.Inicio<X.Fin
    JOIN dbo.AsignacionDocente D ON D.Id=X.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.Pensum N ON N.Id=G.PensumId
    JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
    JOIN dbo.AsignacionDocente A ON A.Id=H.AsignacionId JOIN dbo.GrupoAcademico GA ON GA.Id=A.GrupoId
    JOIN dbo.PeriodoAcademico O ON O.Id=GA.PeriodoId
    WHERE H.AsignacionId=@OrigenId AND D.UsuarioId=@DocenteId AND P.Inicio<=O.Fin AND O.Inicio<=P.Fin
    ORDER BY X.Dia,X.Inicio,X.Id;
   IF @CruceNuevoDocente IS NOT NULL
   BEGIN
    DECLARE @MensajeCruceDocente nvarchar(2048)=CONCAT(N''No se puede asignar al docente: ya tiene clase el '',@CruceNuevoDocente,N''.'');
    THROW 54309,@MensajeCruceDocente,1;
   END;
   SELECT @Antes=(SELECT D.Id AsignacionId,D.GrupoId,S.Nombre Asignatura,G.Seccion,D.UsuarioId DocenteId,U.UserName Docente,P.Nombre Periodo,Y.Anio
    FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId JOIN dbo.AspNetUsers U ON U.Id=D.UsuarioId
    JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE D.Id=@OrigenId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   UPDATE dbo.AsignacionDocente SET UsuarioId=@DocenteId WHERE Id=@OrigenId;
   -- Invalidar confirmaciones de cancelación abiertas con el docente anterior.
   UPDATE H SET AsignacionId=H.AsignacionId FROM dbo.HorarioClase H WHERE H.AsignacionId=@OrigenId AND NOT EXISTS(SELECT 1 FROM dbo.CancelacionHorario C WHERE C.HorarioId=H.Id);
   SET @Despues=JSON_MODIFY(JSON_MODIFY(@Antes,''$.DocenteId'',@DocenteId),''$.Docente'',(SELECT UserName FROM dbo.AspNetUsers WHERE Id=@DocenteId));
  END
  ELSE
  BEGIN
   SELECT @Actual=E.Version,@Periodo=G.PeriodoId,@Pensum=G.PensumId,@Cerrado=P.Cerrado FROM dbo.GrupoEstudiante E WITH(UPDLOCK,HOLDLOCK)
    JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro;
   IF @Actual IS NULL THROW 54305,N''El estudiante ya no pertenece al grupo de origen.'',1;
   IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54306,N''La inscripción cambió. Recargue antes de confirmar.'',1;
   IF @Cerrado=1 THROW 54307,N''El período está cerrado.'',1;
   IF @GrupoDestino=@OrigenId THROW 54302,N''Seleccione otro grupo.'',1;
   DECLARE @Capacidad int,@Anio int,@Modalidad nvarchar(80),@Nivel nvarchar(50);
   SELECT @Capacidad=A.Capacidad,@Anio=Y.Anio,@Modalidad=M.Nombre,@Nivel=N.Nivel FROM dbo.GrupoAcademico G
    JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=N.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=N.ModalidadId JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico T ON T.Id=G.TurnoId
    WHERE G.Id=@GrupoDestino AND G.PeriodoId=@Periodo AND G.PensumId=@Pensum AND Y.Activo=1 AND M.Activo=1 AND A.Activo=1 AND T.Activo=1;
   IF @Capacidad IS NULL THROW 54310,N''El destino debe tener el mismo pensum y período y catálogos activos.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro AND Estado=''Activo'' AND Modalidad=@Modalidad AND Grado=@Nivel) THROW 54310,N''Revise el estado, modalidad y nivel del expediente.'',1;
   IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
   BEGIN
    IF NOT EXISTS(SELECT 1 FROM dbo.MatriculaAcademica WHERE Registro=@Registro AND Anio=@Anio AND Modalidad=@Modalidad AND Nivel=@Nivel) THROW 54310,N''Falta la matrícula académica compatible del año.'',1;
   END
   ELSE IF NOT EXISTS(SELECT 1 FROM dbo.Matriculas WHERE Registro_Estudiante=@Registro AND Anio=@Anio AND Modalidad=@Modalidad AND Grado=@Nivel) THROW 54310,N''Falta la matrícula histórica compatible del año.'',1;
   IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas P JOIN dbo.AsignacionDocente D ON D.Id=P.AsignacionId WHERE D.GrupoId IN (@OrigenId,@GrupoDestino)) THROW 54307,N''Uno de los grupos tiene publicaciones. Requiere revisión académica; no se trasladará automáticamente.'',1;
   IF EXISTS(SELECT 1 FROM dbo.Calificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId WHERE C.Registro=@Registro AND D.GrupoId IN (@OrigenId,@GrupoDestino))
    OR EXISTS(SELECT 1 FROM dbo.HistorialCalificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId JOIN dbo.AsignacionDocente D ON D.Id=E.AsignacionId WHERE C.Registro=@Registro AND D.GrupoId IN (@OrigenId,@GrupoDestino))
    THROW 54311,N''El estudiante tiene registros de calificaciones en origen o destino. No se moverán ni borrarán sus notas.'',1;
   IF EXISTS(SELECT 1 FROM dbo.GrupoEstudiante E JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId WHERE E.Registro=@Registro AND G.PeriodoId=@Periodo AND E.GrupoId<>@OrigenId) THROW 54310,N''El estudiante ya tiene otra inscripción en este período.'',1;
   IF (SELECT COUNT(*) FROM dbo.GrupoEstudiante WHERE GrupoId=@GrupoDestino)>=@Capacidad THROW 54312,N''El grupo de destino no tiene cupo disponible.'',1;
   SELECT @Antes=(SELECT E.Registro,S.NombreEstudiante,E.GrupoId,G.Seccion,P.Nombre Periodo,Y.Anio FROM dbo.GrupoEstudiante E JOIN dbo.Estudiantes S ON S.Registro=E.Registro
    JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId WHERE E.GrupoId=@OrigenId AND E.Registro=@Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   UPDATE dbo.GrupoEstudiante SET GrupoId=@GrupoDestino WHERE GrupoId=@OrigenId AND Registro=@Registro;
   SET @Despues=JSON_MODIFY(JSON_MODIFY(@Antes,''$.GrupoId'',@GrupoDestino),''$.Seccion'',(SELECT Seccion FROM dbo.GrupoAcademico WHERE Id=@GrupoDestino));
  END;
  INSERT dbo.CambioPlanificacion(Operacion,SolicitudHash,Tipo,OrigenId,UsuarioId,Motivo,AntesJson,DespuesJson) VALUES(@Operacion,@Hash,@Tipo,@OrigenId,@UsuarioId,@Motivo,@Antes,@Despues);
  DECLARE @Id nvarchar(100)=CONVERT(nvarchar(100),SCOPE_IDENTITY()),@Accion nvarchar(50)=CASE WHEN @Tipo=''Docente'' THEN N''ReasignarDocente'' ELSE N''TrasladarEstudiante'' END;
  EXEC dbo.Registrar_Auditoria @UsuarioId,@Accion,N''CambioPlanificacion'',@Id,@Operacion,@Antes,@Despues;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.ReciboMultiple_Anular · AnulacionRecibos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.ReciboMultiple_Anular · AnulacionRecibos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.ReciboMultiple_Anular
 @UsuarioId nvarchar(450),@ReciboId bigint,@Operacion uniqueidentifier,@Motivo nvarchar(500),
 @ReferenciaDevolucion nvarchar(100),@Receptor nvarchar(200),@Confirmado bit
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @@TRANCOUNT<>0 THROW 53700,N''No usar transacción externa.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 53701,N''Solo administración puede anular recibos.'',1;
 IF @Confirmado IS NULL OR @Confirmado<>1 OR @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR NULLIF(LTRIM(RTRIM(@Motivo)),'''') IS NULL OR NULLIF(LTRIM(RTRIM(@ReferenciaDevolucion)),'''') IS NULL OR NULLIF(LTRIM(RTRIM(@Receptor)),'''') IS NULL THROW 53702,N''Confirme la devolución y complete motivo, receptor y referencia documental.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@ReciboId ReciboId,@Motivo Motivo,@ReferenciaDevolucion Referencia,@Receptor Receptor FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@Hash binary(32);
 SET @Hash=HASHBYTES(''SHA2_256'',@Solicitud);
 DECLARE @Id bigint,@Lock int,@Registro nvarchar(10),@Dinero decimal(18,2),@SaldoUsado decimal(18,2),@Total decimal(18,2),@Anticipo decimal(18,2),@Saldo decimal(18,2)=0;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53703,N''Finanzas está ocupado. Reintente la misma operación.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53702,N''El libro nuevo no está habilitado.'',1;
 SELECT @Id=Id FROM dbo.AnulacionRecibo WHERE Operacion=@Operacion;
 IF @Id IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.AnulacionRecibo WHERE Id=@Id AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId) THROW 53702,N''La operación ya se usó con otros datos.'',1;
  COMMIT;SELECT @Id Id;RETURN;
 END;
 SELECT @Registro=Registro,@Dinero=Recibido-Cambio,@SaldoUsado=SaldoAplicado,@Total=TotalAplicado,@Anticipo=Anticipo FROM dbo.ReciboMultiple WITH(UPDLOCK,HOLDLOCK) WHERE Id=@ReciboId;
 IF @Registro IS NULL THROW 53704,N''Recibo inexistente.'',1;
 IF EXISTS(SELECT 1 FROM dbo.AnulacionRecibo WHERE ReciboId=@ReciboId) THROW 53702,N''El recibo ya está anulado. Consulte su historial.'',1;
 IF @Total<>ISNULL((SELECT SUM(Importe) FROM dbo.AplicacionPago WHERE ReciboId=@ReciboId),0) OR @Total+@Anticipo<>@Dinero+@SaldoUsado THROW 53702,N''El recibo presenta un balance inconsistente. Requiere revisión.'',1;
 IF EXISTS(SELECT 1 FROM dbo.AplicacionPago A JOIN dbo.CargoEstudiante C ON C.Id=A.CargoId WHERE A.ReciboId=@ReciboId AND (C.Anulado=1 OR C.Registro<>@Registro)) THROW 53702,N''Un cargo fue anulado o no corresponde al estudiante. Requiere revisión.'',1;
 SELECT @Saldo=Disponible FROM dbo.SaldoFinanciero WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Registro;
 IF @Anticipo>@Saldo THROW 53702,N''No se puede anular el anticipo: el saldo disponible no cubre la devolución.'',1;
 IF @SaldoUsado>0 AND NOT EXISTS(SELECT 1 FROM dbo.SaldoFinanciero WHERE Registro=@Registro) THROW 53702,N''No existe la cuenta de saldo original.'',1;
 IF CONVERT(decimal(19,2),@Saldo)+@SaldoUsado>9999999999999999.99 THROW 53702,N''El saldo resultante excede el límite permitido.'',1;
 INSERT dbo.AnulacionRecibo(ReciboId,Operacion,SolicitudHash,UsuarioId,Motivo,ReferenciaDevolucion,Receptor,DineroDevuelto,SaldoRestituido,SaldoAnterior,SaldoFinal,TotalRevertido,SaldoRetirado)
 VALUES(@ReciboId,@Operacion,@Hash,@UsuarioId,@Motivo,@ReferenciaDevolucion,@Receptor,@Dinero,@SaldoUsado,@Saldo,@Saldo+@SaldoUsado-@Anticipo,@Total+@Anticipo,@Anticipo);
 SET @Id=SCOPE_IDENTITY();
 IF @SaldoUsado>0 OR @Anticipo>0 UPDATE dbo.SaldoFinanciero SET Disponible=Disponible+@SaldoUsado-@Anticipo WHERE Registro=@Registro;
 DECLARE @RegistroId nvarchar(100)=CONVERT(nvarchar(100),@ReciboId),@Json nvarchar(max)=(SELECT @Id AnulacionId,@Dinero DineroDevuelto,@SaldoUsado SaldoRestituido,@Anticipo SaldoRetirado,@Total DeudaReabierta,@Motivo Motivo,@ReferenciaDevolucion ReferenciaDevolucion,@Receptor Receptor FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''AnularRecibo'',''ReciboMultiple'',@RegistroId,@Operacion,NULL,@Json;
 COMMIT;SELECT @Id Id;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.ReciboMultiple_Consultar · CobroMultiple.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.ReciboMultiple_Consultar · CobroMultiple.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.ReciboMultiple_Consultar @UsuarioId nvarchar(450),@Id bigint
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Finanzas_Autorizar @UsuarioId;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Shared'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53503,N''Finanzas está ocupado.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ReciboMultiple WHERE Id=@Id) THROW 53504,N''Recibo inexistente.'',1;
 SELECT R.*,U.UserName Responsable,ISNULL(S.Disponible,0) SaldoDisponibleActual FROM dbo.ReciboMultiple R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId LEFT JOIN dbo.SaldoFinanciero S ON S.Registro=R.Registro WHERE R.Id=@Id;
 SELECT CargoId,DescripcionHistorica,Importe FROM dbo.AplicacionPago WHERE ReciboId=@Id ORDER BY CargoId;
 SELECT X.*,U.UserName Responsable FROM dbo.AnulacionRecibo X JOIN dbo.AspNetUsers U ON U.Id=X.UsuarioId WHERE X.ReciboId=@Id;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Registrar_Comprobante · Registrar_Comprobante.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Registrar_Comprobante · Registrar_Comprobante.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Registrar_Comprobante
    @Registro nvarchar(10),
    @Concepto nvarchar(35),
    @MetodoPago nvarchar(15),
    @Referencia nvarchar(100),
    @Descripcion nvarchar(100),
    @UsuarioId nvarchar(450),
    @IdOperacion uniqueidentifier,
    @Modalidad nvarchar(20),
    @Grado nvarchar(50),
    @DineroRecibido decimal(18,2),
    @SaldoAnterior decimal(18,2),
    @SaldoUtilizado decimal(18,2),
    @DeudaCancelada decimal(18,2),
    @CambioDevuelto decimal(18,2),
    @SaldoFinal decimal(18,2),
    @IdComprobante nvarchar(25) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @IdComprobante = NULL;
    IF DB_NAME() <> N''__LICEO_BASE__''
        THROW 51200, N''Base incorrecta.'', 1;
    IF @@TRANCOUNT = 0 OR XACT_STATE() <> 1
        THROW 51201, N''El comprobante debe formar parte de la transaccion del cobro.'', 1;

    IF @IdOperacion IS NULL OR @UsuarioId IS NULL
        THROW 51202, N''Faltan usuario u operacion.'', 1;
    IF EXISTS (SELECT 1 FROM dbo.Historial_Comprobantes WHERE IdOperacion = @IdOperacion)
        THROW 51203, N''Operacion ya registrada. No repetir el cobro.'', 1;

    IF @DineroRecibido IS NULL OR @SaldoAnterior IS NULL OR @SaldoUtilizado IS NULL
       OR @DeudaCancelada IS NULL OR @CambioDevuelto IS NULL OR @SaldoFinal IS NULL
        THROW 51204, N''Faltan importes del cobro.'', 1;
    IF @DineroRecibido < 0 OR @SaldoAnterior < 0 OR @SaldoUtilizado < 0
       OR @DeudaCancelada < 0 OR @CambioDevuelto < 0 OR @SaldoFinal < 0
       OR @SaldoUtilizado > @SaldoAnterior OR @SaldoUtilizado > @DeudaCancelada
       OR @CambioDevuelto > @DineroRecibido
       OR @DeudaCancelada - @SaldoUtilizado > @DineroRecibido - @CambioDevuelto
       OR @SaldoAnterior + @DineroRecibido <> @DeudaCancelada + @CambioDevuelto + @SaldoFinal
        THROW 51205, N''Los importes no cumplen el balance del cobro.'', 1;
    IF @DineroRecibido = 0 AND @SaldoUtilizado = 0
        THROW 51206, N''No hay dinero ni saldo aplicado.'', 1;

    IF @MetodoPago IS NULL OR @MetodoPago NOT IN (N''Efectivo'', N''Transferencia'', N''Saldo'')
        THROW 51207, N''Metodo de pago invalido.'', 1;
    IF @MetodoPago = N''Transferencia'' AND NULLIF(LTRIM(RTRIM(@Referencia)), N'''') IS NULL
        THROW 51208, N''La transferencia necesita referencia.'', 1;
    IF (@MetodoPago = N''Saldo'' AND (@DineroRecibido <> 0 OR @SaldoUtilizado <= 0))
       OR (@MetodoPago <> N''Saldo'' AND @DineroRecibido <= 0)
        THROW 51209, N''El metodo no coincide con los importes.'', 1;
    IF @Concepto IS NULL OR @Concepto NOT IN (
        N''Matrícula'', N''Mensualidad'', N''Promoción'', N''Mantenimiento'',
        N''Evaluaciones, Boletín y Tarjeta'', N''Uso de Saldo'')
        THROW 51210, N''Concepto invalido.'', 1;
    IF @Modalidad IS NULL OR @Modalidad NOT IN (N''Preescolar'', N''Primaria'', N''Secundaria'')
       OR NULLIF(LTRIM(RTRIM(@Grado)), N'''') IS NULL
        THROW 51211, N''Falta modalidad o grado valido de la operacion.'', 1;

    DECLARE @Nombre nvarchar(100), @UsuarioNombre nvarchar(256);
    SELECT @Nombre = NombreEstudiante FROM dbo.Estudiantes WHERE Registro = @Registro;
    SELECT @UsuarioNombre = UserName FROM dbo.AspNetUsers WHERE Id = @UsuarioId;
    IF @Nombre IS NULL OR @UsuarioNombre IS NULL
        THROW 51212, N''Estudiante o usuario inexistente.'', 1;

    DECLARE @Numero bigint = NEXT VALUE FOR dbo.Secuencia_Comprobantes;
    SET @IdComprobante = N''RC-'' + CONVERT(nvarchar(20), @Numero);
    DECLARE @Fecha datetime = CONVERT(datetime,
        SYSUTCDATETIME() AT TIME ZONE ''UTC''
            AT TIME ZONE ''Central America Standard Time'');

    -- Monto representa ingreso NUEVO NETO para los cobros de este procedimiento.
    INSERT dbo.Pagos (
        Id_Comprobante, Registro_Estudiante, Fecha_Pago, Concepto,
        Monto, Metodo_Pago, Referencia_Transaccion, Descripcion)
    VALUES (
        @IdComprobante, @Registro, @Fecha, @Concepto,
        @DineroRecibido - @CambioDevuelto, @MetodoPago,
        CASE WHEN @MetodoPago = N''Transferencia'' THEN @Referencia ELSE NULL END,
        @Descripcion);

    INSERT dbo.Historial_Comprobantes (
        Id_Comprobante, IdOperacion, UsuarioId, UsuarioNombre,
        NombreEstudiante, Modalidad, Grado, DineroRecibido,
        SaldoAnterior, SaldoUtilizado, DeudaCancelada, CambioDevuelto, SaldoFinal)
    VALUES (
        @IdComprobante, @IdOperacion, @UsuarioId, @UsuarioNombre,
        @Nombre, @Modalidad, @Grado, @DineroRecibido,
        @SaldoAnterior, @SaldoUtilizado, @DeudaCancelada, @CambioDevuelto, @SaldoFinal);

    DECLARE @Despues nvarchar(max) = (
        SELECT @IdComprobante AS IdComprobante, @Registro AS Estudiante,
            @Concepto AS Concepto, @DineroRecibido AS DineroRecibido,
            @SaldoAnterior AS SaldoAnterior, @SaldoUtilizado AS SaldoUtilizado,
            @DeudaCancelada AS DeudaCancelada, @CambioDevuelto AS CambioDevuelto,
            @SaldoFinal AS SaldoFinal
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    EXEC dbo.Registrar_Auditoria
        @UsuarioId = @UsuarioId, @Accion = N''RegistrarCobro'',
        @Entidad = N''Pagos'', @RegistroId = @IdComprobante,
        @IdOperacion = @IdOperacion, @DespuesJson = @Despues;

    -- El llamador actualiza deudas y saldo y hace COMMIT.
    -- No hay COMMIT, ROLLBACK ni SELECT de resultados en este procedimiento.
END;');

-- PROCEDURE dbo.ReporteFinanciero_Consultar · ReporteFinanciero_Consultar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.ReporteFinanciero_Consultar · ReporteFinanciero_Consultar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.ReporteFinanciero_Consultar
 @UsuarioId nvarchar(450),@Desde date,@Hasta date,@Pagina int=1,@Exportar bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @Exportar IS NULL THROW 54002,N''Indica el modo de consulta.'',1;
 IF @Desde IS NULL OR @Hasta IS NULL OR @Desde<''20000101'' OR @Hasta>''99981231'' OR @Hasta<@Desde OR DATEDIFF(day,@Desde,@Hasta)>365 OR @Pagina IS NULL OR @Pagina NOT BETWEEN 1 AND 1000000 THROW 54002,N''Indica un rango de hasta 366 días y página válida.'',1;
 DECLARE @Inicio datetime2=DATEADD(hour,6,CONVERT(datetime2,@Desde)),@Fin datetime2=DATEADD(hour,6,DATEADD(day,1,CONVERT(datetime2,@Hasta))),@Lock int;
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Shared'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54003,N''Finanzas está ocupado. Reintenta la consulta.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 54002,N''El reporte requiere el corte aplicado; no incluye el libro anterior.'',1;
 -- Conservar ambos eventos; una anulación posterior no cambia el ingreso de la fecha original.
 SELECT R.Id ReciboId,R.Numero,R.Registro,R.NombreEstudiante,R.Fecha FechaUTC,CONVERT(nvarchar(12),CASE WHEN R.Anticipo>0 THEN N''Anticipo'' ELSE N''Cobro'' END) Tipo,R.Metodo,R.UsuarioId,
 R.Recibido-R.Cambio Dinero,R.SaldoAplicado Saldo,R.TotalAplicado Aplicado
 INTO #Movimientos FROM dbo.ReciboMultiple R WHERE R.Fecha>=@Inicio AND R.Fecha<@Fin
 UNION ALL
 SELECT R.Id,R.Numero,R.Registro,R.NombreEstudiante,X.Fecha,N''Devolución'',R.Metodo,X.UsuarioId,-X.DineroDevuelto,-X.SaldoRestituido,-(X.TotalRevertido-X.SaldoRetirado)
 FROM dbo.AnulacionRecibo X JOIN dbo.ReciboMultiple R ON R.Id=X.ReciboId WHERE X.Fecha>=@Inicio AND X.Fecha<@Fin;
 COMMIT;
 IF @Exportar=1 AND (SELECT COUNT_BIG(*) FROM #Movimientos)>50000 THROW 54002,N''El rango supera 50000 movimientos. Reduce las fechas para exportar; no se descargaron datos parciales.'',1;
 SELECT COUNT_BIG(*) Movimientos,
 ISNULL(SUM(CASE WHEN Tipo IN (''Cobro'',''Anticipo'') THEN Dinero ELSE 0 END),0) Cobrado,
 -ISNULL(SUM(CASE WHEN Tipo=N''Devolución'' THEN Dinero ELSE 0 END),0) Devuelto,
 ISNULL(SUM(Dinero),0) DineroNeto,ISNULL(SUM(Saldo),0) SaldoNeto,ISNULL(SUM(Aplicado),0) AplicadoNeto FROM #Movimientos;
 SELECT Metodo,ISNULL(SUM(CASE WHEN Tipo IN (''Cobro'',''Anticipo'') THEN Dinero ELSE 0 END),0) Cobrado,
 -ISNULL(SUM(CASE WHEN Tipo=N''Devolución'' THEN Dinero ELSE 0 END),0) Devuelto,SUM(Dinero) DineroNeto,SUM(Saldo) SaldoNeto FROM #Movimientos GROUP BY Metodo ORDER BY Metodo;
 SELECT M.ReciboId,M.Numero,M.Registro,M.NombreEstudiante,DATEADD(hour,-6,M.FechaUTC) FechaLocal,M.Tipo,M.Metodo,U.UserName Responsable,M.Dinero,M.Saldo,M.Aplicado
 FROM #Movimientos M LEFT JOIN dbo.AspNetUsers U ON U.Id=M.UsuarioId ORDER BY M.FechaUTC DESC,M.ReciboId DESC,M.Tipo
 OFFSET (CASE WHEN @Exportar=1 THEN 0 ELSE (@Pagina-1)*100 END) ROWS
 FETCH NEXT (CASE WHEN @Exportar=1 THEN 50000 ELSE 100 END) ROWS ONLY;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Saldo_Consultar · ConciliacionSaldos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Saldo_Consultar · ConciliacionSaldos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Saldo_Consultar @UsuarioId nvarchar(450),@Registro nvarchar(10)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Json nvarchar(max),@Saldo decimal(18,2),@Filas int;
 EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
 SELECT @Registro Registro,@Saldo SaldoFavor,@Filas FilasSaldo,CONVERT(varchar(66),HASHBYTES(''SHA2_256'',@Json),1) Huella,
 ISNULL((SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro),0) RevisionAnterior;
 SELECT P.Id_Comprobante,P.Fecha_Pago,P.Concepto,P.Monto MontoHeredado,H.DineroRecibido,H.CambioDevuelto,H.SaldoAnterior,H.SaldoFinal,
 CASE WHEN H.Id_Comprobante IS NULL THEN N''SIN_HISTORIAL'' WHEN H.SaldoAnterior+H.DineroRecibido<>H.DeudaCancelada+H.CambioDevuelto+H.SaldoFinal OR P.Monto<>H.DineroRecibido-H.CambioDevuelto THEN N''BALANCE_INCONSISTENTE'' ELSE N''BALANCE_CON_HISTORIAL'' END Revision
 FROM dbo.Pagos P LEFT JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante WHERE P.Registro_Estudiante=@Registro ORDER BY P.Fecha_Pago,P.Id_Comprobante;
 SELECT TOP(200) R.Id,R.SaldoObservado,R.Decision,R.Referencia,R.Motivo,U.UserName Responsable,R.Fecha,
 CASE WHEN R.Huella=HASHBYTES(''SHA2_256'',@Json) THEN N''COINCIDE_CON_FUENTE'' ELSE N''FUENTE_CAMBIO'' END EstadoFuente
 FROM dbo.RevisionSaldo R JOIN dbo.AspNetUsers U ON U.Id=R.UsuarioId WHERE R.Registro=@Registro ORDER BY R.Id DESC;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Saldo_Revisar · ConciliacionSaldos.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Saldo_Revisar · ConciliacionSaldos.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Saldo_Revisar @UsuarioId nvarchar(450),@Registro nvarchar(10),@Huella varchar(66),@RevisionAnterior bigint,@Decision nvarchar(20),@Referencia nvarchar(200),@Motivo nvarchar(500)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Decision IS NULL OR @Decision NOT IN (''Aprobado'',''Rechazado'') OR NULLIF(TRIM(@Motivo),'''') IS NULL OR NULLIF(TRIM(@Referencia),'''') IS NULL THROW 53200,N''Decisión, referencia y motivo obligatorios.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Json nvarchar(max),@Saldo decimal(18,2),@Filas int,@Hash binary(32),@Operacion uniqueidentifier=NEWID();
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53202,N''Hay otra operación en curso.'',1;
 EXEC dbo.Saldo_Instantanea @UsuarioId,@Registro,@Json OUTPUT,@Saldo OUTPUT,@Filas OUTPUT;
 SET @Hash=HASHBYTES(''SHA2_256'',@Json);
 IF @Huella IS NULL OR TRY_CONVERT(binary(32),@Huella,1) IS NULL OR @Hash<>TRY_CONVERT(binary(32),@Huella,1) THROW 53203,N''Los saldos o pagos cambiaron. Consulta nuevamente.'',1;
 IF @RevisionAnterior IS NULL OR ISNULL((SELECT MAX(Id) FROM dbo.RevisionSaldo WHERE Registro=@Registro),0)<>@RevisionAnterior THROW 53203,N''Otra persona revisó este saldo. Consulta nuevamente.'',1;
 IF @Decision=''Aprobado'' AND (@Filas>1 OR @Saldo<0) THROW 53204,N''No se aprueban saldos negativos ni duplicados.'',1;
 IF @Decision=''Aprobado'' AND EXISTS(SELECT 1 FROM dbo.Pagos P JOIN dbo.Historial_Comprobantes H ON H.Id_Comprobante=P.Id_Comprobante WHERE P.Registro_Estudiante=@Registro AND (H.SaldoAnterior+H.DineroRecibido<>H.DeudaCancelada+H.CambioDevuelto+H.SaldoFinal OR P.Monto<>H.DineroRecibido-H.CambioDevuelto)) THROW 53204,N''Hay comprobantes con balance inconsistente.'',1;
 INSERT dbo.RevisionSaldo(Registro,SaldoObservado,FilasSaldo,Huella,Instantanea,Decision,Referencia,Motivo,UsuarioId) VALUES(@Registro,@Saldo,@Filas,@Hash,@Json,@Decision,TRIM(@Referencia),TRIM(@Motivo),@UsuarioId);
 DECLARE @Despues nvarchar(max)=(SELECT @Saldo SaldoObservado,@Decision Decision,@Referencia Referencia,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''RevisarSaldo'',@Entidad=N''ConciliacionSaldo'',@RegistroId=@Registro,@IdOperacion=@Operacion,@DespuesJson=@Despues;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.TipoEvaluacion_Guardar · TipoEvaluacion_Guardar.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.TipoEvaluacion_Guardar · TipoEvaluacion_Guardar.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.TipoEvaluacion_Guardar
 @UsuarioId nvarchar(450),@Id int,@Nombre nvarchar(max),@Activo bit,
 @Version varchar(max),@Operacion uniqueidentifier,@Motivo nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SET @Nombre=NULLIF(TRIM(@Nombre),N'''');SET @Motivo=NULLIF(TRIM(@Motivo),N'''');
 IF @Id IS NULL OR @Id<=0 OR @Nombre IS NULL OR LEN(@Nombre)>100 OR @Activo IS NULL
 OR @Motivo IS NULL OR LEN(@Motivo) NOT BETWEEN 10 AND 500
 OR @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000''
 OR @Version IS NULL OR DATALENGTH(@Version)<>18 OR LEFT(@Version,2)<>''0x''
 OR TRY_CONVERT(binary(8),@Version,1) IS NULL
 THROW 54602,N''Revisa nombre, versión, operación y motivo de 10 a 500 caracteres.'',1;
 DECLARE @Solicitud nvarchar(max)=(SELECT @Id Id,@Nombre Nombre,@Activo Activo,@Version Version,@Motivo Motivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @Hash binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Lock int,
 @Actual binary(8),@NombreAnterior nvarchar(100),@ActivoAnterior bit;
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Mismo orden que administración de personal; serializa revocación y autorización.
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Personal'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54603,N''Administración ocupada. Reintenta.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
 WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'')
 OR EXISTS(SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
 THROW 54601,N''Acceso exclusivo de administración activa.'',1;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 54603,N''Planificación ocupada. Reintenta.'',1;
 IF EXISTS(SELECT 1 FROM dbo.HistorialTipoEvaluacion WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.HistorialTipoEvaluacion WHERE Operacion=@Operacion AND SolicitudHash=@Hash AND UsuarioId=@UsuarioId)
   THROW 54604,N''La operación ya se utilizó con otros datos.'',1;
  COMMIT;RETURN;
 END;
 SELECT @Actual=Version,@NombreAnterior=Nombre,@ActivoAnterior=Activo
 FROM dbo.TipoEvaluacion WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id;
 IF @Actual IS NULL THROW 54602,N''El tipo no existe.'',1;
 IF @Actual<>CONVERT(binary(8),@Version,1) THROW 54605,N''Otra persona modificó el tipo. Recarga antes de guardar.'',1;
 -- Comparación binaria: incluso un cambio de mayúsculas altera el nombre histórico.
 IF CONVERT(varbinary(max),@Nombre)<>CONVERT(varbinary(max),@NombreAnterior)
 AND EXISTS(SELECT 1 FROM dbo.Evaluacion WHERE TipoId=@Id)
 THROW 54606,N''El tipo ya tiene evaluaciones: conserva su nombre. Puedes cambiar su estado.'',1;
 IF EXISTS(SELECT 1 FROM dbo.TipoEvaluacion WHERE Nombre=@Nombre AND Id<>@Id)
 THROW 54607,N''Ya existe un tipo con ese nombre.'',1;
 IF CONVERT(varbinary(max),@Nombre)=CONVERT(varbinary(max),@NombreAnterior) AND @Activo=@ActivoAnterior
 THROW 54602,N''No hay cambios para guardar.'',1;
 UPDATE dbo.TipoEvaluacion SET Nombre=@Nombre,Activo=@Activo WHERE Id=@Id;
 INSERT dbo.HistorialTipoEvaluacion(TipoId,Operacion,SolicitudHash,UsuarioId,Motivo,NombreAnterior,NombreNuevo,ActivoAnterior,ActivoNuevo)
 VALUES(@Id,@Operacion,@Hash,@UsuarioId,@Motivo,@NombreAnterior,@Nombre,@ActivoAnterior,@Activo);
 DECLARE @Registro nvarchar(100)=CONVERT(nvarchar(100),@Id);
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=N''TipoEvaluacion_Editar'',
 @Entidad=N''TipoEvaluacion'',@RegistroId=@Registro,@IdOperacion=@Operacion;
 COMMIT;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Cargos_GenerarModalidad · Cargos_GenerarModalidad.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Cargos_GenerarModalidad · Cargos_GenerarModalidad.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Cargos_GenerarModalidad
 @UsuarioId nvarchar(450), @TarifaId int, @VersionTarifa binary(8),
 @Mes int=NULL, @Evento nvarchar(30)=NULL, @Vencimiento date=NULL,
 @Aplicar bit=0, @Huella binary(32)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53600,N''No usar transacción externa.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53603,N''Finanzas está ocupado. Reintenta.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1) THROW 53602,N''El corte financiero debe estar aplicado antes de generar cargos.'',1;
 DECLARE @Arancel int,@AnioId int,@Anio int,@Modalidad nvarchar(80),@Periodicidad nvarchar(10),@Importe decimal(18,2),@Referencia nvarchar(80);
 SELECT @Arancel=A.Id,@AnioId=Y.Id,@Anio=Y.Anio,@Modalidad=M.Nombre,@Periodicidad=F.Periodicidad,@Importe=T.Importe
 FROM dbo.TarifaArancel T WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.Arancel A ON A.Id=T.ArancelId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId
 JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId JOIN dbo.ConfiguracionCargo F ON F.ArancelId=A.Id
 WHERE T.Id=@TarifaId AND T.Version=@VersionTarifa AND T.Activo=1 AND A.Activo=1 AND Y.Activo=1 AND M.Activo=1 AND T.Importe>0;
 IF @Arancel IS NULL THROW 53602,N''La tarifa cambió o ya no está disponible. Vuelve a seleccionarla.'',1;
 IF EXISTS(SELECT 1 FROM dbo.MapaConceptoLegado WHERE ArancelId=@Arancel AND CASE WHEN Origen=''Mensualidades'' THEN ''Mensual'' ELSE ''Anual'' END<>@Periodicidad)
 THROW 53602,N''La periodicidad contradice los conceptos históricos.'',1;
 SET @Evento=NULLIF(UPPER(LTRIM(RTRIM(@Evento))),N'''');
 IF (@Periodicidad=''Mensual'' AND (@Mes IS NULL OR @Mes NOT BETWEEN 1 AND 12 OR @Evento IS NOT NULL))
 OR (@Periodicidad=''Anual'' AND (@Mes IS NOT NULL OR @Evento IS NOT NULL))
 OR (@Periodicidad=''Eventual'' AND (@Mes IS NOT NULL OR @Evento IS NULL OR @Evento COLLATE Latin1_General_100_BIN2 LIKE ''%[^A-Z0-9_-]%''))
 THROW 53602,N''Indica el mes para una tarifa mensual o el código para una eventual. Las anuales no llevan esos datos.'',1;
 IF @Vencimiento IS NOT NULL AND YEAR(@Vencimiento)<>@Anio THROW 53602,N''El vencimiento debe pertenecer al año de la tarifa.'',1;
 SET @Referencia=CASE @Periodicidad WHEN ''Anual'' THEN ''ANUAL'' WHEN ''Mensual'' THEN ''MES:''+RIGHT(''0''+CONVERT(varchar(2),@Mes),2) ELSE ''EVENTO:''+@Evento END;

 DECLARE @Alumnos TABLE(Registro nvarchar(10) PRIMARY KEY, Motivo nvarchar(60) NULL);
 INSERT @Alumnos(Registro,Motivo)
 SELECT E.Registro,CASE
 WHEN EXISTS(SELECT 1 FROM dbo.CargoEstudiante C JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId
  WHERE C.Registro=E.Registro AND T.ArancelId=@Arancel AND T.AnioId=@AnioId AND C.Referencia=@Referencia) THEN N''Cargo ya registrado (incluye anulados)''
 WHEN EXISTS(SELECT 1 FROM dbo.ObligacionMigrada O JOIN dbo.RevisionObligacion R ON R.Id=O.RevisionId
  JOIN dbo.TarifaArancel T ON T.Id=R.TarifaId LEFT JOIN dbo.Mensualidades M ON O.Origen=''Mensualidades'' AND M.Id=O.OrigenId
  WHERE R.Registro=E.Registro AND T.ArancelId=@Arancel AND T.AnioId=@AnioId AND (O.Origen<>''Mensualidades'' OR @Periodicidad<>''Mensual'' OR M.Numero_Mes=@Mes OR M.Id IS NULL))
  THEN N''Obligación histórica''
 END
 FROM dbo.Estudiantes E WITH(HOLDLOCK) WHERE E.Estado=''Activo'' AND E.Modalidad=@Modalidad;

 DECLARE @Lista nvarchar(max)=(SELECT Registro,Motivo FROM @Alumnos ORDER BY Registro FOR JSON PATH,INCLUDE_NULL_VALUES);
 DECLARE @Solicitud nvarchar(max)=(SELECT @UsuarioId UsuarioId,@TarifaId TarifaId,
 CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@Referencia Referencia,@Vencimiento Vencimiento,JSON_QUERY(@Lista) Alumnos
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
 DECLARE @Actual binary(32)=HASHBYTES(''SHA2_256'',@Solicitud),@Cantidad int=(SELECT COUNT(*) FROM @Alumnos WHERE Motivo IS NULL);
 IF @Aplicar=1
 BEGIN
  IF @Huella IS NULL OR @Huella<>@Actual THROW 53602,N''La lista de estudiantes o los cargos cambiaron. Revisa una nueva vista previa antes de confirmar.'',1;
  IF @Cantidad=0 THROW 53602,N''No hay estudiantes pendientes de este cargo.'',1;
  DECLARE @Registro nvarchar(10),@Operacion uniqueidentifier;
  WHILE EXISTS(SELECT 1 FROM @Alumnos WHERE Motivo IS NULL)
  BEGIN
   SELECT @Registro=MIN(Registro) FROM @Alumnos WHERE Motivo IS NULL;
   SET @Operacion=NEWID();
   EXEC dbo.Cargos_Generar @UsuarioId,@Operacion,@Registro,@TarifaId,@VersionTarifa,@Mes,@Evento,@Vencimiento,@PermitirTransaccion=1;
   DELETE FROM @Alumnos WHERE Registro=@Registro;
  END;
  COMMIT;
  SELECT @Cantidad Generados;
  RETURN;
 END;
 COMMIT;
 SELECT @Cantidad Pendientes,(SELECT COUNT(*) FROM @Alumnos WHERE Motivo IS NOT NULL) Omitidos,
  @Importe Importe,@Importe*@Cantidad Total,@Actual Huella;
 SELECT A.Registro,E.NombreEstudiante,A.Motivo FROM @Alumnos A
 JOIN dbo.Estudiantes E ON E.Registro=A.Registro ORDER BY E.NombreEstudiante,A.Registro;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Mensualidades_GenerarLote · Mensualidades_GenerarLote.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Mensualidades_GenerarLote · Mensualidades_GenerarLote.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Mensualidades_GenerarLote
 @UsuarioId nvarchar(450),@Operacion uniqueidentifier,@Registro nvarchar(10),@TarifaId int,@VersionTarifa binary(8),@MesInicial int,@MesFinal int,@DiaVencimiento int
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.Cargos_Autorizar @UsuarioId;
 IF @@TRANCOUNT<>0 THROW 53900,N''No usar transacción externa.'',1;
 IF @Operacion IS NULL OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR @MesInicial IS NULL OR @MesFinal IS NULL OR @DiaVencimiento IS NULL OR @MesInicial NOT BETWEEN 1 AND 12 OR @MesFinal NOT BETWEEN @MesInicial AND 12 OR @DiaVencimiento NOT BETWEEN 1 AND 28 THROW 53902,N''Revise meses y día de vencimiento (1 a 28).'',1;
 DECLARE @Json nvarchar(max)=(SELECT @UsuarioId UsuarioId,@Registro Registro,@TarifaId TarifaId,CONVERT(varchar(18),@VersionTarifa,1) VersionTarifa,@MesInicial MesInicial,@MesFinal MesFinal,@DiaVencimiento DiaVencimiento FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@Hash binary(32),@Lock int,@Anio int;
 SET @Hash=HASHBYTES(''SHA2_256'',@Json);
 BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @Lock=sys.sp_getapplock @Resource=''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 53903,N''Finanzas está ocupado.'',1;
 IF EXISTS(SELECT 1 FROM dbo.LoteMensualidades WHERE Operacion=@Operacion)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.LoteMensualidades WHERE Operacion=@Operacion AND SolicitudHash=@Hash) THROW 53902,N''Esta operación ya se utilizó con otros datos.'',1;
  COMMIT;SELECT Cantidad FROM dbo.LoteMensualidades WHERE Operacion=@Operacion;RETURN;
 END;
 SELECT @Anio=Y.Anio FROM dbo.TarifaArancel T JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
 JOIN dbo.ConfiguracionCargo F ON F.ArancelId=T.ArancelId AND F.Periodicidad=''Mensual''
 JOIN dbo.MatriculaAcademica A ON A.Registro=@Registro AND A.Anio=Y.Anio AND A.Modalidad=M.Nombre WHERE T.Id=@TarifaId;
 IF @Anio IS NULL THROW 53902,N''Requiere matrícula académica del año/modalidad y una tarifa mensual.'',1;
 DECLARE @Mes int=@MesInicial,@OpCargo uniqueidentifier,@Fecha date,@Id nvarchar(100)=CONVERT(nvarchar(100),@Operacion);
 WHILE @Mes<=@MesFinal
 BEGIN
  SET @OpCargo=NEWID();SET @Fecha=DATEFROMPARTS(@Anio,@Mes,@DiaVencimiento);
  EXEC dbo.Cargos_Generar @UsuarioId=@UsuarioId,@Operacion=@OpCargo,@Registro=@Registro,@TarifaId=@TarifaId,@VersionTarifa=@VersionTarifa,@Mes=@Mes,@Vencimiento=@Fecha,@PermitirTransaccion=1;
  SET @Mes+=1;
 END;
 INSERT dbo.LoteMensualidades(Operacion,SolicitudHash,UsuarioId,Registro,Cantidad) VALUES(@Operacion,@Hash,@UsuarioId,@Registro,@MesFinal-@MesInicial+1);
 EXEC dbo.Registrar_Auditoria @UsuarioId,''GenerarMensualidades'',''LoteMensualidades'',@Id,@Operacion,NULL,@Json;
 COMMIT;SELECT @MesFinal-@MesInicial+1 Cantidad;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- PROCEDURE dbo.Pagar_Mensualidad · Mensualidades_Legado.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Pagar_Mensualidad · Mensualidades_Legado.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Pagar_Mensualidad
    @Registro nvarchar(10), @Monto decimal(18,2), @Descripcion nvarchar(100),
    @IntegrarSaldo bit, @Metodo_Pago nvarchar(20), @Referencia nvarchar(100),
    @Anio_Limite int, @Numero_Mes_Limite int, @UsuarioId nvarchar(450),
    @Operacion uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @@TRANCOUNT<>0 THROW 53920,N''Ejecuta el cobro sin transacciones externas.'',1;
    IF @Monto IS NULL OR @Monto<0 OR @IntegrarSaldo IS NULL OR @Operacion IS NULL
       OR @Operacion=''00000000-0000-0000-0000-000000000000'' OR @Anio_Limite IS NULL
       OR @Numero_Mes_Limite IS NULL OR @Anio_Limite NOT BETWEEN 1900 AND 9999
       OR @Numero_Mes_Limite NOT BETWEEN 1 AND 12
       THROW 53920,N''Monto, período u operación inválidos.'',1;
    IF @Monto>0 AND (@Metodo_Pago IS NULL OR @Metodo_Pago NOT IN (N''Efectivo'',N''Transferencia''))
       THROW 53920,N''Método de pago inválido.'',1;
    IF @Monto>0 AND @Metodo_Pago=N''Transferencia'' AND NULLIF(TRIM(@Referencia),N'''') IS NULL
       THROW 53920,N''La transferencia requiere referencia.'',1;
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId
        WHERE U.UserId=@UsuarioId AND R.Name IN (N''Administrador'',N''Cajero''))
       OR EXISTS (SELECT 1 FROM dbo.EstadoCuentaPersonal WHERE UsuarioId=@UsuarioId AND Activa=0)
       THROW 53921,N''Acceso financiero denegado.'',1;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Bloqueo int;
        EXEC @Bloqueo=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',
             @LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
        IF @Bloqueo<0 THROW 53920,N''Hay otra operación financiera en curso.'',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.ControlFinanciero WITH (UPDLOCK,HOLDLOCK) WHERE Id=1 AND Migrado=0)
            THROW 53922,N''El libro anterior está cerrado o no se pudo verificar. Usa Estado de cuenta y cobros.'',1;
        IF EXISTS (SELECT 1 FROM dbo.Historial_Comprobantes WHERE IdOperacion=@Operacion)
            THROW 53923,N''La operación ya se registró. Consulta el comprobante antes de cobrar de nuevo.'',1;

        DECLARE @Modalidad nvarchar(20), @Grado nvarchar(50), @Saldo decimal(18,2)=0;
        SELECT @Modalidad=Modalidad,@Grado=Grado FROM dbo.Estudiantes WITH (UPDLOCK,HOLDLOCK)
        WHERE Registro=@Registro AND Estado=N''Activo'';
        IF @Modalidad IS NULL THROW 53920,N''Selecciona un estudiante activo.'',1;
        SELECT @Saldo=Abono_Disponible FROM dbo.Abonos WITH (UPDLOCK,HOLDLOCK)
        WHERE Registro_Estudiante=@Registro;

        DECLARE @Cuotas TABLE (Id int PRIMARY KEY, Importe decimal(18,2));
        INSERT INTO @Cuotas
        SELECT Id,Costo_Mensualidad
        FROM (
            SELECT Id,Costo_Mensualidad,
                SUM(CONVERT(decimal(38,2),Costo_Mensualidad)) OVER
                    (ORDER BY Anio,Numero_Mes,Id ROWS UNBOUNDED PRECEDING) Acumulado
            FROM dbo.Mensualidades WITH (UPDLOCK,HOLDLOCK)
            WHERE Registro_Estudiante=@Registro AND Estado IN (N''Pendiente'',N''Vencido'')
              AND (Anio<@Anio_Limite OR (Anio=@Anio_Limite AND Numero_Mes<=@Numero_Mes_Limite))
        ) C WHERE Acumulado<=@Monto+@Saldo;

        DECLARE @Deuda decimal(18,2)=(SELECT ISNULL(SUM(Importe),0) FROM @Cuotas);
        IF @Deuda=0 AND (@Monto=0 OR @IntegrarSaldo=0)
            THROW 53920,N''No hay fondos suficientes para una cuota completa dentro del período.'',1;
        DECLARE @Utilizado decimal(18,2)=CASE WHEN @Saldo<@Deuda THEN @Saldo ELSE @Deuda END;
        DECLARE @Cambio decimal(18,2)=CASE WHEN @IntegrarSaldo=1 THEN 0 ELSE @Monto-(@Deuda-@Utilizado) END;
        IF @Monto>0 AND @Metodo_Pago=N''Transferencia'' AND @Cambio>0
            THROW 53920,N''No se devuelve cambio en transferencias. Revisa el monto o integra el sobrante al saldo.'',1;
        DECLARE @Final decimal(18,2)=@Saldo+@Monto-@Deuda-@Cambio;
        DECLARE @Concepto nvarchar(35)=CASE WHEN @Monto=0 THEN N''Uso de Saldo'' ELSE N''Mensualidad'' END;
        DECLARE @Metodo nvarchar(15)=CASE WHEN @Monto=0 THEN N''Saldo'' ELSE @Metodo_Pago END;
        DECLARE @Comprobante nvarchar(25);
        EXEC dbo.Registrar_Comprobante @Registro=@Registro,@Concepto=@Concepto,@MetodoPago=@Metodo,
            @Referencia=@Referencia,@Descripcion=@Descripcion,@UsuarioId=@UsuarioId,@IdOperacion=@Operacion,
            @Modalidad=@Modalidad,@Grado=@Grado,@DineroRecibido=@Monto,@SaldoAnterior=@Saldo,
            @SaldoUtilizado=@Utilizado,@DeudaCancelada=@Deuda,@CambioDevuelto=@Cambio,@SaldoFinal=@Final,
            @IdComprobante=@Comprobante OUTPUT;
        UPDATE M SET Estado=N''Cancelado'',Id_Comprobante=@Comprobante
        FROM dbo.Mensualidades M JOIN @Cuotas C ON C.Id=M.Id;
        UPDATE dbo.Abonos SET Abono_Disponible=@Final WHERE Registro_Estudiante=@Registro;
        IF @@ROWCOUNT=0 INSERT dbo.Abonos(Registro_Estudiante,Abono_Disponible) VALUES(@Registro,@Final);
        COMMIT;
        SELECT @Comprobante IdRecibo,@Comprobante IdComprobante,@Cambio Cambio,@Final SaldoFinal;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;');

-- PROCEDURE dbo.Planificacion_Guardar · Planificacion.sql · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'PROCEDURE dbo.Planificacion_Guardar · Planificacion.sql · lote 1',N'CREATE OR ALTER PROCEDURE dbo.Planificacion_Guardar @Datos nvarchar(max),@UsuarioId nvarchar(450),@ResultadoId int=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF ISJSON(@Datos)<>1 THROW 52300,N''Datos inválidos.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUserRoles U JOIN dbo.AspNetRoles R ON R.Id=U.RoleId WHERE U.UserId=@UsuarioId AND R.Name=''Administrador'') THROW 52301,N''Se requiere administrador.'',1;
 DECLARE @Accion nvarchar(30)=JSON_VALUE(@Datos,''$.Accion''),@Anio int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AnioId'')),
 @Modalidad int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.ModalidadId'')),@Nivel nvarchar(50)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@Datos,''$.Nivel''))),''''),
 @Pensum int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.PensumId'')),@Asignatura int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AsignaturaId'')),
 @Periodo int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.PeriodoId'')),@Turno int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.TurnoId'')),
 @Aula int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AulaId'')),@Seccion nvarchar(30),
 @Grupo int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.GrupoId'')),@Docente nvarchar(450)=JSON_VALUE(@Datos,''$.DocenteId''),
 @Asignacion int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.AsignacionId'')),@Dia int=TRY_CONVERT(int,JSON_VALUE(@Datos,''$.Dia'')),
 @Inicio time=TRY_CONVERT(time,JSON_VALUE(@Datos,''$.Inicio'')),@Fin time=TRY_CONVERT(time,JSON_VALUE(@Datos,''$.Fin'')),
 @Estudiante nvarchar(10)=JSON_VALUE(@Datos,''$.Registro'');
 IF @Accion IS NULL OR @Accion NOT IN (''Pensum'',''Materia'',''Grupo'',''Docente'',''Horario'',''Estudiante'') THROW 52302,N''Operación inválida.'',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int,@Resultado int;
 -- Mantener el orden financiero -> académico, antes de bloquear estudiantes.
 IF @Accion=''Estudiante''
 BEGIN
  EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Finanzas.Configuracion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
  IF @Lock<0 THROW 52303,N''Finanzas ocupada. Intente nuevamente.'',1;
 END;
 EXEC @Lock=sys.sp_getapplock @Resource=N''Liceo.Planificacion'',@LockMode=''Exclusive'',@LockOwner=''Transaction'',@LockTimeout=10000;
 IF @Lock<0 THROW 52303,N''Planificación ocupada. Intente nuevamente.'',1;
 IF @Accion=''Pensum''
 BEGIN
  IF @Nivel IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.AnioLectivo WHERE Id=@Anio AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.ModalidadAcademica WHERE Id=@Modalidad AND Activo=1) THROW 52306,N''Revise año, modalidad y nivel.'',1;
  INSERT dbo.Pensum(AnioId,ModalidadId,Nivel) VALUES(@Anio,@Modalidad,@Nivel);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion=''Materia''
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Pensum P JOIN dbo.AnioLectivo A ON A.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE P.Id=@Pensum AND A.Activo=1 AND M.Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.Asignatura WHERE Id=@Asignatura AND Activo=1) THROW 52306,N''Pensum o asignatura no disponible.'',1;
  IF EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PensumId=@Pensum) THROW 52307,N''El pensum ya tiene grupos. No cambie el plan histórico.'',1;
  INSERT dbo.PensumAsignatura(PensumId,AsignaturaId) VALUES(@Pensum,@Asignatura);SET @Resultado=@Pensum;
 END;
 IF @Accion=''Grupo''
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Pensum P JOIN dbo.PeriodoAcademico T ON T.AnioId=P.AnioId JOIN dbo.AnioLectivo A ON A.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE P.Id=@Pensum AND T.Id=@Periodo AND T.Cerrado=0 AND A.Activo=1 AND M.Activo=1)
  OR NOT EXISTS(SELECT 1 FROM dbo.PensumAsignatura WHERE PensumId=@Pensum)
  OR NOT EXISTS(SELECT 1 FROM dbo.Aula WHERE Id=@Aula AND Activo=1) OR NOT EXISTS(SELECT 1 FROM dbo.TurnoAcademico WHERE Id=@Turno AND Activo=1) THROW 52308,N''Revise período, pensum con materias, turno y aula activos.'',1;
  -- Bajo el bloqueo de planificación, asignar el primer nombre libre del plan y período.
  DECLARE @NumeroGrupo int=1;
  SET @Seccion=N''Grupo 1'';
  WHILE EXISTS(SELECT 1 FROM dbo.GrupoAcademico WHERE PensumId=@Pensum AND PeriodoId=@Periodo AND Seccion=@Seccion)
  BEGIN
   SET @NumeroGrupo+=1;
   SET @Seccion=CONCAT(N''Grupo '',@NumeroGrupo);
  END;
  INSERT dbo.GrupoAcademico(PensumId,PeriodoId,TurnoId,AulaId,Seccion) VALUES(@Pensum,@Periodo,@Turno,@Aula,@Seccion);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion IN (''Docente'',''Estudiante'')
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE G.Id=@Grupo AND P.Cerrado=0) THROW 52309,N''Grupo inexistente o período cerrado.'',1;
 END;
 IF @Accion=''Docente''
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId LEFT JOIN dbo.EstadoCuentaPersonal E ON E.UsuarioId=U.Id WHERE U.Id=@Docente AND R.Name=''Profesor'' AND ISNULL(E.Activa,1)=1 AND U.EmailConfirmed=1 AND (U.LockoutEnabled=0 OR U.LockoutEnd IS NULL OR U.LockoutEnd<=SYSUTCDATETIME())) THROW 52310,N''La cuenta debe ser un Profesor habilitado.'',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.PensumAsignatura P ON P.PensumId=G.PensumId JOIN dbo.Asignatura A ON A.Id=P.AsignaturaId WHERE G.Id=@Grupo AND P.AsignaturaId=@Asignatura AND A.Activo=1) THROW 52311,N''La asignatura no pertenece al pensum del grupo.'',1;
  INSERT dbo.AsignacionDocente(GrupoId,AsignaturaId,UsuarioId) VALUES(@Grupo,@Asignatura,@Docente);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion=''Horario''
 BEGIN
  DECLARE @Desde date,@Hasta date,
   @HorarioAnterior int=ISNULL(TRY_CONVERT(int,JSON_VALUE(@Datos,''$.HorarioId'')),0),
   @VersionHorario varchar(max)=JSON_VALUE(@Datos,''$.VersionHorario''),
   @MotivoHorario nvarchar(max)=JSON_VALUE(@Datos,''$.MotivoHorario'');
  IF @HorarioAnterior<0 OR (@HorarioAnterior>0 AND NOT EXISTS(
   SELECT 1 FROM dbo.HorarioClaseVigente WHERE Id=@HorarioAnterior AND AsignacionId=@Asignacion
  )) THROW 52312,N''El bloque ya no está vigente o no corresponde a esta clase. Recarga el horario.'',1;
  SELECT @Grupo=G.Id,@Aula=G.AulaId,@Docente=D.UsuarioId,@Desde=P.Inicio,@Hasta=P.Fin FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Asignacion AND P.Cerrado=0;
  IF @Desde IS NULL OR @Dia IS NULL OR @Dia NOT BETWEEN 1 AND 7 OR @Inicio IS NULL OR @Fin IS NULL OR @Fin<=@Inicio THROW 52312,N''Asignación u horario inválido.'',1;
  DECLARE @CruceDocenteHorario nvarchar(1000);
  SELECT TOP(1) @CruceDocenteHorario=CONCAT(CHOOSE(X.Dia,N''lunes'',N''martes'',N''miércoles'',N''jueves'',N''viernes'',N''sábado'',N''domingo''),
       N'' '',CONVERT(char(5),X.Inicio,108),N''–'',CONVERT(char(5),X.Fin,108),N'' · '',S.Nombre,N'' · '',N.Nivel,N'' '',G.Seccion,N'' · '',P.Nombre)
   FROM dbo.HorarioClaseVigente X JOIN dbo.AsignacionDocente D ON D.Id=X.AsignacionId
   JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId
   JOIN dbo.Pensum N ON N.Id=G.PensumId JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
   WHERE D.UsuarioId=@Docente AND X.Id<>@HorarioAnterior AND X.Dia=@Dia
    AND X.Inicio<@Fin AND @Inicio<X.Fin AND P.Inicio<=@Hasta AND @Desde<=P.Fin
   ORDER BY X.Inicio,X.Id;
  IF @CruceDocenteHorario IS NOT NULL
  BEGIN
   DECLARE @MensajeCruceHorario nvarchar(2048)=CONCAT(N''El docente no está disponible: ya tiene clase el '',@CruceDocenteHorario,N''.'');
   THROW 52313,@MensajeCruceHorario,1;
  END;
  IF EXISTS(SELECT 1 FROM dbo.HorarioClaseVigente H JOIN dbo.AsignacionDocente D ON D.Id=H.AsignacionId JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId
   WHERE H.Id<>@HorarioAnterior AND H.Dia=@Dia AND H.Inicio<@Fin AND @Inicio<H.Fin AND P.Inicio<=@Hasta AND @Desde<=P.Fin AND (G.Id=@Grupo OR G.AulaId=@Aula)) THROW 52313,N''El horario se cruza con otra clase del aula o grupo.'',1;
  -- La cancelación y el bloque nuevo comparten transacción y bloqueo.
  IF @HorarioAnterior>0
  BEGIN
   DECLARE @OperacionCambioHorario uniqueidentifier=NEWID();
   EXEC dbo.Horario_Cancelar @UsuarioId,@HorarioAnterior,@VersionHorario,@OperacionCambioHorario,@MotivoHorario;
  END;
  INSERT dbo.HorarioClase(AsignacionId,Dia,Inicio,Fin) VALUES(@Asignacion,@Dia,@Inicio,@Fin);SET @Resultado=CONVERT(int,SCOPE_IDENTITY());
 END;
 IF @Accion=''Estudiante''
 BEGIN
  IF EXISTS(SELECT 1 FROM dbo.PeriodoAcademico P JOIN dbo.GrupoAcademico G ON G.PeriodoId=P.Id WHERE G.Id=@Grupo AND P.Cerrado=1) THROW 52316,N''El período está cerrado.'',1;
  IF EXISTS(SELECT 1 FROM dbo.PublicacionNotas N JOIN dbo.AsignacionDocente A ON A.Id=N.AsignacionId WHERE A.GrupoId=@Grupo) THROW 52316,N''El grupo ya tiene notas publicadas; no se pueden incorporar estudiantes.'',1;
  -- Bloqueo compartido con el contrato financiero por estudiante.
  DECLARE @Estado nvarchar(10),@Capacidad int,@AnioNumero int,@ModalidadNombre nvarchar(80);
  SELECT @Estado=Estado FROM dbo.Estudiantes WITH(UPDLOCK,HOLDLOCK) WHERE Registro=@Estudiante;
  SELECT @Capacidad=A.Capacidad,@AnioNumero=Y.Anio,@ModalidadNombre=M.Nombre,@Nivel=P.Nivel,@Periodo=G.PeriodoId FROM dbo.GrupoAcademico G JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId WHERE G.Id=@Grupo;
  IF @Estado IS NULL OR @Estado<>''Activo'' OR @Capacidad IS NULL THROW 52314,N''Estudiante o grupo inválido.'',1;
  IF EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.GrupoAcademico G JOIN dbo.Pensum P ON P.Id=G.PensumId JOIN dbo.AnioLectivo Y ON Y.Id=P.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=P.ModalidadId JOIN dbo.Aula A ON A.Id=G.AulaId JOIN dbo.TurnoAcademico T ON T.Id=G.TurnoId WHERE G.Id=@Grupo AND Y.Activo=1 AND M.Activo=1 AND A.Activo=1 AND T.Activo=1) THROW 52314,N''El grupo requiere catálogos activos.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.Estudiantes WHERE Registro=@Estudiante AND Modalidad=@ModalidadNombre AND Grado=@Nivel) THROW 52314,N''El expediente debe coincidir con modalidad y nivel del grupo.'',1;
   IF EXISTS(SELECT 1 FROM dbo.MatriculaAcademica WHERE Registro=@Estudiante AND Anio=@AnioNumero AND (Modalidad<>@ModalidadNombre OR Nivel<>@Nivel)) THROW 52314,N''Existe matrícula del año con otro nivel/modalidad. Requiere revisión, no una segunda matrícula.'',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.MatriculaAcademica WHERE Registro=@Estudiante AND Anio=@AnioNumero)
   BEGIN
    DECLARE @CargoMatricula bigint,@MatriculaLegada int,@CantidadCargos int;
    SELECT @MatriculaLegada=MIN(Id) FROM dbo.Matriculas WHERE Registro_Estudiante=@Estudiante AND Anio=@AnioNumero AND Modalidad=@ModalidadNombre AND Grado=@Nivel;
    IF @MatriculaLegada IS NULL
    BEGIN
     SELECT @CantidadCargos=COUNT(*),@CargoMatricula=MIN(C.Id)
     FROM dbo.CargoEstudiante C JOIN dbo.TarifaArancel T ON T.Id=C.TarifaId JOIN dbo.AnioLectivo Y ON Y.Id=T.AnioId JOIN dbo.ModalidadAcademica M ON M.Id=T.ModalidadId
     JOIN dbo.ConfiguracionMatricula L ON L.ArancelId=T.ArancelId AND L.Id=1
     JOIN dbo.ConfiguracionCargo F ON F.ArancelId=T.ArancelId AND F.Periodicidad=''Anual''
     WHERE C.Registro=@Estudiante AND C.Anulado=0 AND C.Referencia=''ANUAL'' AND Y.Anio=@AnioNumero AND M.Nombre=@ModalidadNombre;
     IF @CantidadCargos<>1 THROW 52314,N''Genera primero un único cargo anual de matrícula para el estudiante, año y modalidad. Revisa ConfiguracionMatricula.'',1;
    END;
    INSERT dbo.MatriculaAcademica(Registro,Anio,Modalidad,Nivel,CargoId,MatriculaLegadaId,UsuarioId)
    VALUES(@Estudiante,@AnioNumero,@ModalidadNombre,@Nivel,@CargoMatricula,@MatriculaLegada,@UsuarioId);
    DECLARE @MatriculaId nvarchar(100)=CONVERT(nvarchar(100),SCOPE_IDENTITY()),@OperacionMatricula uniqueidentifier=NEWID(),@JsonMatricula nvarchar(max)=(SELECT @Estudiante Registro,@AnioNumero Anio,@ModalidadNombre Modalidad,@Nivel Nivel,@CargoMatricula CargoId,@MatriculaLegada MatriculaLegadaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
    EXEC dbo.Registrar_Auditoria @UsuarioId,''MatricularAcademicamente'',''MatriculaAcademica'',@MatriculaId,@OperacionMatricula,NULL,@JsonMatricula;
   END;
  END
  ELSE IF NOT EXISTS(SELECT 1 FROM dbo.Matriculas WHERE Registro_Estudiante=@Estudiante AND Anio=@AnioNumero AND Modalidad=@ModalidadNombre AND Grado=@Nivel) THROW 52314,N''El estudiante requiere matrícula vigente del mismo año, modalidad y nivel.'',1;
  IF EXISTS(SELECT 1 FROM dbo.GrupoEstudiante E JOIN dbo.GrupoAcademico G ON G.Id=E.GrupoId WHERE E.Registro=@Estudiante AND G.PeriodoId=@Periodo) THROW 52315,N''El estudiante ya pertenece a un grupo en este período.'',1;
  IF (SELECT COUNT(*) FROM dbo.GrupoEstudiante WHERE GrupoId=@Grupo)>=@Capacidad THROW 52316,N''El aula alcanzó su capacidad.'',1;
  INSERT dbo.GrupoEstudiante(GrupoId,Registro) VALUES(@Grupo,@Estudiante);SET @Resultado=@Grupo;
 END;
 DECLARE @Operacion uniqueidentifier=NEWID(),@RegistroId nvarchar(100)=CONVERT(nvarchar(100),@Resultado),@AccionAudit nvarchar(50)=N''Planificar''+@Accion;
 EXEC dbo.Registrar_Auditoria @UsuarioId=@UsuarioId,@Accion=@AccionAudit,@Entidad=N''Planificacion'',@RegistroId=@RegistroId,@IdOperacion=@Operacion;
 COMMIT;
 SET @ResultadoId=@Resultado;
 END TRY
 BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
 END CATCH;
END;');

-- Roles Identity · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Roles Identity · lote 1',N'INSERT dbo.AspNetRoles(Id,Name,NormalizedName,ConcurrencyStamp)
        SELECT CONVERT(nvarchar(450),NEWID()),Nombre,UPPER(Nombre),CONVERT(nvarchar(36),NEWID())
        FROM (VALUES(N''Administrador''),(N''Cajero''),(N''Profesor'')) R(Nombre);');

-- Demostración · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Demostración · lote 1',N'-- Solo para una instalación NUEVA de demostración; no ejecutar sobre datos reales.
-- Cuentas solicitadas: camilo@liceo.test / profesor@liceo.test / cajero@liceo.test.
-- Contraseña de demostración: Admin1234#. Se almacenan hashes Identity V3, no texto plano.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS(SELECT 1 FROM dbo.AspNetUsers) OR EXISTS(SELECT 1 FROM dbo.Estudiantes)
 THROW 54902,N''La demostración requiere usuarios y estudiantes vacíos.'',1;
BEGIN TRANSACTION;
DECLARE @Cuentas TABLE(Id nvarchar(450),Correo nvarchar(256),Rol nvarchar(256),Hash nvarchar(max));
INSERT @Cuentas VALUES
(N''demo-administrador'',N''camilo@liceo.test'',N''Administrador'',N''AQAAAAIAAYagAAAAEFkG+aS+bZ1TffK01csIU28xixNNSkVFTzqSLsE+y/d7wQz5an9rqpnkBipjtRZa2A==''),
(N''demo-profesor'',N''profesor@liceo.test'',N''Profesor'',N''AQAAAAIAAYagAAAAEL+ZK6jIO3tJiGaFkCCSq7AO15k5uJQsqYzC0ZGhgOzIp7z1Fbnx8fPUNv1ORGOgmw==''),
(N''demo-cajero'',N''cajero@liceo.test'',N''Cajero'',N''AQAAAAIAAYagAAAAEHyfHdOhZ716ymIFbY3ofF0Hmvz6XZXjfpaZZmoMUUFMEqkVu63vA/UmmSeqCrCB0Q=='');
INSERT dbo.AspNetUsers(Id,UserName,NormalizedUserName,Email,NormalizedEmail,EmailConfirmed,
 PasswordHash,SecurityStamp,ConcurrencyStamp,PhoneNumberConfirmed,TwoFactorEnabled,LockoutEnabled,AccessFailedCount)
SELECT Id,Correo,UPPER(Correo),Correo,UPPER(Correo),1,Hash,CONVERT(nvarchar(36),NEWID()),
 CONVERT(nvarchar(36),NEWID()),0,0,1,0 FROM @Cuentas;
INSERT dbo.AspNetUserRoles(UserId,RoleId)
 SELECT C.Id,R.Id FROM @Cuentas C JOIN dbo.AspNetRoles R ON R.Name=C.Rol;
INSERT dbo.EstadoCuentaPersonal(UsuarioId,Activa) SELECT Id,1 FROM @Cuentas;
DECLARE @Op uniqueidentifier=NEWID();
EXEC dbo.Registrar_Auditoria N''demo-administrador'',N''InicializarDemo'',N''Identity'',N''cuentas-demo'',@Op;
COMMIT;');

-- Demostración · lote 2
INSERT @Etapas(Nombre,Texto) VALUES(N'Demostración · lote 2',N'-- Esto activa el libro nuevo sin migrar ni reinterpretar pagos de otra instalación.
DECLARE @Corte uniqueidentifier=NEWID();
EXEC dbo.CorteFinanciero_Ejecutar
 @UsuarioId=N''demo-administrador'',@Operacion=@Corte,@Aplicar=1,
 @Confirmacion=N''APLICAR CORTE EN DESARROLLO'';
IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N''No se activó el libro nuevo. No se continuará con los datos demo.'',1;');

-- Demostración · lote 3
INSERT @Etapas(Nombre,Texto) VALUES(N'Demostración · lote 3',N'DECLARE @Admin nvarchar(450)=N''demo-administrador'',@Profesor nvarchar(450)=N''demo-profesor'',
 @Cajero nvarchar(450)=N''demo-cajero'',@Anio int=YEAR(SYSUTCDATETIME()),
 @AnioId int,@Periodo int,@Turno int,@Matricula int,@Mensualidad int,@Bus int;
INSERT dbo.AnioLectivo(Anio) VALUES(@Anio); SET @AnioId=SCOPE_IDENTITY();
INSERT dbo.PeriodoAcademico(AnioId,Nombre,Inicio,Fin)
 VALUES(@AnioId,N''Período de demostración'',DATEFROMPARTS(@Anio,1,1),DATEFROMPARTS(@Anio,12,31));
SET @Periodo=SCOPE_IDENTITY();
INSERT dbo.TurnoAcademico(Nombre) VALUES(N''Matutino'');SET @Turno=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N''MAT'',N''Matrícula'');SET @Matricula=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N''MEN'',N''Mensualidad'');SET @Mensualidad=SCOPE_IDENTITY();
INSERT dbo.Arancel(Codigo,Nombre) VALUES(N''BUS'',N''Transporte escolar'');SET @Bus=SCOPE_IDENTITY();
EXEC dbo.Cargos_Configurar @Admin,@Matricula,N''Anual'';
EXEC dbo.Cargos_Configurar @Admin,@Mensualidad,N''Mensual'';
EXEC dbo.Cargos_Configurar @Admin,@Bus,N''Mensual'';
EXEC dbo.Cargos_ConfigurarMatricula @Admin,@Matricula;

DECLARE @Niveles TABLE(N int PRIMARY KEY,Modalidad nvarchar(80),Grado nvarchar(50),Precio decimal(18,2),Nacimiento int);
INSERT @Niveles VALUES(1,N''Preescolar'',N''I Nivel'',350,4),(2,N''Primaria'',N''1er Grado'',500,6),(3,N''Secundaria'',N''7mo Grado'',650,12);
DECLARE @n int=1,@i int,@Modalidad nvarchar(80),@Grado nvarchar(50),@Precio decimal(18,2),@Edad int,
 @Mod int,@Aula int,@Plan int,@Grupo int,@Materia int,@Asignacion int,@TarifaMat int,@TarifaMen int,
 @VMat binary(8),@VMen binary(8),@Cargo bigint,@Registro nvarchar(10),@Json nvarchar(max),@Op uniqueidentifier,
 @Aplicaciones nvarchar(max),@Recibido decimal(28,8),@Nombre nvarchar(100),@Familia nvarchar(100);
DECLARE @Salida TABLE(Registro nvarchar(10));
DECLARE @Alumnos TABLE(N int,I int,Registro nvarchar(10),GrupoId int);
DECLARE @Clases TABLE(N int,Orden int,AsignacionId int);
WHILE @n<=3
BEGIN
 SELECT @Modalidad=Modalidad,@Grado=Grado,@Precio=Precio,@Edad=Nacimiento FROM @Niveles WHERE N=@n;
 INSERT dbo.ModalidadAcademica(Nombre) VALUES(@Modalidad); SET @Mod=SCOPE_IDENTITY();
 INSERT dbo.Aula(Nombre,Ubicacion,Capacidad) VALUES(CONCAT(N''Aula demo '',@n),N''Planta baja · demostración'',25); SET @Aula=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Matricula,@Mod,@AnioId,450); SET @TarifaMat=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Mensualidad,@Mod,@AnioId,@Precio); SET @TarifaMen=SCOPE_IDENTITY();
 INSERT dbo.TarifaArancel(ArancelId,ModalidadId,AnioId,Importe) VALUES(@Bus,@Mod,@AnioId,150);
 SELECT @VMat=Version FROM dbo.TarifaArancel WHERE Id=@TarifaMat;
 SELECT @VMen=Version FROM dbo.TarifaArancel WHERE Id=@TarifaMen;
 SET @Json=(SELECT N''Pensum'' Accion,@AnioId AnioId,@Mod ModalidadId,@Grado Nivel FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Plan OUTPUT;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SET @Nombre=CASE WHEN @n=1 THEN CASE @i WHEN 1 THEN N''Comunicación y lenguaje'' ELSE N''Expresión y creatividad'' END
   ELSE CASE @i WHEN 1 THEN N''Matemáticas'' ELSE N''Lengua y literatura'' END END;
  -- Una asignatura por código de nivel mantiene la demostración simple y visible.
  INSERT dbo.Asignatura(Codigo,Nombre) VALUES(CONCAT(N''DEMO-'',@n,N''-'',@i),@Nombre); SET @Materia=SCOPE_IDENTITY();
  SET @Json=(SELECT N''Materia'' Accion,@Plan PensumId,@Materia AsignaturaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Planificacion_Guardar @Json,@Admin;
  SET @i+=1;
 END;
 SET @Json=(SELECT N''Grupo'' Accion,@Plan PensumId,@Periodo PeriodoId,@Turno TurnoId,@Aula AulaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Grupo OUTPUT;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SELECT @Materia=Id FROM dbo.Asignatura WHERE Codigo=CONCAT(N''DEMO-'',@n,N''-'',@i);
  SET @Json=(SELECT N''Docente'' Accion,@Grupo GrupoId,@Materia AsignaturaId,@Profesor DocenteId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC dbo.Planificacion_Guardar @Json,@Admin,@ResultadoId=@Asignacion OUTPUT;
  INSERT @Clases VALUES(@n,@i,@Asignacion);
  DECLARE @Dia int=1,@Inicio time,@Fin time;
  SET @Inicio=CONVERT(time,DATEADD(minute,(@n-1)*100+(@i-1)*40,CONVERT(datetime,''19000101 07:00'')));
  SET @Fin=CONVERT(time,DATEADD(minute,40,CONVERT(datetime,@Inicio)));
  WHILE @Dia<=CASE @n WHEN 1 THEN 2 WHEN 2 THEN 5 ELSE 3 END
  BEGIN
   SET @Json=(SELECT N''Horario'' Accion,@Asignacion AsignacionId,@Dia Dia,@Inicio Inicio,@Fin Fin FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
   SET @Dia+=1;
  END;
  SET @i+=1;
 END;

 SET @i=1;
 WHILE @i<=4
 BEGIN
  SET @Nombre=CONCAT(N''Demo '',@Modalidad,N'' '',CHOOSE(@i,N''Ana López'',N''Luis Rivera'',N''Sofía Castro'',N''Diego Torres''));
  SET @Familia=CONCAT(N''Responsable ficticio '',@n,N''-'',@i);
  SET @Json=(SELECT @Nombre NombreEstudiante,@Modalidad Modalidad,@Grado Grado,
   DATEFROMPARTS(@Anio-@Edad,1,15) FechaNacimiento,
   CASE WHEN @i IN (1,3) THEN N''F'' ELSE N''M'' END Sexo,N''Dirección ficticia · demostración'' Direccion,
   N''Nuevo'' TipoIngreso,N''Madre'' Tutor,N''Alta de datos ficticios para presentación'' Motivo,
   JSON_QUERY((SELECT @Familia Nombre,N''00000000'' Telefono,N''Contacto ficticio'' Direccion FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Madre,
   JSON_QUERY((SELECT N''Padre ficticio'' Nombre,N''00000000'' Telefono FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) Padre,
   N''No reportadas (dato ficticio)'' Alergias,CAST(1 AS bit) PartidaRecibida,CAST(1 AS bit) IdentificacionTutorRecibida
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DELETE @Salida; INSERT @Salida EXEC dbo.Expediente_Guardar @Json,@Admin;
  SELECT @Registro=Registro FROM @Salida;
  INSERT @Alumnos VALUES(@n,@i,@Registro,@Grupo);
  SET @Op=NEWID();
  EXEC dbo.Cargos_Generar @Admin,@Op,@Registro,@TarifaMat,@VMat;
  SELECT @Cargo=Id FROM dbo.CargoEstudiante WHERE Registro=@Registro AND TarifaId=@TarifaMat AND Referencia=N''ANUAL'';
  SET @Aplicaciones=(SELECT @Cargo CargoId,CAST(450 AS decimal(18,2)) Importe FOR JSON PATH);
  SET @Op=NEWID();
  EXEC dbo.CobroMultiple_Registrar @Cajero,@Op,@Registro,@Familia,N''Efectivo'',NULL,450,0,@Aplicaciones;
  -- El cuarto alumno queda listo para inscribir durante la presentación.
  IF @i<=3
  BEGIN
   SET @Json=(SELECT N''Estudiante'' Accion,@Grupo GrupoId,@Registro Registro FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Planificacion_Guardar @Json,@Admin;
  END;
  SET @Op=NEWID();
  DECLARE @Mes int=MONTH(SYSUTCDATETIME());
  EXEC dbo.Cargos_Generar @Admin,@Op,@Registro,@TarifaMen,@VMen,@Mes;
  SELECT @Cargo=Id FROM dbo.CargoEstudiante WHERE Registro=@Registro AND TarifaId=@TarifaMen;
  IF @i<=2
  BEGIN
   SET @Recibido=CASE WHEN @i=1 THEN @Precio ELSE @Precio/2 END;
   SET @Aplicaciones=(SELECT @Cargo CargoId,@Recibido Importe FOR JSON PATH);
   SET @Op=NEWID();
   EXEC dbo.CobroMultiple_Registrar @Cajero,@Op,@Registro,@Familia,N''Efectivo'',NULL,@Recibido,0,@Aplicaciones;
  END;
  IF @i=3
  BEGIN
   SET @Op=NEWID();
   EXEC dbo.Anticipo_Registrar @Cajero,@Op,@Registro,@Familia,N''Efectivo'',NULL,150;
  END;
  SET @i+=1;
 END;
 SET @n+=1;
END;


IF (SELECT COUNT(*) FROM dbo.Estudiantes)<>12 OR (SELECT COUNT(*) FROM dbo.GrupoEstudiante)<>9
 OR (SELECT COUNT(*) FROM dbo.AspNetUsers)<>3 OR NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N''La demostración base no terminó correctamente.'',1;
IF (SELECT COUNT(*) FROM dbo.CargoEstudiante)<>24
 OR (SELECT COUNT(*) FROM dbo.ReciboMultiple)<>21
 OR (SELECT COUNT(*) FROM dbo.HorarioClaseVigente)<>20
 OR (SELECT SUM(Disponible) FROM dbo.SaldoFinanciero)<>450
 OR NOT EXISTS(SELECT 1 FROM dbo.ConfiguracionMatricula C JOIN dbo.Arancel A ON A.Id=C.ArancelId WHERE C.Id=1 AND A.Codigo=N''MAT'')
 THROW 54902,N''Los cargos, recibos, horarios o saldos demo no coinciden con lo esperado.'',1;');

-- Calificaciones demo · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Calificaciones demo · lote 1',N'-- Completa las notas de la demostración y permite recuperar la instalación que falló con 52408.
-- No borrar estudiantes, pagos o la base. No sobrescribe calificaciones existentes.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54902,N''Cierra transacciones antes de completar la demostración.'',1;
DECLARE @Profesor nvarchar(450)=N''demo-profesor'',@Tipo int,@Evaluacion int,@Clase int,
 @Version varchar(18),@VersionBinaria binary(8),@Registro nvarchar(10),@Json nvarchar(max),@i int,@Fecha date;
IF NOT EXISTS(SELECT 1 FROM dbo.AspNetUsers WHERE Id=@Profesor AND Email=N''profesor@liceo.test'')
 OR NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
 THROW 54902,N''Este archivo requiere las cuentas y el corte de la instalación de demostración.'',1;

DECLARE @Clases TABLE(Id int PRIMARY KEY);
INSERT @Clases
 SELECT D.Id FROM dbo.AsignacionDocente D JOIN dbo.Asignatura S ON S.Id=D.AsignaturaId
 JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 WHERE D.UsuarioId=@Profesor AND S.Codigo IN
 (N''DEMO-1-1'',N''DEMO-1-2'',N''DEMO-2-1'',N''DEMO-2-2'',N''DEMO-3-1'',N''DEMO-3-2'');
IF (SELECT COUNT(*) FROM @Clases)<>6
 THROW 54902,N''No se encontraron las seis clases de demostración esperadas. No se modificaron otras clases.'',1;
SELECT @Tipo=Id FROM dbo.TipoEvaluacion WHERE Nombre=N''Trabajo práctico demo'';
IF @Tipo IS NULL
BEGIN
 INSERT dbo.TipoEvaluacion(Nombre) VALUES(N''Trabajo práctico demo'');
 SET @Tipo=SCOPE_IDENTITY();
END;
DECLARE Clases CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM @Clases ORDER BY Id;
OPEN Clases; FETCH NEXT FROM Clases INTO @Clase;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @Fecha=P.Inicio FROM dbo.AsignacionDocente D JOIN dbo.GrupoAcademico G ON G.Id=D.GrupoId
 JOIN dbo.PeriodoAcademico P ON P.Id=G.PeriodoId WHERE D.Id=@Clase;
 SET @i=1;
 WHILE @i<=2
 BEGIN
  SET @Evaluacion=NULL;
  SELECT @Evaluacion=Id FROM dbo.Evaluacion
   WHERE AsignacionId=@Clase AND Nombre=CONCAT(N''Evaluación demo '',@i);
  IF @Evaluacion IS NULL
  BEGIN
   SET @Json=(SELECT N''Evaluacion'' Accion,@Clase AsignacionId,@Tipo TipoId,CONCAT(N''Evaluación demo '',@i) Nombre,
    @Fecha Fecha,N''Cuantitativa'' Modo,100 Maximo,50 Peso FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC dbo.Notas_Guardar @Json,@Profesor,@ResultadoId=@Evaluacion OUTPUT;
  END;
  SET @VersionBinaria=NULL; SET @Version=NULL; SET @Registro=NULL;
  SELECT @VersionBinaria=CONVERT(binary(8),E.Version)
   FROM dbo.Evaluacion E WHERE E.Id=@Evaluacion AND E.AsignacionId=@Clase;
  -- No convertir timestamp directamente a varchar: normalizar primero a ocho bytes.
  SET @Version=CONVERT(varchar(18),sys.fn_varbintohexstr(CONVERT(varbinary(8),@VersionBinaria)));
  IF @VersionBinaria IS NULL OR DATALENGTH(@Version)<>18 OR TRY_CONVERT(binary(8),@Version,1)<>@VersionBinaria
   THROW 54902,N''No se pudo representar la versión de la evaluación. No se intentó guardar una nota sin versión.'',1;
  SELECT TOP(1) @Registro=A.Registro FROM dbo.GrupoEstudiante A
   JOIN dbo.AsignacionDocente D ON D.GrupoId=A.GrupoId
   JOIN dbo.Estudiantes E ON E.Registro=A.Registro
   WHERE D.Id=@Clase AND E.NombreEstudiante LIKE N''Demo %''
   ORDER BY A.Registro;
  IF @Registro IS NULL THROW 54902,N''No hay alumno demo inscrito en la clase.'',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.Calificacion WHERE EvaluacionId=@Evaluacion AND Registro=@Registro)
  BEGIN
   SET @Json=(SELECT N''Nota'' Accion,@Clase AsignacionId,@Evaluacion EvaluacionId,@Registro Registro,
    @Version VersionEvaluacion,CAST(85 AS decimal(7,2)) Nota,N''Resultado de demostración'' Observacion
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   IF TRY_CONVERT(binary(8),JSON_VALUE(@Json,''$.VersionEvaluacion''),1)<>@VersionBinaria
    THROW 54902,N''La versión de la evaluación no se conservó en el formulario demo.'',1;
   EXEC dbo.Notas_Guardar @Json,@Profesor;
  END;
  SET @i+=1;
 END;
 FETCH NEXT FROM Clases INTO @Clase;
END;
CLOSE Clases; DEALLOCATE Clases;
IF (SELECT COUNT(*) FROM dbo.Calificacion C JOIN dbo.Evaluacion E ON E.Id=C.EvaluacionId
 JOIN @Clases D ON D.Id=E.AsignacionId WHERE E.Nombre IN(N''Evaluación demo 1'',N''Evaluación demo 2''))<12
 THROW 54902,N''Faltan calificaciones de demostración.'',1;
SELECT N''DEMOSTRACIÓN COMPLETADA: cuentas, pagos y estudiantes conservados.'' Resultado;');

-- Verificación final · lote 1
INSERT @Etapas(Nombre,Texto) VALUES(N'Verificación final · lote 1',N'IF (SELECT COUNT(*) FROM dbo.InstalacionInicial)<>23
            THROW 54901,N''La estructura no alcanzó la migración 023.'',1;
        IF EXISTS(SELECT 1 FROM (VALUES (N''Anticipo_Registrar'',N''P''),
(N''ReciboMultiple_Anular'',N''P''),
(N''ObligacionLegada'',N''V''),
(N''Aranceles_Guardar'',N''P''),
(N''Aranceles_Consultar'',N''P''),
(N''Cargos_ConfigurarMatricula'',N''P''),
(N''Cargos_GenerarModalidad'',N''P''),
(N''CierreAcademico_Guardar'',N''P''),
(N''CierreAcademico_Consultar'',N''P''),
(N''Finanzas_Autorizar'',N''P''),
(N''CobroMultiple_Registrar'',N''P''),
(N''CuentaEstudiante_Consultar'',N''P''),
(N''ReciboMultiple_Consultar'',N''P''),
(N''Conciliacion_Revisar'',N''P''),
(N''Conciliacion_Consultar'',N''P''),
(N''Conciliacion_Pantalla'',N''P''),
(N''Conciliacion_Recapturar'',N''P''),
(N''Saldo_Instantanea'',N''P''),
(N''Saldo_Consultar'',N''P''),
(N''Saldo_Revisar'',N''P''),
(N''CorteFinanciero_Ejecutar'',N''P''),
(N''Evaluacion_ConsultarEdicion'',N''P''),
(N''Evaluacion_Editar'',N''P''),
(N''Expediente_Obtener'',N''P''),
(N''Expediente_Guardar'',N''P''),
(N''Estudiante_DarBaja'',N''P''),
(N''Cargos_Autorizar'',N''P''),
(N''Cargos_Configurar'',N''P''),
(N''Cargos_Generar'',N''P''),
(N''Cargos_Pantalla'',N''P''),
(N''Horario_Cancelar'',N''P''),
(N''Horario_Consultar'',N''P''),
(N''Horario_Historial'',N''P''),
(N''Mensualidades_GenerarLote'',N''P''),
(N''Buscar_Estudiantes_Mensualidad'',N''P''),
(N''Ver_Estado_Mensualidad_Cuenta'',N''P''),
(N''Pagar_Mensualidad'',N''P''),
(N''Notas_Guardar'',N''P''),
(N''Notas_Consultar'',N''P''),
(N''Obtener_ComprobanteHistorico'',N''P''),
(N''Personal_Autorizar'',N''P''),
(N''Personal_Consultar'',N''P''),
(N''Personal_Guardar'',N''P''),
(N''CatalogoAcademico_Guardar'',N''P''),
(N''Planificacion_Guardar'',N''P''),
(N''Planificacion_Consultar'',N''P''),
(N''Planificacion_Cambiar'',N''P''),
(N''Planificacion_CambioConsultar'',N''P''),
(N''Planificacion_CambiosHistorial'',N''P''),
(N''Registrar_Auditoria'',N''P''),
(N''Registrar_Comprobante'',N''P''),
(N''ReporteFinanciero_Consultar'',N''P''),
(N''TipoEvaluacion_Consultar'',N''P''),
(N''TipoEvaluacion_Guardar'',N''P'')) M(Nombre,Tipo)
            WHERE OBJECT_ID(N''dbo.''+M.Nombre,M.Tipo) IS NULL)
            THROW 54901,N''Faltan procedimientos o vistas.'',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
            THROW 54901,N''El libro financiero nuevo no quedó activo.'',1;
        IF (SELECT COUNT(*) FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id
            JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE
            (U.Email=N''camilo@liceo.test'' AND R.Name=N''Administrador'') OR
            (U.Email=N''profesor@liceo.test'' AND R.Name=N''Profesor'') OR
            (U.Email=N''cajero@liceo.test'' AND R.Name=N''Cajero''))<>3
            THROW 54901,N''Las cuentas demo no quedaron completas.'',1;
        INSERT dbo.InstalacionInicial(Etapa,FuenteSha256)
            VALUES(N''DemostracionLista'',''5fb9ddad7179a1dc3aa4c116c5aa4d0aa36b53e9a2ab4a129c8633a5de3f4151'');
        SELECT DB_NAME() BaseInstalada,23 UltimaMigracion,
            (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(''dbo'')) Procedimientos,
            (SELECT COUNT(*) FROM dbo.Estudiantes) Estudiantes,
            (SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1) Migrado;
        SELECT N''INSTALACIÓN COMPLETA: inicia LiceoWeb conectado a esta base.'' Resultado;');

DECLARE @Nombre nvarchar(200)=N'Crear base',@Texto nvarchar(max),@Ejecutar nvarchar(max),@Crear nvarchar(max);
BEGIN TRY
 SET @Crear=N'CREATE DATABASE '+QUOTENAME(@Base)+N';';
 EXEC sys.sp_executesql @Crear;
 -- La ejecución en la base destino mantiene CREATE PROCEDURE/VIEW al inicio de su lote.
 SET @Ejecutar=N'EXEC '+QUOTENAME(@Base)+N'.sys.sp_executesql @stmt=@Lote;';
 DECLARE Instalacion CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre,Texto FROM @Etapas ORDER BY Orden;
 OPEN Instalacion; FETCH NEXT FROM Instalacion INTO @Nombre,@Texto;
 WHILE @@FETCH_STATUS=0
 BEGIN
  PRINT CONCAT(N'Instalando: ',@Nombre);
  SET @Texto=REPLACE(@Texto,N'__LICEO_BASE__',@Base);
  EXEC sys.sp_executesql @Ejecutar,N'@Lote nvarchar(max)',@Lote=@Texto;
  IF @@TRANCOUNT<>0 THROW 54999,N'La etapa dejó una transacción abierta.',1;
  FETCH NEXT FROM Instalacion INTO @Nombre,@Texto;
 END;
 CLOSE Instalacion; DEALLOCATE Instalacion;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF CURSOR_STATUS('local','Instalacion')>=0 CLOSE Instalacion;
 IF CURSOR_STATUS('local','Instalacion')>-3 DEALLOCATE Instalacion;
 DECLARE @Error nvarchar(2048)=CONCAT(N'INSTALACIÓN DETENIDA en ',@Nombre,N'. Error ',ERROR_NUMBER(),N': ',ERROR_MESSAGE(),
 N' No continúes con la aplicación sobre esta base parcial.');
 THROW 54999,@Error,1;
END CATCH;
