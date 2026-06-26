using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class KeywordRepository : IKeywordRepository
{
    private readonly AppDbContext _context;

    public KeywordRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Keyword>> GetAllAsync(CancellationToken cancellationToken = default)
        => await _context.Keywords.AsNoTracking().OrderBy(x => x.Name).ToListAsync(cancellationToken);

    public async Task<Keyword?> GetByIdAsync(string keywordId, CancellationToken cancellationToken = default)
        => await _context.Keywords.FirstOrDefaultAsync(x => x.KeywordId == keywordId, cancellationToken);

    public async Task<Keyword?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
        => await _context.Keywords.FirstOrDefaultAsync(x => x.Name == name, cancellationToken);

    public async Task<Keyword> AddAsync(Keyword keyword, CancellationToken cancellationToken = default)
    {
        _context.Keywords.Add(keyword);
        await _context.SaveChangesAsync(cancellationToken);
        return keyword;
    }

    public async Task<IReadOnlyList<Keyword>> GetOrCreateAsync(IEnumerable<string> names, CancellationToken cancellationToken = default)
    {
        var existing = await _context.Keywords.Where(x => names.Contains(x.Name)).ToListAsync(cancellationToken);
        var existingNames = new HashSet<string>(existing.Select(x => x.Name));
        var toAdd = names.Except(existingNames).Select(n => new Keyword { KeywordId = Guid.NewGuid().ToString(), Name = n }).ToList();

        if (toAdd.Any())
        {
            _context.Keywords.AddRange(toAdd);
            await _context.SaveChangesAsync(cancellationToken);
        }

        return existing.Concat(toAdd).ToList();
    }
}
