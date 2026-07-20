using Microsoft.Extensions.Hosting;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Services;

public class SyncBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;

    public SyncBackgroundService(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Wait 30 seconds on startup before first sync
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var syncService = scope.ServiceProvider.GetRequiredService<IOpenAlexSyncService>();
                await syncService.SyncWorksAsync(stoppingToken);
                await syncService.SyncPopularTopicsAsync(5, stoppingToken);
            }
            catch (Exception)
            {
                // Log and continue
            }

            await Task.Delay(TimeSpan.FromHours(12), stoppingToken);
        }
    }
}
