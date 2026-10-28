-- LiceoWeb - Etapa 2. Ejecutar sobre una base NUEVA y vacia.
-- No ejecutar sobre Registro_Pagos ni sobre una base con datos reales.
-- SQL Server / SSMS. UTF-8. Ejecutar el archivo completo con F5.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev'
    THROW 50001, N'Seleccione LiceoWeb_Dev antes de ejecutar.', 1;

IF OBJECT_ID(N'dbo.Estudiantes', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Historial_Bajas', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Pagos', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Arreglos_Pago', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Costo_Matricula', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Costo_Mensualidad', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Costo_Promocion', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Costo_Mantenimiento', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Costo_EvBoTa', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Matriculas', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Mantenimientos', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.EvBoTaS', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Mensualidades', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Promociones', N'U') IS NOT NULL OR
   OBJECT_ID(N'dbo.Abonos', N'U') IS NOT NULL
    THROW 50002, N'Ya existen tablas del negocio. No repita esta instalacion.', 1;
IF OBJECT_ID(N'dbo.Secuencia_Estudiantes', N'SO') IS NOT NULL
    THROW 50003, N'Ya existe la secuencia. Revise la base seleccionada.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    CREATE SEQUENCE dbo.Secuencia_Estudiantes AS bigint
        START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9999999 NO CYCLE;

CREATE TABLE dbo.Estudiantes (
Registro nvarchar(10) primary key default (N'E_' + right(N'0000000' + cast(next value for Secuencia_Estudiantes as nvarchar), 7)),
    NombreEstudiante nvarchar(100) not null,
    Modalidad nvarchar(20) check (Modalidad in (N'Preescolar',N'Primaria',N'Secundaria')) not null,
    Grado nvarchar(50) not null, 
    FechaNacimiento date not null,
    Sexo char(1) check (Sexo in (N'M',N'F'))not null,
    NombreTutor nvarchar(100) not null,
    Telefono nvarchar(9) not null,
    Direccion nvarchar(200) not null,
    Notas nvarchar(200),
    CodigoEstudiante nvarchar(25) default N'Aun no asignado',
    Estado nvarchar(10) not null default N'Activo' check (Estado in (N'Activo',N'Inactivo'))
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
    Concepto nvarchar(35) check (Concepto in (N'Matrícula', N'Mensualidad', N'Promoción', N'Mantenimiento', N'Evaluaciones, Boletín y Tarjeta', N'Uso de Saldo')) not null,
    Monto decimal(18,2) not null,
	Metodo_Pago nvarchar(15) check (Metodo_Pago in (N'Efectivo', N'Transferencia', N'Saldo')) not null,
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
	Estado nvarchar(10) default N'Pendiente' check (Estado in (N'Pendiente',N'Cancelado')) not null
);

CREATE TABLE dbo.EvBoTaS (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_EvBoTa(EvBoTa_Modalidad),
    Grado nvarchar(50) not null, 
    Costo_EvBoTa decimal(18,2) not null,
    Anio int not null,
	Estado nvarchar(10) default N'Pendiente' check (Estado in (N'Pendiente',N'Cancelado')) not null
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
    Estado nvarchar(10) default N'Pendiente' check (Estado in (N'Pendiente',N'Cancelado',N'Vencido')) not null
);

CREATE TABLE dbo.Promociones (
Id int identity(1,1) primary key,
    Id_Comprobante nvarchar(25) references Pagos(Id_Comprobante) null,
    Registro_Estudiante nvarchar(10) references Estudiantes(Registro) not null,
    Modalidad nvarchar(20) not null references Costo_Promocion(Promocion_Modalidad),
    Costo_Promocion decimal(18,2) not null,
    Anio int not null,
    Estado nvarchar(10) default N'Pendiente' check (Estado in (N'Pendiente',N'Cancelado')) not null,
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
END CATCH;
