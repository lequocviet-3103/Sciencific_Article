using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IAuthorRepository
{
    Task<Author?> GetByIdAsync(string authorId, CancellationToken cancellationToken = default);
    Task<Author?> GetByExternalIdAsync(string externalAuthorId, CancellationToken cancellationToken = default);
    Task<Author> AddAsync(Author author, CancellationToken cancellationToken = default);
    Task UpdateAsync(Author author, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Author>> GetByNamesAsync(IEnumerable<string> names, CancellationToken cancellationToken = default);
}
