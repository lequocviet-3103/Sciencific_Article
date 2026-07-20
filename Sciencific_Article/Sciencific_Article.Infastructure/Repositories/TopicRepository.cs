using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class TopicRepository : ITopicRepository
{
    private readonly AppDbContext _context;

    public TopicRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ResearchTopic?> GetByIdAsync(string topicId, CancellationToken cancellationToken = default)
        => await _context.ResearchTopics.FirstOrDefaultAsync(x => x.TopicId == topicId, cancellationToken);

    public async Task<ResearchTopic?> GetByOpenAlexIdAsync(string openAlexId, CancellationToken cancellationToken = default)
        => await _context.ResearchTopics.FirstOrDefaultAsync(x => x.OpenAlexId == openAlexId, cancellationToken);

    public async Task<ResearchTopic> AddAsync(ResearchTopic topic, CancellationToken cancellationToken = default)
    {
        _context.ResearchTopics.Add(topic);
        await _context.SaveChangesAsync(cancellationToken);
        return topic;
    }

    public async Task UpdateAsync(ResearchTopic topic, CancellationToken cancellationToken = default)
    {
        _context.ResearchTopics.Update(topic);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<ResearchTopic>> GetFeaturedAsync(int take, CancellationToken cancellationToken = default)
        => await ProjectWithLocalPaperCount(_context.ResearchTopics)
            .Where(x => x.WorksCount > 0)
            .OrderByDescending(x => x.WorksCount)
            .ThenBy(x => x.Name)
            .Take(Math.Clamp(take, 1, 100))
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<ResearchTopic>> SearchAsync(string query, int take, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return await ProjectWithLocalPaperCount(_context.ResearchTopics)
                .Where(x => x.WorksCount > 0)
                .OrderByDescending(x => x.WorksCount)
                .ThenBy(x => x.Name)
                .Take(Math.Clamp(take, 1, 100))
                .ToListAsync(cancellationToken);
        }

        // Postgres LIKE is case-sensitive (unlike SQL Server), so a plain
        // .Contains() would miss "Quantum..." when the user types "quantum".
        return await ProjectWithLocalPaperCount(_context.ResearchTopics
            .Where(x => EF.Functions.ILike(x.Name, $"%{query}%")
                || (x.Field != null && EF.Functions.ILike(x.Field, $"%{query}%"))))
            .Where(x => x.WorksCount > 0)
            .OrderByDescending(x => x.WorksCount)
            .ThenBy(x => x.Name)
            .Take(Math.Clamp(take, 1, 100))
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Counts returned to Flutter represent papers actually available in the
    /// local database. They are derived from paper_topics rather than from a
    /// stale cached value or OpenAlex's global works_count.
    /// </summary>
    private static IQueryable<ResearchTopic> ProjectWithLocalPaperCount(
        IQueryable<ResearchTopic> query)
        => query.AsNoTracking().Select(x => new ResearchTopic
        {
            TopicId = x.TopicId,
            Name = x.Name,
            Field = x.Field,
            Domain = x.Domain,
            Subfield = x.Subfield,
            OpenAlexId = x.OpenAlexId,
            WorksCount = x.Papers.Count(),
            CreatedAt = x.CreatedAt,
            UpdatedAt = x.UpdatedAt,
        });
}
