using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/keywords")]
public class KeywordsController : ControllerBase
{
    private readonly AppDbContext _context;

    public KeywordsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] int take = 25,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Keywords.AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(k => EF.Functions.ILike(k.Name, $"%{q}%"));
        }

        var keywords = await query
            .OrderBy(k => k.Name)
            .Take(take)
            .Select(k => new { k.KeywordId, k.Name })
            .ToListAsync(cancellationToken);

        return Ok(keywords);
    }

    [HttpGet("popular")]
    public async Task<IActionResult> GetPopular(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 100);
        var popular = await _context.PaperKeywords
            .GroupBy(pk => new { pk.KeywordId, pk.Keyword.Name })
            .Select(g => new
            {
                keywordId = g.Key.KeywordId,
                name = g.Key.Name,
                paperCount = g.Count(),
                totalCitations = g.Sum(x => x.Paper.CitationCount ?? 0),
                avgCitations = g.Average(x => (double)(x.Paper.CitationCount ?? 0))
            })
            .OrderByDescending(x => x.paperCount)
            .ThenByDescending(x => x.totalCitations)
            .Take(take)
            .ToListAsync(cancellationToken);

        return Ok(popular);
    }

    [HttpGet("{keywordId}")]
    public async Task<IActionResult> GetById(
        string keywordId,
        CancellationToken cancellationToken = default)
    {
        var keyword = await _context.Keywords
            .FirstOrDefaultAsync(k => k.KeywordId == keywordId, cancellationToken);

        if (keyword == null) return NotFound(new { message = "Keyword not found" });

        var paperCount = await _context.PaperKeywords
            .CountAsync(pk => pk.KeywordId == keywordId, cancellationToken);

        return Ok(new { keyword.KeywordId, keyword.Name, paperCount });
    }

    [HttpGet("{keywordId}/papers")]
    public async Task<IActionResult> GetPapers(
        string keywordId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.Papers
            .AsNoTracking()
            .Where(p => p.Keywords.Any(k => k.KeywordId == keywordId));

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(p => p.CitationCount)
            .ThenByDescending(p => p.PublicationYear)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.PaperId,
                p.Title,
                p.Abstract,
                p.Doi,
                p.PublicationYear,
                p.CitationCount,
                p.DocType,
                Journal = p.Journal != null
                    ? new { p.Journal.JournalId, p.Journal.Name }
                    : null,
                Authors = p.Authors.Take(5)
                    .Select(a => new { a.AuthorId, a.Name })
                    .ToList()
            })
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            items,
            total,
            page,
            pageSize,
            pageCount = (int)Math.Ceiling(total / (double)pageSize)
        });
    }
}
