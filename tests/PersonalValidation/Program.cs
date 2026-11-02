using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using LiceoWeb.Services;
using LiceoWeb.ViewModels;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using LiceoWeb.Pages.Personal;

var count=0;
void Check(bool ok,string name){if(!ok)throw new Exception(name);Console.WriteLine("OK: "+name);count++;}
bool Valid(PersonalInput input)=>Validator.TryValidateObject(input,new ValidationContext(input),new List<ValidationResult>(),true);
PersonalInput Good()=>new(){CuentaId="cuenta",Version="version",Rol="Profesor",Activa=true,Motivo="Cambio autorizado para pruebas"};
Check(Valid(Good()),"Entrada válida");
foreach(var role in new[]{"Administrador","Profesor","Cajero"}){var x=Good();x.Rol=role;Check(Valid(x),"Rol permitido: "+role);}
foreach(var role in new[]{"Visitante","administrador","Administrador ",""}){var x=Good();x.Rol=role;Check(!Valid(x),"Rechazo de rol: "+role);}
var input=Good();input.Motivo="          ";Check(!Valid(input),"Motivo vacío");
input=Good();input.Motivo=new string('x',501);Check(!Valid(input),"Motivo largo");
input=Good();input.Operacion=Guid.Empty;Check(!Valid(input),"Sin idempotencia");
input=Good();input.Version="";Check(!Valid(input),"Sin versión");
input=Good();input.CuentaId="";Check(!Valid(input),"Sin cuenta");

// Verifica la obligatoriedad que MVC infiere; Validator.TryValidateObject no
// detecta el Required implícito de las referencias no anulables.
var services=new ServiceCollection();services.AddLogging();services.AddControllersWithViews();
using var provider=services.BuildServiceProvider();
var metadata=provider.GetRequiredService<IModelMetadataProvider>();
Check(!metadata.GetMetadataForProperty(typeof(AdministrarModel),nameof(AdministrarModel.Busqueda)).IsRequired,"Búsqueda opcional al guardar personal");
Check(metadata.GetMetadataForProperty(typeof(PersonalInput),nameof(PersonalInput.Rol)).IsRequired,"MVC conserva rol obligatorio");
Check(metadata.GetMetadataForProperty(typeof(PersonalInput),nameof(PersonalInput.Motivo)).IsRequired,"MVC conserva motivo obligatorio");

var opts=Options.Create(new IdentityOptions());opts.Value.SignIn.RequireConfirmedAccount=true;
var user=new IdentityUser("empleado"){Id="empleado",EmailConfirmed=true,SecurityStamp="original"};
using var users=new FakeUsers(user,opts);
var state=new FakeState();
var manager=new PersonalSignInManager(users,new HttpContextAccessor{HttpContext=new DefaultHttpContext()},
 new UserClaimsPrincipalFactory<IdentityUser>(users,opts),opts,NullLogger<SignInManager<IdentityUser>>.Instance,
 new AuthenticationSchemeProvider(Options.Create(new AuthenticationOptions())),new DefaultUserConfirmation<IdentityUser>(),state);
Check(await manager.CanSignInAsync(user),"Cuenta activa inicia sesión");
user.EmailConfirmed=false;Check(!await manager.CanSignInAsync(user),"Conserva requisito de correo confirmado");user.EmailConfirmed=true;
state.Active=false;Check(!await manager.CanSignInAsync(user),"Baja impide inicio de sesión");
Check(!await manager.ValidateSecurityStampAsync(user,"original"),"Baja rechaza sello incluso si coincide");
var principal=new ClaimsPrincipal(new ClaimsIdentity(new[]{new Claim(ClaimTypes.NameIdentifier,user.Id),new Claim(opts.Value.ClaimsIdentity.SecurityStampClaimType,"original")}));
Check(await manager.ValidateSecurityStampAsync(principal) is null,"Cookie normal de cuenta desactivada rechazada");
var twofactor=new ClaimsPrincipal(new ClaimsIdentity(new[]{new Claim(ClaimTypes.Name,user.Id),new Claim(opts.Value.ClaimsIdentity.SecurityStampClaimType,"original")}));
Check(await manager.ValidateTwoFactorSecurityStampAsync(twofactor) is null,"Cookie de segundo factor desactivada rechazada");
state.Active=true;
Check(await manager.ValidateSecurityStampAsync(principal) is not null,"Cookie válida activa aceptada");
Check(await manager.ValidateTwoFactorSecurityStampAsync(twofactor) is not null,"Cookie de segundo factor activa aceptada");
user.SecurityStamp="nuevo";
Check(await manager.ValidateSecurityStampAsync(principal) is null,"Cambio de sello revoca cookie anterior");
Check(await manager.ValidateTwoFactorSecurityStampAsync(twofactor) is null,"Cambio de sello revoca cookie de segundo factor");
Check(!await manager.ValidateSecurityStampAsync(null,"nuevo"),"Usuario inexistente rechazado");
Console.WriteLine($"{count} pruebas correctas; sin conexión SQL Server.");

sealed class FakeState:IEstadoCuentaPersonal{public bool Active=true;public Task<bool> EstaActivaAsync(string id)=>Task.FromResult(Active);}
sealed class FakeUsers(IdentityUser user,IOptions<IdentityOptions> options):UserManager<IdentityUser>(new EmptyStore(),options,new PasswordHasher<IdentityUser>(),[],[],new UpperInvariantLookupNormalizer(),new IdentityErrorDescriber(),null!,NullLogger<UserManager<IdentityUser>>.Instance)
{
 public override bool SupportsUserSecurityStamp=>true;
 public override Task<string> GetSecurityStampAsync(IdentityUser value)=>Task.FromResult(value.SecurityStamp!);
 public override Task<IdentityUser?> FindByIdAsync(string id)=>Task.FromResult<IdentityUser?>(id==user.Id?user:null);
 public override Task<bool> IsEmailConfirmedAsync(IdentityUser value)=>Task.FromResult(value.EmailConfirmed);
}
sealed class EmptyStore:IUserStore<IdentityUser>
{
 public void Dispose(){}
 public Task<string> GetUserIdAsync(IdentityUser user,CancellationToken ct)=>Task.FromResult(user.Id);
 public Task<string?> GetUserNameAsync(IdentityUser user,CancellationToken ct)=>Task.FromResult(user.UserName);
 public Task SetUserNameAsync(IdentityUser user,string? name,CancellationToken ct)=>throw new NotSupportedException();
 public Task<string?> GetNormalizedUserNameAsync(IdentityUser user,CancellationToken ct)=>Task.FromResult(user.NormalizedUserName);
 public Task SetNormalizedUserNameAsync(IdentityUser user,string? name,CancellationToken ct)=>throw new NotSupportedException();
 public Task<IdentityResult> CreateAsync(IdentityUser user,CancellationToken ct)=>throw new NotSupportedException();
 public Task<IdentityResult> UpdateAsync(IdentityUser user,CancellationToken ct)=>throw new NotSupportedException();
 public Task<IdentityResult> DeleteAsync(IdentityUser user,CancellationToken ct)=>throw new NotSupportedException();
 public Task<IdentityUser?> FindByIdAsync(string id,CancellationToken ct)=>throw new NotSupportedException();
 public Task<IdentityUser?> FindByNameAsync(string name,CancellationToken ct)=>throw new NotSupportedException();
}
