using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IFollowTopicRepository
{
    Task<PagedResult<FollowTopic>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<FollowTopic?> GetAsync(string userId, string? keywordId, string? topicId, CancellationToken cancellationToken = default);
    Task<FollowTopic> AddAsync(FollowTopic followTopic, CancellationToken cancellationToken = default);
    Task RemoveAsync(string followTopicId, CancellationToken cancellationToken = default);
}
