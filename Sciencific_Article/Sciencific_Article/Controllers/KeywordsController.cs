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
        var popular = await _context.PaperKeywords
            .GroupBy(pk => new { pk.KeywordId, pk.Keyword.Name })
            .Select(g => new { keywordId = g.Key.KeywordId, name = g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
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
}
