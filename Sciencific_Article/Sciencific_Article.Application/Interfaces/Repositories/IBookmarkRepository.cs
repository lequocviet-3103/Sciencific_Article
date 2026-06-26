using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IBookmarkRepository
{
    Task<PagedResult<Bookmark>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<Bookmark?> GetAsync(string userId, string paperId, CancellationToken cancellationToken = default);
    Task<Bookmark> AddAsync(Bookmark bookmark, CancellationToken cancellationToken = default);
    Task RemoveAsync(Bookmark bookmark, CancellationToken cancellationToken = default);
    Task RemoveAsync(string bookmarkId, CancellationToken cancellationToken = default);
    Task<int> CountByUserAsync(string userId, CancellationToken cancellationToken = default);
}
