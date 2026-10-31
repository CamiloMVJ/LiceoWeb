using LiceoWeb.Repositories;
using LiceoWeb.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using LiceoWeb.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

//DB
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));
builder.Services.AddScoped<SqlConnectionFactory>();
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
        policy.RequireRole("Administrador", "Profesor", "Cajero");
    });

    options.AddPolicy("GestionFinanciera", policy => policy.RequireAuthenticatedUser().RequireRole("Administrador", "Cajero"));
    options.AddPolicy("GestionAcademica", policy => policy.RequireAuthenticatedUser().RequireRole("Administrador", "Profesor"));

    options.AddPolicy("SoloAdministrador", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireRole("Administrador");
    });
});

// Rutas utilizadas por la cookie de autenticaci�n.
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Identity/Account/Login";
    options.AccessDeniedPath = "/Identity/Account/AccessDenied";
});

//Protecciones

builder.Services.AddRazorPages(options =>
{
    options.Conventions.AllowAnonymousToPage("/Index");
    options.Conventions.AuthorizeFolder("/Estudiantes", "GestionFinanciera");
    options.Conventions.AuthorizeFolder("/Cobros", "GestionFinanciera");
    options.Conventions.AuthorizeFolder("/Mensualidades", "GestionFinanciera");
    options.Conventions.AuthorizeFolder("/Matriculas", "GestionFinanciera");
    options.Conventions.AuthorizeFolder("/Recibos", "GestionFinanciera");
    options.Conventions.AuthorizeFolder("/Personal", "SoloAdministrador");

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

    // Permite mostrar errores aunque no haya una sesi�n.
    options.Conventions.AllowAnonymousToPage("/Error");
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<UsuarioActual>();
builder.Services.AddScoped<ExpedienteRepository>();
builder.Services.AddScoped<ExpedienteService>();
builder.Services.AddScoped<PlanificacionRepository>();
builder.Services.AddScoped<PlanificacionService>();
builder.Services.AddScoped<NotasRepository>();
builder.Services.AddScoped<ArancelRepository>();
builder.Services.AddScoped<ConciliacionRepository>();
builder.Services.AddScoped<CierreAcademicoRepository>();
builder.Services.AddScoped<NotasService>();
//builder.Services.AddRazorPages();

var app = builder.Build();

// Creaci�n manual de cuentas para desarrollo.
if (args.Contains("--crear-cuentas"))
{
    if (!app.Environment.IsDevelopment())
    {
        throw new InvalidOperationException(
            "Este comando solo est� habilitado en Development.");
    }

    await using var scope =
        app.Services.CreateAsyncScope();

    await IdentitySeeder.CrearCuentasAsync(
        scope.ServiceProvider,
        app.Configuration);

    Console.WriteLine(
        "Roles y cuentas iniciales verificados correctamente.");

    return;
}

// Comprobación manual de conexión para desarrollo.
if (args.Contains("--probar-conexion"))
{
    if (!app.Environment.IsDevelopment())
    {
        throw new InvalidOperationException(
            "Este comando solo está habilitado en Development.");
    }

    await using var scope =
        app.Services.CreateAsyncScope();

    var factory = scope.ServiceProvider
        .GetRequiredService<SqlConnectionFactory>();

    await using var connection = factory.Create();

    await connection.OpenAsync();

    using var command = connection.CreateCommand();

    command.CommandText = "SELECT DB_NAME();";

    var baseActual = await command.ExecuteScalarAsync();

    Console.WriteLine(
        $"Conexión correcta. Base de datos: {baseActual}");

    return;
}
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
