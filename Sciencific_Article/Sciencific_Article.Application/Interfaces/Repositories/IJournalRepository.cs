using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IJournalRepository
{
    Task<Journal?> GetByIdAsync(string journalId, CancellationToken cancellationToken = default);
    Task<Journal?> GetByNameAsync(string name, CancellationToken cancellationToken = default);
    Task<Journal> AddAsync(Journal journal, CancellationToken cancellationToken = default);
    Task UpdateAsync(Journal journal, CancellationToken cancellationToken = default);
}
