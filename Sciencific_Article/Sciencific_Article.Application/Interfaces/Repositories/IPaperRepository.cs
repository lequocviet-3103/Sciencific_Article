using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IPaperRepository
{
    Task<PagedResult<Paper>> SearchAsync(string? query, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<PagedResult<Paper>> GetByTopicAsync(string topicId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<Paper?> GetByIdAsync(string paperId, CancellationToken cancellationToken = default);
    Task AddAsync(Paper paper, CancellationToken cancellationToken = default);
    Task UpdateAsync(Paper paper, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Paper>> GetByIdsAsync(IEnumerable<string> paperIds, CancellationToken cancellationToken = default);
}
