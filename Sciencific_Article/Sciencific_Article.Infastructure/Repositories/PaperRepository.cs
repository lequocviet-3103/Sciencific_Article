using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class PaperRepository : IPaperRepository
{
    private readonly AppDbContext _context;

    public PaperRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<Paper>> SearchAsync(string? query, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.Papers.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            q = q.Where(x => x.Title.Contains(query) || (x.Abstract != null && x.Abstract.Contains(query)));
        }

        var total = await q.CountAsync(cancellationToken);
        var items = await q.OrderByDescending(x => x.PublicationYear).ThenByDescending(x => x.CitationCount).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);

        return new PagedResult<Paper> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    /*public async Task<PagedResult<Paper>> GetByTopicAsync(string topicId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.Papers.AsNoTracking().Where(x => x.PapersTopics.Any(pt => pt.TopicId == topicId));
        var total = await q.CountAsync(cancellationToken);
        var items = await q.OrderByDescending(x => x.PublicationYear).ThenByDescending(x => x.CitationCount).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<Paper> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }*/

    public async Task<Paper?> GetByIdAsync(string paperId, CancellationToken cancellationToken = default)
        => await _context.Papers.Include(x => x.Journal).FirstOrDefaultAsync(x => x.PaperId == paperId, cancellationToken);

    public async Task AddAsync(Paper paper, CancellationToken cancellationToken = default)
    {
        _context.Papers.Add(paper);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(Paper paper, CancellationToken cancellationToken = default)
    {
        _context.Papers.Update(paper);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Paper>> GetByIdsAsync(IEnumerable<string> paperIds, CancellationToken cancellationToken = default)
        => await _context.Papers.Where(x => paperIds.Contains(x.PaperId)).ToListAsync(cancellationToken);

    public Task<PagedResult<Paper>> GetByTopicAsync(string topicId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}
