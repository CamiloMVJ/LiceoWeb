using System.IO;
using System.Text.RegularExpressions;
namespace LiceoWeb.Data;

// SQL puede devolver rowversion como binary(8) o como hexadecimal convertido.
// byte[].ToString() devuelve "System.Byte[]", que no es un token de versión.
public static class RowVersionToken
{
    public static string DesdeSql(object valor) => valor switch
    {
        byte[] { Length: 8 } bytes => "0x" + Convert.ToHexString(bytes),
        string texto when Regex.IsMatch(texto, "\\A0x[0-9A-Fa-f]{16}\\z") => texto,
        _ => throw new InvalidDataException("La base no devolvió una versión de registro válida de 8 bytes.")
    };
}
