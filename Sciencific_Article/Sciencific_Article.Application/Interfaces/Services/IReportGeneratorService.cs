using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Services;

public interface IReportGeneratorService
{
    /// Computes the publication trend, top authors and top journals for
    /// papers matching <paramref name="query"/> (and/or <paramref name="topicId"/>),
    /// renders them into a PDF, uploads it to Firebase Storage and persists
    /// a Report row pointing at the resulting URL.
    Task<Report> GenerateDashboardReportAsync(
        string userId,
        string? query,
        string? topicId,
        CancellationToken cancellationToken = default);
}
