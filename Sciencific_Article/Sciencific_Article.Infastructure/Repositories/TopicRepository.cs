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
        => await _context.ResearchTopics.OrderByDescending(x => x.WorksCount).Take(take).ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<ResearchTopic>> SearchAsync(string query, int take, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return await _context.ResearchTopics.OrderByDescending(x => x.WorksCount).Take(take).ToListAsync(cancellationToken);
        }

        return await _context.ResearchTopics
            .Where(x => x.Name.Contains(query) || (x.Field != null && x.Field.Contains(query)))
            .OrderByDescending(x => x.WorksCount)
            .Take(take)
            .ToListAsync(cancellationToken);
    }
}
