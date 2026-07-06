using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/analysis")]
public class AnalysisController : ControllerBase
{
    private readonly AppDbContext _context;

    public AnalysisController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Publication count per year for a keyword or topic query.
    /// GET /api/analysis/topic-trend?q=AI&fromYear=2015&toYear=2024
    /// </summary>
    [HttpGet("topic-trend")]
    public async Task<IActionResult> GetTopicTrend(
        [FromQuery] string q,
        [FromQuery] int? fromYear,
        [FromQuery] int? toYear,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(q))
            return BadRequest(new { message = "q is required" });

        var query = _context.Papers
            .Where(p => p.PublicationYear.HasValue &&
                ((p.Title != null && EF.Functions.ILike(p.Title, $"%{q}%")) ||
                 (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%"))));

        if (fromYear.HasValue) query = query.Where(p => p.PublicationYear >= fromYear.Value);
        if (toYear.HasValue) query = query.Where(p => p.PublicationYear <= toYear.Value);

        var trend = await query
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderBy(x => x.year)
            .ToListAsync(cancellationToken);

        return Ok(new { keyword = q, trend });
    }

    /// <summary>
    /// Compare publication trends for multiple keywords.
    /// POST /api/analysis/compare-keywords
    /// Body: { "keywords": ["AI", "Machine Learning", "Deep Learning"], "fromYear": 2015, "toYear": 2024 }
    /// </summary>
    [HttpPost("compare-keywords")]
    public async Task<IActionResult> CompareKeywords(
        [FromBody] CompareKeywordsRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Keywords == null || request.Keywords.Count == 0)
            return BadRequest(new { message = "keywords list is required" });

        var results = new List<object>();
        foreach (var kw in request.Keywords.Take(5))
        {
            var q = _context.Papers
                .Where(p => p.PublicationYear.HasValue &&
                    ((p.Title != null && EF.Functions.ILike(p.Title, $"%{kw}%")) ||
                     (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{kw}%"))));

            if (request.FromYear.HasValue) q = q.Where(p => p.PublicationYear >= request.FromYear.Value);
            if (request.ToYear.HasValue) q = q.Where(p => p.PublicationYear <= request.ToYear.Value);

            var trend = await q
                .GroupBy(p => p.PublicationYear!.Value)
                .Select(g => new { year = g.Key, count = g.Count() })
                .OrderBy(x => x.year)
                .ToListAsync(cancellationToken);

            results.Add(new { keyword = kw, trend });
        }

        return Ok(results);
    }

    /// <summary>
    /// Emerging topics: topics whose paper count in the last 2 years is disproportionately high.
    /// GET /api/analysis/emerging-topics?take=10
    /// </summary>
    [HttpGet("emerging-topics")]
    public async Task<IActionResult> GetEmergingTopics(
        [FromQuery] int take = 10,
        CancellationToken cancellationToken = default)
    {
        var currentYear = DateTime.UtcNow.Year;
        var cutoff = currentYear - 2;

        var emerging = await _context.ResearchTopics
            .Select(t => new
            {
                t.TopicId,
                t.Name,
                t.Field,
                t.Domain,
                t.WorksCount,
                recentCount = t.Papers.Count(p => p.PublicationYear >= cutoff),
                totalCount = t.Papers.Count()
            })
            .Where(t => t.recentCount > 0)
            .ToListAsync(cancellationToken);

        // Growth ratio: recent / total; topics that are mostly recent are "emerging"
        var ranked = emerging
            .Select(t => new
            {
                t.TopicId,
                t.Name,
                t.Field,
                t.Domain,
                t.WorksCount,
                t.recentCount,
                t.totalCount,
                growthRatio = t.totalCount > 0 ? (double)t.recentCount / t.totalCount : 0
            })
            .OrderByDescending(t => t.growthRatio)
            .ThenByDescending(t => t.recentCount)
            .Take(take)
            .ToList();

        return Ok(ranked);
    }

    /// <summary>
    /// Keyword trend chart: publication count per year grouped by keyword occurrences in paper titles.
    /// GET /api/analysis/keyword-trend?q=AI
    /// </summary>
    [HttpGet("keyword-trend")]
    public async Task<IActionResult> GetKeywordTrend(
        [FromQuery] string? q,
        [FromQuery] int? fromYear,
        [FromQuery] int? toYear,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(q))
            return BadRequest(new { message = "q is required" });

        // Check if it matches a stored keyword first
        var keyword = await _context.Keywords
            .FirstOrDefaultAsync(k => EF.Functions.ILike(k.Name, q), cancellationToken);

        IQueryable<int> yearQuery;

        if (keyword != null)
        {
            yearQuery = _context.PaperKeywords
                .Where(pk => pk.KeywordId == keyword.KeywordId && pk.Paper.PublicationYear.HasValue)
                .Select(pk => pk.Paper.PublicationYear!.Value);
        }
        else
        {
            var baseQ = _context.Papers
                .Where(p => p.PublicationYear.HasValue &&
                    ((p.Title != null && EF.Functions.ILike(p.Title, $"%{q}%")) ||
                     (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%"))));

            if (fromYear.HasValue) baseQ = baseQ.Where(p => p.PublicationYear >= fromYear.Value);
            if (toYear.HasValue) baseQ = baseQ.Where(p => p.PublicationYear <= toYear.Value);

            yearQuery = baseQ.Select(p => p.PublicationYear!.Value);
        }

        var trend = await yearQuery
            .GroupBy(y => y)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderBy(x => x.year)
            .ToListAsync(cancellationToken);

        return Ok(new { keyword = q, trend });
    }
}

public class CompareKeywordsRequest
{
    public List<string> Keywords { get; set; } = new();
    public int? FromYear { get; set; }
    public int? ToYear { get; set; }
}
