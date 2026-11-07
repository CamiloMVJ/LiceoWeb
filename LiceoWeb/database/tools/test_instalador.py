"""Pruebas estáticas del instalador. No sustituyen la ejecución en SQL Server."""
import re
from generar_instalador import construir, DB, MODULO
texto, etapas = construir()
assert texto == (DB / "InstalacionInicialCompleta.sql").read_text(), "Regenerar el instalador"
assert not re.search(r"^\s*:", texto, re.M), "No debe requerir comandos SQLCMD"
assert not re.search(r"^\s*GO\s*$", texto, re.M), "Un único lote para manejar errores"
assert len([n for n, _ in etapas if n.startswith("Confirmación ")]) == 24
assert len([n for n, _ in etapas if n.startswith(("PROCEDURE ", "VIEW "))]) == 56
declarados = set()
for n, sql in etapas:
 m = MODULO.search(sql)
 if m: declarados.add(m[2].lower())
 if n.startswith("Demostración"):
  llamadas = {x.lower() for x in re.findall(r"EXEC(?:UTE)?\s+dbo\.(\w+)", sql, re.I)}
  assert llamadas <= declarados, (n, llamadas - declarados)
corte = next(i for i, (n, sql) in enumerate(etapas) if n.startswith("Demostración") and "EXEC dbo.CorteFinanciero_Ejecutar" in sql)
datos = next(i for i, (n, sql) in enumerate(etapas) if n.startswith("Demostración") and "INSERT dbo.AnioLectivo" in sql)
assert corte < datos
assert "@Aplicar=1" in etapas[corte][1]
assert texto.index("IF DB_ID(@Base) IS NOT NULL") < texto.index("SET @Crear=")
assert "IF @@TRANCOUNT<>0 THROW 54999" in texto
assert "No continúes con la aplicación sobre esta base parcial" in texto
print("PASS: instalador reproducible, sin SQLCMD, con 24 etapas y 56 módulos.")
print("PASS: dependencias antes de demo, corte real y verificación final.")
print("PASS: base existente protegida y detención completa ante un error.")
notas = (DB / "seeds/003_CalificacionesDemostracion.sql").read_text()
assert "sys.fn_varbintohexstr(CONVERT(varbinary(8),@VersionBinaria))" in notas
assert "IF NOT EXISTS(SELECT 1 FROM dbo.Calificacion" in notas
assert "JSON_VALUE(@Json,'$.VersionEvaluacion')" in notas
assert not re.search(r"\b(DELETE|TRUNCATE|DROP)\b", notas, re.I)
assert next(i for i,(n,_) in enumerate(etapas) if n.startswith("Calificaciones demo")) > datos
print("PASS: recuperación sin borrados, notas no sobrescritas y versión binaria normalizada.")

# Las escrituras monetarias deben identificar el corte abierto y persistirlo.
for nombre in ('CobroMultiple.sql','Anticipos.sql','AnulacionRecibos.sql'):
 sql=(DB/'procedures'/nombre).read_text()
 assert "WHERE Fin IS NULL" in sql and "CorteCajaId)" in sql, nombre
print("PASS: cobros, anticipos y devoluciones vinculados al corte de caja.")
