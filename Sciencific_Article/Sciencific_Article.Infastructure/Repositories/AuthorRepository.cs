using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class AuthorRepository : IAuthorRepository
{
    private readonly AppDbContext _context;

    public AuthorRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Author>> GetAllAsync(CancellationToken cancellationToken = default)
        => await _context.Authors.AsNoTracking().OrderBy(x => x.Name).ToListAsync(cancellationToken);

    public async Task<Author?> GetByIdAsync(string authorId, CancellationToken cancellationToken = default)
        => await _context.Authors.FirstOrDefaultAsync(x => x.AuthorId == authorId, cancellationToken);

    public async Task<Author?> GetByExternalIdAsync(string externalAuthorId, CancellationToken cancellationToken = default)
        => await _context.Authors.FirstOrDefaultAsync(x => x.ExternalAuthorId == externalAuthorId, cancellationToken);

    public async Task<Author> AddAsync(Author author, CancellationToken cancellationToken = default)
    {
        _context.Authors.Add(author);
        await _context.SaveChangesAsync(cancellationToken);
        return author;
    }

    public async Task UpdateAsync(Author author, CancellationToken cancellationToken = default)
    {
        _context.Authors.Update(author);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Author>> GetByNamesAsync(IEnumerable<string> names, CancellationToken cancellationToken = default)
        => await _context.Authors.Where(x => names.Contains(x.Name)).ToListAsync(cancellationToken);
}
