using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

/// <summary>Public read-only statistics — no auth required.</summary>
[ApiController]
[Route("api/stats")]
public class StatsController : ControllerBase
{
    private readonly AppDbContext _context;

    public StatsController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>Quick counts for the homepage stats card.</summary>
    [HttpGet]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken = default)
    {
        var paperCount = await _context.Papers.CountAsync(cancellationToken);
        var authorCount = await _context.Authors.CountAsync(cancellationToken);
        var journalCount = await _context.Journals.CountAsync(cancellationToken);
        var topicCount = await _context.ResearchTopics.CountAsync(cancellationToken);

        return Ok(new { paperCount, authorCount, journalCount, topicCount });
    }

    /// <summary>Full DB-backed dashboard data — replaces search-based analytics.</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken = default)
    {
        var paperCount = await _context.Papers.CountAsync(cancellationToken);
        var authorCount = await _context.Authors.CountAsync(cancellationToken);
        var journalCount = await _context.Journals.CountAsync(cancellationToken);
        var topicCount = await _context.ResearchTopics.CountAsync(cancellationToken);

        // Average citation count (only papers that have a citation value)
        var avgCitations = await _context.Papers
            .Where(p => p.CitationCount.HasValue)
            .AverageAsync(p => (double?)p.CitationCount!.Value, cancellationToken) ?? 0;

        // Top 5 journals by paper count
        var topJournals = await _context.Papers
            .Where(p => p.JournalId != null && p.Journal != null)
            .GroupBy(p => new { p.JournalId, p.Journal!.Name })
            .Select(g => new { g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .Take(5)
            .ToListAsync(cancellationToken);

        // Top 5 authors by paper count
        var topAuthors = await _context.PaperAuthors
            .GroupBy(pa => new { pa.AuthorId, pa.Author.Name })
            .Select(g => new { g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .Take(5)
            .ToListAsync(cancellationToken);

        // Publications by year (last 15 years)
        var cutoffYear = DateTime.UtcNow.Year - 15;
        var papersByYear = await _context.Papers
            .Where(p => p.PublicationYear.HasValue && p.PublicationYear >= cutoffYear)
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderBy(x => x.year)
            .ToListAsync(cancellationToken);

        // Most cited paper
        var mostCited = await _context.Papers
            .Include(p => p.Journal)
            .Where(p => p.CitationCount.HasValue)
            .OrderByDescending(p => p.CitationCount)
            .Select(p => new
            {
                p.PaperId, p.Title, p.PublicationYear, p.CitationCount,
                JournalName = p.Journal != null ? p.Journal.Name : null
            })
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(new
        {
            paperCount,
            authorCount,
            journalCount,
            topicCount,
            avgCitations = Math.Round(avgCitations, 1),
            topJournals,
            topAuthors,
            papersByYear,
            mostCited
        });
    }
}
