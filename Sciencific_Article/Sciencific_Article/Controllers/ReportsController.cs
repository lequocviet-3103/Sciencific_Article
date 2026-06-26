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
    private readonly IFirebaseStorageService _storageService;

    public ReportsController(AppDbContext context, IFirebaseStorageService storageService)
    {
        _context = context;
        _storageService = storageService;
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

    [HttpPost]
    public async Task<IActionResult> CreateReport(
        [FromBody] CreateReportRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))
            return BadRequest(new { message = "UserId is required" });

        var reportId = Guid.NewGuid().ToString();
        string? fileUrl = null;

        if (!string.IsNullOrWhiteSpace(request.PdfBase64))
        {
            try
            {
                var bytes = Convert.FromBase64String(request.PdfBase64);
                using var stream = new MemoryStream(bytes);
                var fileName = $"reports/{reportId}.pdf";
                fileUrl = await _storageService.UploadAsync(
                    string.Empty,
                    fileName,
                    stream,
                    "application/pdf",
                    cancellationToken);
            }
            catch
            {
                fileUrl = null;
            }
        }

        var report = new Domain.Entities.Report
        {
            ReportId = reportId,
            UserId = request.UserId,
            TopicId = request.TopicId,
            ReportType = request.ReportType ?? "Trend Report",
            FileUrl = fileUrl,
            CreatedAt = DateTime.Now
        };

        _context.Reports.Add(report);
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            reportId = report.ReportId,
            fileUrl = report.FileUrl,
            createdAt = report.CreatedAt?.ToString("o")
        });
    }
}

public class CreateReportRequest
{
    public string UserId { get; set; } = string.Empty;
    public string? TopicId { get; set; }
    public string? ReportType { get; set; }
    public string? PdfBase64 { get; set; }
}
