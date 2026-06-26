using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface ISyncLogRepository
{
    Task<SyncLog> AddAsync(SyncLog syncLog, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<SyncLog>> GetRecentAsync(int take, CancellationToken cancellationToken = default);
}
