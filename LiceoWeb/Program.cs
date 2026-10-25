using LiceoWeb.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

//DB
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();

//Identity y Roles

builder.Services.AddDefaultIdentity<IdentityUser>(options =>
{
    options.SignIn.RequireConfirmedAccount = true;
    options.User.RequireUniqueEmail = true;
})
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

//Politicas y auth

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("OperarSistema", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireRole("Administrador", "Profesor");
    });

    options.AddPolicy("SoloAdministrador", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireRole("Administrador");
    });
});

// Rutas utilizadas por la cookie de autenticación.
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Identity/Account/Login";
    options.AccessDeniedPath = "/Identity/Account/AccessDenied";
});

//Protecciones

builder.Services.AddRazorPages(options =>
{
    options.Conventions.AuthorizeFolder(
        "/", "OperarSistema");

    options.Conventions.AuthorizeFolder(
        "/Precios", "SoloAdministrador");

    options.Conventions.AuthorizeFolder(
        "/Arreglos", "SoloAdministrador");

    options.Conventions.AuthorizeFolder(
        "/Reportes", "SoloAdministrador");

    options.Conventions.AuthorizePage(
        "/Estudiantes/Editar", "SoloAdministrador");

    options.Conventions.AuthorizePage(
        "/Estudiantes/DarBaja", "SoloAdministrador");

    // Permite mostrar errores aunque no haya una sesión.
    options.Conventions.AllowAnonymousToPage("/Error");
});

//builder.Services.AddRazorPages();

var app = builder.Build();

//Procesamiento de solicitudes
// Configure the HTTP request  pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapRazorPages();

app.Run();
