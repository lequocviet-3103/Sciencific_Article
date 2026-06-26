using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface ITrendRepository
{
    Task<IReadOnlyList<PublicationTrend>> GetByTopicAsync(string topicId, int? fromYear, int? toYear, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PublicationTrend>> AggregateByTopicAsync(string topicId, CancellationToken cancellationToken = default);
    Task<PublicationTrend> AddAsync(PublicationTrend trend, CancellationToken cancellationToken = default);
}
