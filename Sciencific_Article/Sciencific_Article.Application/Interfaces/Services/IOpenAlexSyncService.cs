namespace Sciencific_Article.Application.Interfaces.Services;

public interface IOpenAlexSyncService
{
    Task<string> SyncWorksAsync(CancellationToken cancellationToken = default);
    Task<SyncWorksResult> SyncWorksAsync(
        int requestedCount,
        CancellationToken cancellationToken = default);
    Task<string> SyncJournalsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncAuthorsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncTopicsAsync(CancellationToken cancellationToken = default);
    Task<string> SyncKeywordsAsync(CancellationToken cancellationToken = default);
    Task<string> RecomputeTrendsAsync(CancellationToken cancellationToken = default);

    /// Pulls more works from OpenAlex matching `query` and persists them if
    /// the DB has fewer than `minResults` matches already, so search becomes
    /// DB-backed instead of a perpetual live pass-through. Returns the
    /// number of newly inserted papers (0 if the DB already had enough).
    Task<int> EnsureWorksSyncedForQueryAsync(
        string query,
        int minResults = 15,
        int maxPages = 2,
        CancellationToken cancellationToken = default);

    Task<int> EnsureTopicsSyncedForQueryAsync(
        string query,
        int minResults = 5,
        CancellationToken cancellationToken = default);
}

public sealed record SyncWorksResult(
    int RequestedCount,
    int InsertedCount,
    int SkippedDuplicates,
    int ScannedCount,
    bool SourceExhausted)
{
    public string Message => InsertedCount >= RequestedCount
        ? $"Synced {InsertedCount} new papers from OpenAlex. " +
          $"Skipped {SkippedDuplicates} duplicates while scanning {ScannedCount} works."
        : $"Synced {InsertedCount}/{RequestedCount} requested new papers from OpenAlex. " +
          $"Skipped {SkippedDuplicates} duplicates while scanning {ScannedCount} works. " +
          (SourceExhausted
              ? "OpenAlex returned no more works."
              : "The safe scan limit was reached; run sync again to continue.");
}
