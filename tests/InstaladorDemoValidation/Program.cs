using Microsoft.AspNetCore.Identity;
using System.Text.RegularExpressions;
var seed = File.ReadAllText(args.Length>0 ? args[0] : "LiceoWeb/database/seeds/002_Demostracion.sql");
var matches = Regex.Matches(seed, @"\(N'demo-[^']+',N'([^']+)',N'([^']+)',N'([^']+)'\)");
if (matches.Count!=3) throw new Exception("Se esperaban exactamente tres cuentas.");
var roles = new HashSet<string>();
var hasher = new PasswordHasher<IdentityUser>();
foreach (Match m in matches)
{
 var user = new IdentityUser(m.Groups[1].Value) { Email=m.Groups[1].Value };
 if (hasher.VerifyHashedPassword(user,m.Groups[3].Value,"Admin1234#") == PasswordVerificationResult.Failed)
  throw new Exception("El hash no coincide con la contraseña de demostración.");
 if (!roles.Add(m.Groups[2].Value)) throw new Exception("Rol de demostración duplicado.");
 Console.WriteLine("PASS: cuenta y contraseña Identity de "+m.Groups[2].Value);
}
if (!roles.SetEquals(["Administrador","Profesor","Cajero"])) throw new Exception("Roles inesperados.");
Console.WriteLine("PASS: las tres cuentas tienen roles distintos y contraseñas válidas.");
