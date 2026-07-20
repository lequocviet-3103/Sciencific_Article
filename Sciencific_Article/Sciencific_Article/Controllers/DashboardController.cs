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
        [FromQuery] string? q,
        [FromQuery] int? year,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Papers
            .Include(p => p.Journal)
            .Include(p => p.Authors)
            .Include(p => p.Topics)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(topicId))
        {
            query = query.Where(p => p.Topics.Any(t => t.TopicId == topicId));
        }

        if (!string.IsNullOrWhiteSpace(q) && string.IsNullOrWhiteSpace(topicId))
        {
            query = query.Where(p =>
                EF.Functions.ILike(p.Title, $"%{q}%") ||
                (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%")) ||
                p.Topics.Any(t =>
                    EF.Functions.ILike(t.Name, $"%{q}%") ||
                    (t.Field != null && EF.Functions.ILike(t.Field, $"%{q}%")) ||
                    (t.Subfield != null && EF.Functions.ILike(t.Subfield, $"%{q}%")) ||
                    (t.Domain != null && EF.Functions.ILike(t.Domain, $"%{q}%"))) ||
                p.Keywords.Any(k => EF.Functions.ILike(k.Name, $"%{q}%")));
        }

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
            .GroupBy(p => new { p.Journal!.JournalId, p.Journal.Name })
            .Select(g => new
            {
                journalId = g.Key.JournalId,
                name = g.Key.Name,
                paperCount = g.Count(),
                totalCitations = g.Sum(p => p.CitationCount ?? 0)
            })
            .OrderByDescending(x => x.paperCount)
            .Take(10)
            .ToList();

        // A paper can have several topic tags. For an overview that adds up
        // to totalPublications, count it once under its first populated field.
        var fieldBreakdown = paperList
            .Select(p => p.Topics
                .Where(t => !string.IsNullOrWhiteSpace(t.Field))
                .OrderBy(t => t.TopicId)
                .Select(t => t.Field!)
                .FirstOrDefault() ?? "Other")
            .GroupBy(field => field)
            .Select(g => new { name = g.Key, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .ThenBy(x => x.name)
            .ToList();

        var uniqueAuthors = paperList
            .SelectMany(p => p.Authors)
            .Select(a => a.AuthorId)
            .Distinct()
            .Count();

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
            uniqueAuthors,
            publicationsByYear = yearCounts,
            fieldBreakdown,
            topJournals = journalCounts,
            topPapers,
            recentPapers
        });
    }
}
