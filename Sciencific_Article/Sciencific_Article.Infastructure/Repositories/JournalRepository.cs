using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class JournalRepository : IJournalRepository
{
    private readonly AppDbContext _context;

    public JournalRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Journal>> GetAllAsync(CancellationToken cancellationToken = default)
        => await _context.Journals.AsNoTracking().OrderBy(x => x.Name).ToListAsync(cancellationToken);

    public async Task<Journal?> GetByIdAsync(string journalId, CancellationToken cancellationToken = default)
        => await _context.Journals.FirstOrDefaultAsync(x => x.JournalId == journalId, cancellationToken);

    public async Task<Journal?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
        => await _context.Journals.FirstOrDefaultAsync(x => x.Name == name, cancellationToken);

    public async Task<Journal> AddAsync(Journal journal, CancellationToken cancellationToken = default)
    {
        _context.Journals.Add(journal);
        await _context.SaveChangesAsync(cancellationToken);
        return journal;
    }

    public async Task UpdateAsync(Journal journal, CancellationToken cancellationToken = default)
    {
        _context.Journals.Update(journal);
        await _context.SaveChangesAsync(cancellationToken);
    }
}
