using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Application.Mapping;
using Sciencific_Article.Application.Services;
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
        policy.WithOrigins(
                "http://localhost:5255",
                "http://10.0.2.2:5255",
                "http://localhost:8080",
                "http://localhost:52710")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials());
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")));

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

FirebaseApp.Create(new AppOptions
{
    Credential = GoogleCredential.FromFile(serviceAccountPath),
    ProjectId = firebaseProjectId
});

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
builder.Services.AddHostedService<Sciencific_Article.Services.SyncBackgroundService>();

builder.Services.AddHttpClient<IOpenAlexClient, OpenAlexClient>(client =>
{
    client.BaseAddress = new Uri("https://api.openalex.org");
    client.Timeout = TimeSpan.FromSeconds(100);
    client.DefaultRequestHeaders.Add("User-Agent", "SciencificArticleApp/1.0 (mailto:admin@example.com)");
});

var app = builder.Build();



if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();
app.MapControllers();
app.Run();
