using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class FollowTopicRepository : IFollowTopicRepository
{
    private readonly AppDbContext _context;

    public FollowTopicRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<FollowTopic>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.FollowTopics.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAt);
        var total = await q.CountAsync(cancellationToken);
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<FollowTopic> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<FollowTopic?> GetAsync(string userId, string? keywordId, string? topicId, CancellationToken cancellationToken = default)
        => await _context.FollowTopics.FirstOrDefaultAsync(x => x.UserId == userId && x.KeywordId == keywordId && x.TopicId == topicId, cancellationToken);

    public async Task<FollowTopic> AddAsync(FollowTopic followTopic, CancellationToken cancellationToken = default)
    {
        _context.FollowTopics.Add(followTopic);
        await _context.SaveChangesAsync(cancellationToken);
        return followTopic;
    }

    public async Task RemoveAsync(string followTopicId, CancellationToken cancellationToken = default)
    {
        var entity = await _context.FollowTopics.FirstOrDefaultAsync(x => x.FollowTopicId == followTopicId, cancellationToken);
        if (entity == null) return;
        _context.FollowTopics.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
    }
}
