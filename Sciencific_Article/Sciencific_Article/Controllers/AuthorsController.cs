using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/authors")]
public class AuthorsController : ControllerBase
{
    private readonly AppDbContext _context;

    public AuthorsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] int take = 25,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Authors.AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(a => EF.Functions.ILike(a.Name, $"%{q}%"));
        }

        var authors = await query
            .OrderBy(a => a.Name)
            .Take(take)
            .Select(a => new { a.AuthorId, a.Name, a.ExternalAuthorId })
            .ToListAsync(cancellationToken);

        return Ok(authors);
    }

    [HttpGet("top")]
    public async Task<IActionResult> GetTop(
        [FromQuery] int take = 10,
        CancellationToken cancellationToken = default)
    {
        var top = await _context.PaperAuthors
            .GroupBy(pa => new { pa.AuthorId, pa.Author.Name })
            .Select(g => new { authorId = g.Key.AuthorId, name = g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .Take(take)
            .ToListAsync(cancellationToken);

        return Ok(top);
    }

    [HttpGet("{authorId}")]
    public async Task<IActionResult> GetById(
        string authorId,
        CancellationToken cancellationToken = default)
    {
        var author = await _context.Authors
            .FirstOrDefaultAsync(a => a.AuthorId == authorId, cancellationToken);

        if (author == null) return NotFound(new { message = "Author not found" });

        var paperCount = await _context.PaperAuthors
            .CountAsync(pa => pa.AuthorId == authorId, cancellationToken);

        return Ok(new
        {
            author.AuthorId,
            author.Name,
            author.ExternalAuthorId,
            author.CreatedAt,
            paperCount
        });
    }

    [HttpGet("{authorId}/papers")]
    public async Task<IActionResult> GetPapers(
        string authorId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var query = _context.PaperAuthors
            .Where(pa => pa.AuthorId == authorId)
            .Select(pa => pa.Paper)
            .Include(p => p.Journal);

        var total = await query.CountAsync(cancellationToken);
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
                p.DocType,
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
}
