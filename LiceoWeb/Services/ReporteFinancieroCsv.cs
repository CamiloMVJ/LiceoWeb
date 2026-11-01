using System.Data;
using System.Globalization;
using System.Text;

namespace LiceoWeb.Services;

public static class ReporteFinancieroCsv
{
    // Texto controlado por usuarios: impedir fórmulas al abrir en una hoja de cálculo.
    public static string Texto(string value)
    {
        var first = value.TrimStart();
        if (first.Length > 0 && "=+-@".Contains(first[0]) ||
            value.StartsWith('\t') || value.StartsWith('\r') || value.StartsWith('\n'))
            value = "'" + value;
        return "\"" + value.Replace("\"", "\"\"") + "\"";
    }

    public static byte[] Crear(DataTable movimientos)
    {
        var csv = new StringBuilder("Fecha local (UTC-6),Recibo,Registro,Estudiante,Movimiento,Metodo,Responsable,Dinero (NIO),Saldo (NIO),Aplicado (NIO)\r\n");
        foreach (DataRow row in movimientos.Rows)
        {
            var fields = new List<string> { Texto(((DateTime)row["FechaLocal"]).ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture)) };
            foreach (var name in new[] { "Numero", "Registro", "NombreEstudiante", "Tipo", "Metodo", "Responsable" })
                fields.Add(Texto(Convert.ToString(row[name], CultureInfo.InvariantCulture) ?? ""));
            foreach (var name in new[] { "Dinero", "Saldo", "Aplicado" })
                fields.Add(((decimal)row[name]).ToString("0.00", CultureInfo.InvariantCulture));
            csv.AppendJoin(',', fields).Append("\r\n");
        }
        // BOM para que Excel reconozca correctamente los nombres con tildes.
        return Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.ToString())).ToArray();
    }
}
