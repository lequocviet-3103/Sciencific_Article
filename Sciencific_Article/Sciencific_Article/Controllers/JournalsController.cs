using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/journals")]
public class JournalsController : ControllerBase
{
    private readonly AppDbContext _context;

    public JournalsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] int take = 25,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Journals.AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(j =>
                EF.Functions.ILike(j.Name, $"%{q}%") ||
                (j.Publisher != null && EF.Functions.ILike(j.Publisher, $"%{q}%")));
        }

        var journals = await query
            .OrderBy(j => j.Name)
            .Take(take)
            .Select(j => new { j.JournalId, j.Name, j.Publisher, j.Issn })
            .ToListAsync(cancellationToken);

        return Ok(journals);
    }

    [HttpGet("top")]
    public async Task<IActionResult> GetTop(
        [FromQuery] int take = 10,
        CancellationToken cancellationToken = default)
    {
        var top = await _context.Papers
            .Where(p => p.JournalId != null)
            .GroupBy(p => new { p.JournalId, p.Journal!.Name })
            .Select(g => new { journalId = g.Key.JournalId, name = g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .Take(take)
            .ToListAsync(cancellationToken);

        return Ok(top);
    }

    [HttpGet("{journalId}")]
    public async Task<IActionResult> GetById(
        string journalId,
        CancellationToken cancellationToken = default)
    {
        var journal = await _context.Journals
            .FirstOrDefaultAsync(j => j.JournalId == journalId, cancellationToken);

        if (journal == null) return NotFound(new { message = "Journal not found" });

        var paperCount = await _context.Papers
            .CountAsync(p => p.JournalId == journalId, cancellationToken);

        return Ok(new
        {
            journal.JournalId,
            journal.Name,
            journal.Publisher,
            journal.Issn,
            journal.CreatedAt,
            paperCount
        });
    }

    [HttpGet("{journalId}/papers")]
    public async Task<IActionResult> GetPapers(
        string journalId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var query = _context.Papers
            .Where(p => p.JournalId == journalId)
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
