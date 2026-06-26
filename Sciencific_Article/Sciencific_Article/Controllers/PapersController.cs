using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/papers")]
public class PapersController : ControllerBase
{
    private readonly AppDbContext _context;

    public PapersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] string? topicId,
        [FromQuery] int? year,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        var query = _context.Papers
            .Include(p => p.Journal)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(p =>
                (p.Title != null && EF.Functions.ILike(p.Title, $"%{q}%")) ||
                (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%")));
        }

        if (year.HasValue)
        {
            query = query.Where(p => p.PublicationYear == year.Value);
        }

        var total = query.Count();
        var items = await query
            .OrderByDescending(p => p.PublicationYear)
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
                Journal = p.Journal != null ? new { p.Journal.JournalId, p.Journal.Name } : null
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

    [HttpGet("{paperId}")]
    public async Task<IActionResult> GetById(string paperId, CancellationToken cancellationToken)
    {
        var paper = await _context.Papers
            .Include(p => p.Journal)
            .FirstOrDefaultAsync(p => p.PaperId == paperId, cancellationToken);

        if (paper == null) return NotFound(new { message = "Paper not found" });

        var authors = await _context.PaperAuthors
            .Where(pa => pa.PaperId == paperId)
            .Select(pa => pa.Author)
            .Select(a => new { a.AuthorId, a.Name })
            .ToListAsync(cancellationToken);

        var keywords = await _context.PaperKeywords
            .Where(pk => pk.PaperId == paperId)
            .Select(pk => pk.Keyword)
            .Select(k => new { k.KeywordId, k.Name })
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            paper.PaperId,
            paper.Title,
            paper.Abstract,
            paper.Doi,
            paper.PublicationYear,
            paper.CitationCount,
            Journal = paper.Journal != null ? new
            {
                paper.Journal.JournalId,
                paper.Journal.Name,
                paper.Journal.Publisher,
                paper.Journal.Issn
            } : null,
            Authors = authors,
            Keywords = keywords
        });
    }
}
