using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/dashboard")]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _context;

    public DashboardController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetDashboard(
        [FromQuery] string? topicId,
        [FromQuery] int? year,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Papers
            .Include(p => p.Journal)
            .AsQueryable();

        if (year.HasValue)
        {
            query = query.Where(p => p.PublicationYear == year.Value);
        }

        var paperList = await query.ToListAsync(cancellationToken);

        var totalPublications = paperList.Count;
        var totalCitations = paperList.Sum(p => p.CitationCount);
        var avgCitations = totalPublications > 0 ? totalCitations / (double)totalPublications : 0;

        var yearCounts = paperList
            .Where(p => p.PublicationYear.HasValue)
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderBy(x => x.year)
            .ToList();

        var journalCounts = paperList
            .Where(p => p.Journal != null && !string.IsNullOrWhiteSpace(p.Journal.Name))
            .GroupBy(p => p.Journal!.Name!)
            .Select(g => new { name = g.Key, count = g.Count() })
            .OrderByDescending(x => x.count)
            .Take(10)
            .ToList();

        var topPapers = paperList
            .OrderByDescending(p => p.CitationCount)
            .Take(10)
            .Select(p => new
            {
                p.PaperId,
                p.Title,
                p.PublicationYear,
                p.CitationCount
            })
            .ToList();

        var recentPapers = paperList
            .OrderByDescending(p => p.PublicationYear)
            .Take(20)
            .Select(p => new
            {
                p.PaperId,
                p.Title,
                p.PublicationYear,
                p.CitationCount,
                JournalName = p.Journal != null ? p.Journal.Name : null
            })
            .ToList();

        return Ok(new
        {
            totalPublications,
            totalCitations,
            avgCitations = Math.Round(avgCitations ?? 0, 2),
            publicationsByYear = yearCounts,
            topJournals = journalCounts,
            topPapers,
            recentPapers
        });
    }
}
