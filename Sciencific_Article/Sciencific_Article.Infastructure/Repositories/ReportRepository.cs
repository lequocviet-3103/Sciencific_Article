using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class ReportRepository : IReportRepository
{
    private readonly AppDbContext _context;

    public ReportRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<Report>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.Reports.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAt);
        var total = await q.CountAsync(cancellationToken);
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<Report> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<Report> AddAsync(Report report, CancellationToken cancellationToken = default)
    {
        _context.Reports.Add(report);
        await _context.SaveChangesAsync(cancellationToken);
        return report;
    }
}
