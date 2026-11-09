"""Verifica coherencia del retiro entre rutas, SQL vigente, actualización e instalador."""
from pathlib import Path
import re
from generar_retiro_conciliacion import construir, DB
APP=DB.parent
ROOT=APP.parent
retirados={'Conciliacion_Revisar','Conciliacion_Consultar','Conciliacion_Pantalla','Conciliacion_Recapturar',
 'Saldo_Instantanea','Saldo_Consultar','Saldo_Revisar','CorteFinanciero_Ejecutar','ObligacionLegada',
 'ObligacionMigrada','RevisionObligacion','HistorialCaptura','PreparacionObligacion','MapaConceptoLegado','RevisionSaldo'}
migracion=(DB/'migrations/025_RetirarConciliacionesLegadas.sql').read_text()
assert migracion==construir(),'Regenerar la migración 025 desde las fuentes vigentes'
for path in (DB/'procedures').glob('*.sql'):
 if path.name=='Procedimientos.sql':continue
 for name in retirados:
  assert not re.search(r'\bdbo\.'+name+r'\b',path.read_text(encoding='utf-8-sig'),re.I),(path,name)
print('PASS: procedimientos vigentes sin dependencias de objetos retirados.')
for pagina in ('Conciliacion','Saldos'):
 assert not (APP/f'Pages/Finanzas/{pagina}.cshtml').exists()
 assert not (APP/f'Pages/Finanzas/{pagina}.cshtml.cs').exists()
 for path in (APP/'Pages').rglob('*.cshtml'):
  assert f'/Finanzas/{pagina}' not in path.read_text(encoding='utf-8-sig'),path
print('PASS: rutas y enlaces a las dos pantallas eliminados.')
assert 'ConciliacionRepository' not in (APP/'Program.cs').read_text()
assert 'OnPostTransicionAsync' not in (APP/'Pages/Finanzas/Cortes.cshtml.cs').read_text()
assert 'CorteFinanciero_Ejecutar' not in (DB/'seeds/002_Demostracion.sql').read_text()
print('PASS: sin registro del repositorio ni activación/importación del libro desde UI o demo.')
for tabla in ('CargoEstudiante','ReciboMultiple','AplicacionPago','SaldoFinanciero','CorteCaja','Estudiantes','AspNetUsers'):
 assert not re.search(r'(?:DROP\s+TABLE|DELETE\s+(?:FROM\s+)?)\s+dbo\.'+tabla+r'\b',migracion,re.I),tabla
for name in retirados:
 assert re.search(r'DROP\s+(?:TABLE|VIEW|PROCEDURE)\s+IF\s+EXISTS\s+dbo\.'+name+r'\b',migracion,re.I),name
assert 'ISNULL(SUM(Disponible),0)' in migracion and 'XACT_STATE()<>0 ROLLBACK' in migracion
print('PASS: retiro transaccional sin borrar operaciones, saldos ni cuentas actuales.')
