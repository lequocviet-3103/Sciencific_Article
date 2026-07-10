using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Application.Mapping;
using Sciencific_Article.Application.Services;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;
using Sciencific_Article.Infastructure.Repositories;
using Sciencific_Article.Infastructure.Services;
using Sciencific_Article.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            // flutter run -d chrome/edge picks a random localhost port each
            // run, so allow any localhost/127.0.0.1 origin in dev instead of
            // hardcoding one.
            policy.SetIsOriginAllowed(origin =>
                    Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
                    (uri.Host == "localhost" || uri.Host == "127.0.0.1" || uri.Host == "10.0.2.2"))
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
        else
        {
            policy.WithOrigins(
                    "http://localhost:5255",
                    "http://10.0.2.2:5255",
                    "http://localhost:8080",
                    "http://localhost:52710")
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
    });
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"))
    .EnableSensitiveDataLogging());

var firebaseSection = builder.Configuration.GetSection("Firebase");
var firebaseProjectId = firebaseSection["project_id"] ?? firebaseSection["ProjectId"];
var serviceAccountPath = firebaseSection["ServiceAccountPath"];

if (string.IsNullOrWhiteSpace(serviceAccountPath))
{
    var tempPath = Path.Combine(Path.GetTempPath(), $"firebase-service-account-{Guid.NewGuid()}.json");
    var firebaseConfig = firebaseSection.GetChildren().ToDictionary(x => x.Key, x => x.Value?.ToString() ?? string.Empty);
    await File.WriteAllTextAsync(tempPath, JsonSerializer.Serialize(firebaseConfig));
    serviceAccountPath = tempPath;
}

var firebaseCredential = GoogleCredential.FromFile(serviceAccountPath);

FirebaseApp.Create(new AppOptions
{
    Credential = firebaseCredential,
    ProjectId = firebaseProjectId
});

QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

builder.Services.AddSingleton(firebaseCredential);
builder.Services.AddSingleton(new FirebaseStorageOptions($"{firebaseProjectId}.appspot.com"));

builder.Services.AddAutoMapper(typeof(MappingProfile));
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IPaperRepository, PaperRepository>();
builder.Services.AddScoped<IJournalRepository, JournalRepository>();
builder.Services.AddScoped<IAuthorRepository, AuthorRepository>();
builder.Services.AddScoped<IKeywordRepository, KeywordRepository>();
builder.Services.AddScoped<ITopicRepository, TopicRepository>();
builder.Services.AddScoped<IBookmarkRepository, BookmarkRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();
builder.Services.AddScoped<IFollowTopicRepository, FollowTopicRepository>();
builder.Services.AddScoped<ISyncLogRepository, SyncLogRepository>();
builder.Services.AddScoped<ITrendRepository, TrendRepository>();
builder.Services.AddScoped<IFirebaseAuthService, FirebaseAuthService>();
builder.Services.AddScoped<IFirebaseNotificationService, FirebaseNotificationService>();
builder.Services.AddScoped<IFirebaseStorageService, FirebaseStorageService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOpenAlexSyncService, OpenAlexSyncService>();
builder.Services.AddScoped<IReportGeneratorService, ReportGeneratorService>();
builder.Services.AddHostedService<Sciencific_Article.Services.SyncBackgroundService>();

builder.Services.AddHttpClient<IOpenAlexClient, OpenAlexClient>(client =>
{
    client.BaseAddress = new Uri("https://api.openalex.org");
    client.Timeout = TimeSpan.FromSeconds(100);
    client.DefaultRequestHeaders.Add("User-Agent", "SciencificArticleApp/1.0 (mailto:admin@example.com)");
});

var app = builder.Build();

// Seed roles so user creation can satisfy fk_users_role even on a fresh DB
// (after a TRUNCATE or first-time deploy). Uses fixed string IDs to match
// whatever the client passes in (e.g. "1"=Admin, "2"=Moderator, "3"=User).
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (!db.Roles.Any())
    {
        db.Roles.AddRange(
            new Role { RoleId = "1", RoleName = "Admin",    Description = "System administrator" },
            new Role { RoleId = "2", RoleName = "Moderator",Description = "Content moderator" },
            new Role { RoleId = "3", RoleName = "User",     Description = "Regular user" }
        );
        db.SaveChanges();
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors();
app.UseAuthorization();
app.MapControllers();
app.Run();
