using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class SyncLogRepository : ISyncLogRepository
{
    private readonly AppDbContext _context;

    public SyncLogRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<SyncLog> AddAsync(SyncLog syncLog, CancellationToken cancellationToken = default)
    {
        _context.SyncLogs.Add(syncLog);
        await _context.SaveChangesAsync(cancellationToken);
        return syncLog;
    }

    public async Task<IReadOnlyList<SyncLog>> GetRecentAsync(int take, CancellationToken cancellationToken = default)
        => await _context.SyncLogs.OrderByDescending(x => x.SyncTime).Take(take).ToListAsync(cancellationToken);
}
