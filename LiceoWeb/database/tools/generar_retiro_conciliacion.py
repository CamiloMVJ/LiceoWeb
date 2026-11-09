"""Genera una migración 025 autónoma: actualiza dependencias y retira conciliaciones."""
from pathlib import Path
import re
DB=Path(__file__).resolve().parents[1]
FUENTES=('Aranceles.sql','Aranceles_Consultar.sql','GeneracionCargos.sql','Cargos_GenerarModalidad.sql','Anticipos.sql','CortesCaja.sql')
def construir():
 partes=['''-- 025 · Retirar conciliaciones del sistema de escritorio.
-- Ejecutar TODO una vez con la aplicación detenida, después de 024.
-- No importa registros de escritorio. Conserva cargos, recibos, estudiantes,
-- saldos disponibles, cuentas y cortes de caja existentes.
-- Elimina las tablas de preparación/revisión y los procedimientos de traslado.
-- RevisionSaldoId se conserva nullable SIN FK como compatibilidad de scripts demo
-- distribuidos; ya no se utiliza para consultar, aprobar ni importar saldos.
-- Los archivos 001–024 son historia de instalación, no deben volverse a ejecutar.
SET NOCOUNT ON; SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 THROW 54920,N'Cierra transacciones antes de instalar 025.',1;
IF OBJECT_ID('dbo.CorteCaja','U') IS NULL OR COL_LENGTH('dbo.ReciboMultiple','Anticipo') IS NULL
 THROW 54920,N'Instala primero la migración 024.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Finanzas.Configuracion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54920,N'Finanzas ocupada. Detén la aplicación y reintenta.',1;
 EXEC @Lock=sys.sp_getapplock @Resource=N'Liceo.Planificacion',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @Lock<0 THROW 54920,N'Planificación ocupada. Reintenta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.ControlFinanciero WHERE Id=1)
 THROW 54920,N'Falta el control financiero de la instalación.',1;
 DECLARE @Cargos bigint=(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante),
 @Recibos bigint=(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple),
 @Saldo decimal(38,2)=(SELECT ISNULL(SUM(Disponible),0) FROM dbo.SaldoFinanciero),
 @Cortes bigint=(SELECT COUNT_BIG(*) FROM dbo.CorteCaja);
 -- En instalación nueva los procedimientos se crean después, en orden de dependencia.
 -- En una actualización se reemplazan aquí, dentro de la misma transacción del retiro.
 IF OBJECT_ID('dbo.Cargos_Autorizar','P') IS NOT NULL
 BEGIN
''']
 for nombre in FUENTES:
  for lote in re.split(r'^\s*GO\s*(?:--[^\n]*)?$',(DB/'procedures'/nombre).read_text(encoding='utf-8-sig'),flags=re.M|re.I):
   if re.search(r'CREATE\s+OR\s+ALTER\s+PROCEDURE',lote,re.I):
    partes.append(f" -- Dependencia vigente: {nombre}\n EXEC sys.sp_executesql N'{lote.strip().replace(chr(39),chr(39)*2)}';\n")
 partes.append(''' END;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Revisar;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Consultar;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Pantalla;
 DROP PROCEDURE IF EXISTS dbo.Conciliacion_Recapturar;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Instantanea;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Consultar;
 DROP PROCEDURE IF EXISTS dbo.Saldo_Revisar;
 DROP PROCEDURE IF EXISTS dbo.CorteFinanciero_Ejecutar;
 DROP VIEW IF EXISTS dbo.ObligacionLegada;
 -- Quitar solo la FK de conciliación. Los valores y balances financieros permanecen.
 DECLARE @Sql nvarchar(max)=N'';
 SELECT @Sql+=N'ALTER TABLE dbo.SaldoFinanciero DROP CONSTRAINT '+QUOTENAME(name)+N';'
 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('dbo.SaldoFinanciero')
  AND referenced_object_id=OBJECT_ID('dbo.RevisionSaldo');
 IF @Sql<>N'' EXEC sys.sp_executesql @Sql;
 DROP TABLE IF EXISTS dbo.ObligacionMigrada;
 DROP TABLE IF EXISTS dbo.RevisionObligacion;
 DROP TABLE IF EXISTS dbo.HistorialCaptura;
 DROP TABLE IF EXISTS dbo.PreparacionObligacion;
 DROP TABLE IF EXISTS dbo.MapaConceptoLegado;
 DROP TABLE IF EXISTS dbo.RevisionSaldo;
 -- Activar el esquema web directamente; no leer ni trasladar datos de las tablas antiguas.
 -- Migrado se conserva como indicador interno de compatibilidad con los módulos vigentes.
 UPDATE dbo.ControlFinanciero SET Migrado=1,Fecha=COALESCE(Fecha,SYSUTCDATETIME()) WHERE Id=1 AND Migrado=0;
 IF @Cargos<>(SELECT COUNT_BIG(*) FROM dbo.CargoEstudiante)
 OR @Recibos<>(SELECT COUNT_BIG(*) FROM dbo.ReciboMultiple)
 OR @Saldo<>(SELECT ISNULL(SUM(Disponible),0) FROM dbo.SaldoFinanciero)
 OR @Cortes<>(SELECT COUNT_BIG(*) FROM dbo.CorteCaja)
 THROW 54920,N'Cambió un total financiero durante el retiro. Se revierte la actualización.',1;
 COMMIT;
 SELECT N'025 APLICADA: conciliaciones retiradas; operaciones financieras conservadas.' Resultado;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
''')
 return ''.join(partes)
if __name__=='__main__':
 destino=DB/'migrations/025_RetirarConciliacionesLegadas.sql'
 destino.write_text(construir(),encoding='utf-8')
 print(destino.name)
