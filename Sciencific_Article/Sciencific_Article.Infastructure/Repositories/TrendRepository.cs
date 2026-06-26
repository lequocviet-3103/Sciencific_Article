using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class TrendRepository : ITrendRepository
{
    private readonly AppDbContext _context;

    public TrendRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<PublicationTrend>> GetByTopicAsync(string topicId, int? fromYear, int? toYear, CancellationToken cancellationToken = default)
    {
        var q = _context.PublicationTrends.AsNoTracking().Where(x => x.TopicId == topicId);

        if (fromYear.HasValue) q = q.Where(x => x.Year >= fromYear.Value);
        if (toYear.HasValue) q = q.Where(x => x.Year <= toYear.Value);

        return await q.OrderBy(x => x.Year).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<PublicationTrend>> AggregateByTopicAsync(string topicId, CancellationToken cancellationToken = default)
        => await GetByTopicAsync(topicId, null, null, cancellationToken);

    public async Task<PublicationTrend> AddAsync(PublicationTrend trend, CancellationToken cancellationToken = default)
    {
        _context.PublicationTrends.Add(trend);
        await _context.SaveChangesAsync(cancellationToken);
        return trend;
    }
}
