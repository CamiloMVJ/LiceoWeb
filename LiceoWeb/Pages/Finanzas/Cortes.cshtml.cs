using System.ComponentModel.DataAnnotations;
using System.Data;
using LiceoWeb.Data;
using LiceoWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
namespace LiceoWeb.Pages.Finanzas;

[Authorize(Policy="SoloAdministrador")]
[ResponseCache(NoStore=true,Location=ResponseCacheLocation.None)]
public class CortesModel(SqlConnectionFactory factory, UsuarioActual usuario, ILogger<CortesModel> logger):PageModel
{
 public sealed class CorteInput:IValidatableObject
 {
  public Guid Operacion {get;set;}=Guid.NewGuid();
  public long CorteId {get;set;}
  [Required,RegularExpression("^(Abrir|Cerrar|CerrarAbrir)$")] public string Accion {get;set;}="Abrir";
  public decimal Fondo {get;set;}
  public decimal? Contado {get;set;}
  [Required,StringLength(500,MinimumLength=10)] public string Motivo {get;set;}="";
  public IEnumerable<ValidationResult> Validate(ValidationContext context)
  {
   if(Accion=="Cerrar" && Fondo!=0)yield return new("Para cerrar sin abrir otro corte, el fondo nuevo debe ser cero.");
   if(Operacion==Guid.Empty)yield return new("Recarga para identificar la operación.");
   if(Fondo<0 || Fondo>9999999999999999.99m || decimal.Round(Fondo,2)!=Fondo)yield return new("Fondo inválido.");
   if(Accion!="Abrir" && (CorteId<=0 || Contado is null or <0 or >9999999999999999.99m || decimal.Round(Contado.Value,2)!=Contado))
    yield return new("Indica el efectivo contado del corte abierto.");
  }
 }
 public CorteInput Input {get;set;}=new();
 public DataSet Datos {get;private set;}=new();
 public bool Cargado=>Datos.Tables.Contains("Metodos");
 public bool Migrado=>Cargado && Datos.Tables["Control"]!.Rows[0].Field<bool>("Migrado");
 public IEnumerable<DataRow> Cortes=>Datos.Tables["Cortes"]?.AsEnumerable() is {} rows?rows:[];
 public DataRow? Abierto=>Cortes.FirstOrDefault(r=>r.IsNull("Fin"));
 public DataRow? Elegido=>Cortes.FirstOrDefault(r=>r.Field<long>("Id")==Id) ?? Abierto;
 [BindProperty(SupportsGet=true)] public long Id {get;set;}
 [TempData] public string? Mensaje {get;set;}
 public decimal EfectivoEsperado=>Abierto is {} a && Elegido==Abierto
  ? a.Field<decimal>("FondoApertura")+Datos.Tables["Metodos"]!.AsEnumerable().Where(r=>r.Field<string>("Metodo")=="Efectivo").Sum(r=>r.Field<decimal>("Neto")):0;
 public async Task<IActionResult> OnGetAsync()
 {
  if(Id<0)return BadRequest();await Cargar();
  if(Abierto is {} a){Input.CorteId=a.Field<long>("Id");Input.Accion="CerrarAbrir";}
  return Page();
 }
 public async Task<IActionResult> OnPostAsync([FromForm(Name="Input")]CorteInput input)
 {
  Input=input;
  if(ModelState.IsValid)try
  {
   await using var c=factory.Create();await c.OpenAsync();
   await using var cmd=new SqlCommand("dbo.CorteCaja_Operar",c){CommandType=CommandType.StoredProcedure};
   cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();
   cmd.Parameters.Add("@Operacion",SqlDbType.UniqueIdentifier).Value=input.Operacion;
   cmd.Parameters.Add("@Accion",SqlDbType.NVarChar,20).Value=input.Accion;
   cmd.Parameters.Add("@CorteId",SqlDbType.BigInt).Value=input.CorteId;
   foreach(var (n,v) in new[]{("@Fondo",(decimal?)input.Fondo),("@Contado",input.Contado)})
   {var p=cmd.Parameters.Add(n,SqlDbType.Decimal);p.Precision=28;p.Scale=8;p.Value=(object?)v??DBNull.Value;}
   cmd.Parameters.Add("@Motivo",SqlDbType.NVarChar,500).Value=input.Motivo;
   await cmd.ExecuteNonQueryAsync();
   Mensaje="Operación de caja guardada. El cierre y su resumen permanecen en el historial.";
   return RedirectToPage();
  }
  catch(SqlException ex) when(ex.Number==53601){return Forbid();}
  catch(SqlException ex) when(ex.Number is >=54800 and <=54803){ModelState.AddModelError("",ex.Message);}
  catch(Exception ex){logger.LogError(ex,"Operación de corte no confirmada");ModelState.AddModelError("","No se pudo confirmar. Consulta el historial y conserva esta operación para reintentar.");}
  Id=0;await Cargar();return Page();
 }
 private async Task Cargar()
 {
  try
  {
   await using var c=factory.Create();await c.OpenAsync();
   await using var cmd=new SqlCommand("dbo.CorteCaja_Consultar",c){CommandType=CommandType.StoredProcedure};
   cmd.Parameters.Add("@UsuarioId",SqlDbType.NVarChar,450).Value=usuario.ObtenerId();
   cmd.Parameters.Add("@Id",SqlDbType.BigInt).Value=Id;
   await using var r=await cmd.ExecuteReaderAsync();var ds=new DataSet();
   foreach(var n in new[]{"Control","Cortes","Metodos"}){var t=new DataTable(n);t.Load(r);ds.Tables.Add(t);}Datos=ds;
  }
  catch(Exception ex){logger.LogError(ex,"Consultar cortes");ModelState.AddModelError("","No se pudieron cargar los cortes. Verifica la migración 024 y CortesCaja.sql.");}
 }
}
