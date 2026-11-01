using System.ComponentModel.DataAnnotations;
using LiceoWeb.Pages.Finanzas;
var count=0;
void Check(string name,DateTime desde,DateTime hasta,int pagina,bool expected)
{
 var x=new ReporteModel.FiltroInput{Desde=desde,Hasta=hasta,Pagina=pagina};
 var valid=Validator.TryValidateObject(x,new ValidationContext(x),new List<ValidationResult>(),true);
 if(valid!=expected)throw new Exception(name);Console.WriteLine("PASS "+name);count++;
}
var d=new DateTime(2026,1,1);
Check("Un día",d,d,1,true);
Check("366 días incluidos",d,d.AddDays(365),1,true);
Check("Rango demasiado largo",d,d.AddDays(366),1,false);
Check("Invertido",d,d.AddDays(-1),1,false);
Check("Página cero",d,d,0,false);
Check("Página excesiva",d,d,1000001,false);
Check("Año fuera de rango",new(1999,1,1),new(1999,1,2),1,false);
Check("Evitar desborde de fecha final",new(9999,1,1),new(9999,1,2),1,false);
Console.WriteLine($"{count} pruebas aprobadas.");

void CsvCheck(string name, bool valid)
{
 if(!valid) throw new Exception(name);
 Console.WriteLine("PASS "+name);count++;
}
CsvCheck("CSV protege fórmula",LiceoWeb.Services.ReporteFinancieroCsv.Texto("=1+1")=="\"'=1+1\"");
CsvCheck("CSV protege fórmula tras espacios",LiceoWeb.Services.ReporteFinancieroCsv.Texto("  @SUM(1)").StartsWith("\"'"));
CsvCheck("CSV protege tabulación inicial",LiceoWeb.Services.ReporteFinancieroCsv.Texto("\t=1").StartsWith("\"'"));
CsvCheck("CSV escapa comillas y coma",LiceoWeb.Services.ReporteFinancieroCsv.Texto("Ana, \"María\"")=="\"Ana, \"\"María\"\"\"");
CsvCheck("CSV conserva saltos dentro de campo",LiceoWeb.Services.ReporteFinancieroCsv.Texto("Ana\r\nMaría")=="\"Ana\r\nMaría\"");
var table=new System.Data.DataTable();
table.Columns.Add("FechaLocal",typeof(DateTime));
foreach(var c in new[]{"Numero","Registro","NombreEstudiante","Tipo","Metodo","Responsable"})table.Columns.Add(c,typeof(string));
foreach(var c in new[]{"Dinero","Saldo","Aplicado"})table.Columns.Add(c,typeof(decimal));
var empty=LiceoWeb.Services.ReporteFinancieroCsv.Crear(table);
CsvCheck("CSV vacío contiene encabezado y BOM",empty.Take(3).SequenceEqual(new byte[]{239,187,191}) && System.Text.Encoding.UTF8.GetString(empty).EndsWith("Aplicado (NIO)\r\n"));
for(int i=0;i<101;i++)table.Rows.Add(d,"R"+i,"E_0000001","María, Pérez","Devolución","Efectivo",DBNull.Value,-1234.56m,-30m,-1264.56m);
var previous=System.Globalization.CultureInfo.CurrentCulture;
try
{
 System.Globalization.CultureInfo.CurrentCulture=new("es-ES");
 var csv=System.Text.Encoding.UTF8.GetString(LiceoWeb.Services.ReporteFinancieroCsv.Crear(table));
 CsvCheck("CSV incluye más de una página",csv.Split("\r\n").Length==103 && csv.Contains("\"R100\""));
 CsvCheck("CSV decimal independiente de cultura y negativos numéricos",csv.Contains(",-1234.56,-30.00,-1264.56\r\n"));
 CsvCheck("CSV conserva tildes y responsable ausente",csv.Contains("\"María, Pérez\"") && csv.Contains("\"Efectivo\",\"\",-"));
}
finally { System.Globalization.CultureInfo.CurrentCulture=previous; }
Console.WriteLine($"Total: {count} pruebas aprobadas.");
