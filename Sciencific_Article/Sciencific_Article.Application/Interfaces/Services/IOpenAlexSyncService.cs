namespace Sciencific_Article.Application.Interfaces.Services;

public interface IOpenAlexSyncService
{
    Task<string> SyncWorksAsync(CancellationToken cancellationToken = default);
    Task<string> SyncJournalsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncAuthorsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncTopicsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncKeywordsAsync(CancellationToken cancellationToken = default);
    Task<string> RecomputeTrendsAsync(CancellationToken cancellationToken = default);
}
