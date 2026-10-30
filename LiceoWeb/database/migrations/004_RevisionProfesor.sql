-- Ampliación aditiva. No elimina ni transforma registros históricos.
-- Instalar después de 003 y de Identity, sobre una copia respaldada.
SET XACT_ABORT ON;
IF DB_NAME() <> N'LiceoWeb_Dev' THROW 52000, N'Base incorrecta.', 1;
IF OBJECT_ID('dbo.Estudiantes') IS NULL OR OBJECT_ID('dbo.AspNetUsers') IS NULL
 THROW 52001, N'Instale negocio e Identity primero.', 1;
IF OBJECT_ID('dbo.ExpedienteAmpliado') IS NOT NULL
 THROW 52002, N'Esta ampliación ya existe; no repetir.', 1;
BEGIN TRY
BEGIN TRANSACTION;
CREATE TABLE dbo.ExpedienteAmpliado (
 Registro nvarchar(10) PRIMARY KEY REFERENCES dbo.Estudiantes(Registro),
 Identificacion nvarchar(50) NULL, TipoSangre nvarchar(10) NULL,
 Alergias nvarchar(1000) NULL, Padecimientos nvarchar(1000) NULL,
 IndicacionesEmergencia nvarchar(1000) NULL,
 TipoIngreso nvarchar(20) NOT NULL CHECK(TipoIngreso IN ('Nuevo','Traslado')),
 CodigoTraslado nvarchar(100) NULL, CentroProcedencia nvarchar(200) NULL,
 Version rowversion,
 CHECK(TipoIngreso <> 'Traslado' OR LEN(LTRIM(RTRIM(CodigoTraslado))) > 0 AND CodigoTraslado IS NOT NULL)
);
CREATE TABLE dbo.ResponsableEstudiante (
 Id int IDENTITY PRIMARY KEY, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro),
 Vinculo nvarchar(20) NOT NULL CHECK(Vinculo IN ('Padre','Madre','Otro')),
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
 Tipo nvarchar(100) NOT NULL, Estado nvarchar(20) NOT NULL CHECK(Estado IN ('Pendiente','Recibido','Verificado')),
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
CREATE TABLE dbo.ReciboMultiple(Id bigint IDENTITY PRIMARY KEY, Numero nvarchar(25) NOT NULL UNIQUE, Operacion uniqueidentifier NOT NULL UNIQUE, Registro nvarchar(10) NOT NULL REFERENCES dbo.Estudiantes(Registro), Pagador nvarchar(200) NOT NULL, UsuarioId nvarchar(450) NOT NULL REFERENCES dbo.AspNetUsers(Id), Fecha datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), Metodo nvarchar(20) NOT NULL CHECK(Metodo IN ('Efectivo','Transferencia')), Referencia nvarchar(100) NULL, Recibido decimal(18,2) NOT NULL CHECK(Recibido>0), Cambio decimal(18,2) NOT NULL CHECK(Cambio>=0), CHECK(Cambio<=Recibido), CHECK(Metodo<>'Transferencia' OR Referencia IS NOT NULL));
CREATE TABLE dbo.AplicacionPago(ReciboId bigint NOT NULL REFERENCES dbo.ReciboMultiple(Id), CargoId bigint NOT NULL REFERENCES dbo.CargoEstudiante(Id), Importe decimal(18,2) NOT NULL CHECK(Importe>0), DescripcionHistorica nvarchar(200) NOT NULL, PRIMARY KEY(ReciboId,CargoId));
COMMIT;
END TRY
BEGIN CATCH
IF XACT_STATE()<>0 ROLLBACK;
THROW;
END CATCH;
