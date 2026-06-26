using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IKeywordRepository
{
    Task<Keyword?> GetByIdAsync(string keywordId, CancellationToken cancellationToken = default);
    Task<Keyword?> GetByNameAsync(string name, CancellationToken cancellationToken = default);
    Task<Keyword> AddAsync(Keyword keyword, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Keyword>> GetOrCreateAsync(IEnumerable<string> names, CancellationToken cancellationToken = default);
}
