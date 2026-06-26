using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface ITopicRepository
{
    Task<ResearchTopic?> GetByIdAsync(string topicId, CancellationToken cancellationToken = default);
    Task<ResearchTopic?> GetByOpenAlexIdAsync(string openAlexId, CancellationToken cancellationToken = default);
    Task<ResearchTopic> AddAsync(ResearchTopic topic, CancellationToken cancellationToken = default);
    Task UpdateAsync(ResearchTopic topic, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ResearchTopic>> GetFeaturedAsync(int take, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ResearchTopic>> SearchAsync(string query, int take, CancellationToken cancellationToken = default);
}
