using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IReportRepository
{
    Task<PagedResult<Report>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<Report> AddAsync(Report report, CancellationToken cancellationToken = default);
}
