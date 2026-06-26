using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Application.Services;

public class SyncBackgroundService
{
    private readonly IOpenAlexSyncService _syncService;

    public SyncBackgroundService(IOpenAlexSyncService syncService)
    {
        _syncService = syncService;
    }

    public Task<string> RunOnceAsync(CancellationToken cancellationToken = default)
    {
        return _syncService.SyncWorksAsync(cancellationToken);
    }
}
