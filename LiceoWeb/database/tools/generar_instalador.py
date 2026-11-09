"""Regenera el instalador autónomo. Ejecutar con Python 3, sin paquetes adicionales."""
from pathlib import Path
import hashlib
import re

DB = Path(__file__).resolve().parents[1]
MARCADOR = "__LICEO_BASE__"
MODULO = re.compile(r"CREATE\s+OR\s+ALTER\s+(PROCEDURE|VIEW|FUNCTION)\s+(?:dbo\.)?(\w+)", re.I)

def leer(path):
    return path.read_text(encoding="utf-8-sig")

def lotes(sql):
    return [p.strip() for p in re.split(r"^\s*GO\s*(?:--[^\n]*)?$", sql, flags=re.M | re.I) if p.strip()]

def adaptar(sql):
    return sql.replace("LiceoWeb_Dev", MARCADOR).replace("LiceoWeb_Limpia", MARCADOR)

def construir():
    etapas = []
    def agregar(nombre, sql):
        for i, lote in enumerate(lotes(sql), 1):
            etapas.append((f"{nombre} · lote {i}", adaptar(lote)))

    agregar("Identity", "\n".join(lotes(leer(DB / "tools/IdentityInicial.sql"))))
    agregar("Registro de instalación", """CREATE TABLE dbo.InstalacionInicial(
        Etapa nvarchar(160) NOT NULL PRIMARY KEY, FuenteSha256 varchar(64) NOT NULL,
        FechaUTC datetime2 NOT NULL DEFAULT SYSUTCDATETIME());""")

    migraciones = sorted((DB / "migrations").glob("*.sql"))
    assert [int(p.name[:3]) for p in migraciones] == list(range(26))
    for p in migraciones[1:]:
        agregar(p.name, leer(p))
        agregar("Confirmación " + p.name,
            f"INSERT dbo.InstalacionInicial(Etapa,FuenteSha256) VALUES(N'{p.name}','{hashlib.sha256(p.read_bytes()).hexdigest()}');")

    modulos = {}
    for p in sorted((DB / "procedures").glob("*.sql")):
        if p.name == "Procedimientos.sql":
            continue  # legado incompatible; reemplazos vigentes incluidos por sus archivos.
        for lote in lotes(leer(p)):
            match = MODULO.search(lote)
            if match:
                nombre = match[2].lower()
                assert nombre not in modulos, f"Módulo duplicado: {nombre}"
                modulos[nombre] = (match[1], match[2], p.name, lote)

    pendientes = set(modulos)
    while pendientes:
        listos = sorted(n for n in pendientes if not (
            {x.lower() for x in re.findall(r"\bdbo\.(\w+)", modulos[n][3], re.I)}
            & (pendientes - {n})))
        assert listos, f"Dependencias cíclicas: {pendientes}"
        for n in listos:
            tipo, nombre, archivo, sql = modulos[n]
            agregar(f"{tipo} dbo.{nombre} · {archivo}", sql)
            pendientes.remove(n)

    agregar("Roles Identity", """
        INSERT dbo.AspNetRoles(Id,Name,NormalizedName,ConcurrencyStamp)
        SELECT CONVERT(nvarchar(450),NEWID()),Nombre,UPPER(Nombre),CONVERT(nvarchar(36),NEWID())
        FROM (VALUES(N'Administrador'),(N'Cajero'),(N'Profesor')) R(Nombre);""")
    agregar("Demostración", leer(DB / "seeds/002_Demostracion.sql"))
    agregar("Calificaciones demo", leer(DB / "seeds/003_CalificacionesDemostracion.sql"))

    esperados = ",\n".join(f"(N'{nombre}',N'{'P' if tipo.upper() == 'PROCEDURE' else 'V'}')"
                           for tipo, nombre, _, _ in modulos.values())
    agregar("Verificación final", f"""
        IF (SELECT COUNT(*) FROM dbo.InstalacionInicial)<>25
            THROW 54901,N'La estructura no alcanzó la migración 025.',1;
        IF EXISTS(SELECT 1 FROM (VALUES {esperados}) M(Nombre,Tipo)
            WHERE OBJECT_ID(N'dbo.'+M.Nombre,M.Tipo) IS NULL)
            THROW 54901,N'Faltan procedimientos o vistas.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1 AND Migrado=1)
            THROW 54901,N'El libro financiero nuevo no quedó activo.',1;
        IF (SELECT COUNT(*) FROM dbo.AspNetUsers U JOIN dbo.AspNetUserRoles UR ON UR.UserId=U.Id
            JOIN dbo.AspNetRoles R ON R.Id=UR.RoleId WHERE
            (U.Email=N'camilo@liceo.test' AND R.Name=N'Administrador') OR
            (U.Email=N'profesor@liceo.test' AND R.Name=N'Profesor') OR
            (U.Email=N'cajero@liceo.test' AND R.Name=N'Cajero'))<>3
            THROW 54901,N'Las cuentas demo no quedaron completas.',1;
        IF OBJECT_ID('dbo.RevisionSaldo','U') IS NOT NULL OR OBJECT_ID('dbo.PreparacionObligacion','U') IS NOT NULL
            THROW 54901,N'No se completó el retiro de conciliaciones.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.CorteCaja WHERE Fin IS NULL)
            THROW 54901,N'No quedó un corte de caja abierto para la demostración.',1;
        INSERT dbo.InstalacionInicial(Etapa,FuenteSha256)
            VALUES(N'DemostracionLista','{hashlib.sha256((DB / "seeds/002_Demostracion.sql").read_bytes()).hexdigest()}');
        SELECT DB_NAME() BaseInstalada,25 UltimaMigracion,
            (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('dbo')) Procedimientos,
            (SELECT COUNT(*) FROM dbo.Estudiantes) Estudiantes,
            (SELECT Migrado FROM dbo.ControlFinanciero WHERE Id=1) Migrado;
        SELECT N'INSTALACIÓN COMPLETA: inicia LiceoWeb conectado a esta base.' Resultado;
        """)

    encabezado = """-- LICEOWEB · INSTALACIÓN COMPLETA CON DEMOSTRACIÓN · esquema 001–025
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
"""
    def literal(s): return "N'" + s.replace("'", "''") + "'"
    partes = [encabezado]
    for nombre, sql in etapas:
        partes.append(f"\n-- {nombre}\nINSERT @Etapas(Nombre,Texto) VALUES({literal(nombre)},{literal(sql)});\n")
    partes.append("""
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
""")
    return "".join(partes), etapas

if __name__ == "__main__":
    texto, etapas = construir()
    destino = DB / "InstalacionInicialCompleta.sql"
    destino.write_text(texto, encoding="utf-8")
    print(f"{destino.name}: {len(etapas)} lotes, {len(texto)} caracteres.")
