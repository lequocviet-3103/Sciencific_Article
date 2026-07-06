using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IReportGeneratorService _reportGenerator;

    public ReportsController(
        AppDbContext context,
        IReportGeneratorService reportGenerator)
    {
        _context = context;
        _reportGenerator = reportGenerator;
    }

    /// User searches a topic → backend computes the publication trend, top
    /// authors and top journals for the matching papers, renders a PDF,
    /// uploads it to Firebase Storage and saves the resulting report row.
    [HttpPost("generate")]
    public async Task<IActionResult> GenerateReport(
        [FromBody] GenerateReportRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))
            return BadRequest(new { message = "UserId is required" });

        var report = await _reportGenerator.GenerateDashboardReportAsync(
            request.UserId,
            request.Query,
            request.TopicId,
            cancellationToken);

        return Ok(new
        {
            reportId = report.ReportId,
            fileUrl = report.FileUrl,
            reportType = report.ReportType,
            topicId = report.TopicId,
            createdAt = report.CreatedAt?.ToString("o"),
        });
    }

    [HttpGet]
    public async Task<IActionResult> GetReports(
        [FromQuery] string? userId,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Reports.AsQueryable();
        if (!string.IsNullOrWhiteSpace(userId))
            query = query.Where(r => r.UserId == userId);

        var reports = await query
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(cancellationToken);

        return Ok(reports.Select(r => new
        {
            r.ReportId,
            r.UserId,
            r.TopicId,
            r.ReportType,
            r.FileUrl,
            CreatedAt = r.CreatedAt?.ToString("o")
        }));
    }

}

public class GenerateReportRequest
{
    public string UserId { get; set; } = string.Empty;
    public string? Query { get; set; }
    public string? TopicId { get; set; }
}
