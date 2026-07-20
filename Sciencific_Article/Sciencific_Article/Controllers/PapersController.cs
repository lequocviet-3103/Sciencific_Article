using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/papers")]
public class PapersController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IOpenAlexSyncService _syncService;

    public PapersController(AppDbContext context, IOpenAlexSyncService syncService)
    {
        _context = context;
        _syncService = syncService;
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] string? topicId,
        [FromQuery] string? authorId,
        [FromQuery] string? authorName,
        [FromQuery] string? journalId,
        [FromQuery] string? journalName,
        [FromQuery] int? year,
        [FromQuery] int? fromYear,
        [FromQuery] int? toYear,
        [FromQuery] int? minCitations,
        [FromQuery] string? docType,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        // Auto-sync is intentionally OFF for search. The Search screen, Topic detail,
        // and Home all read straight from the DB. OpenAlex ingestion runs only via
        // SyncBackgroundService (every 12h) and the manual admin sync endpoint, so a
        // user's request never blocks on an external API round-trip.

        var query = _context.Papers
            .Include(p => p.Journal)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(p =>
                (p.Title != null && EF.Functions.ILike(p.Title, $"%{q}%")) ||
                (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%")) ||
                p.Topics.Any(t =>
                    EF.Functions.ILike(t.Name, $"%{q}%") ||
                    (t.Field != null && EF.Functions.ILike(t.Field, $"%{q}%")) ||
                    (t.Subfield != null && EF.Functions.ILike(t.Subfield, $"%{q}%")) ||
                    (t.Domain != null && EF.Functions.ILike(t.Domain, $"%{q}%"))) ||
                p.Keywords.Any(k => EF.Functions.ILike(k.Name, $"%{q}%")));
        }

        if (!string.IsNullOrWhiteSpace(authorId))
        {
            query = query.Where(p => p.Authors.Any(a => a.AuthorId == authorId));
        }
        else if (!string.IsNullOrWhiteSpace(authorName))
        {
            query = query.Where(p => p.Authors.Any(a =>
                EF.Functions.ILike(a.Name, $"%{authorName}%")));
        }

        if (!string.IsNullOrWhiteSpace(journalId))
        {
            query = query.Where(p => p.JournalId == journalId);
        }
        else if (!string.IsNullOrWhiteSpace(journalName))
        {
            query = query.Where(p =>
                p.Journal != null && EF.Functions.ILike(p.Journal.Name, $"%{journalName}%"));
        }

        var effectiveFromYear = fromYear ?? year;
        var effectiveToYear = toYear ?? year;
        if (effectiveFromYear.HasValue)
            query = query.Where(p => p.PublicationYear >= effectiveFromYear.Value);
        if (effectiveToYear.HasValue)
            query = query.Where(p => p.PublicationYear <= effectiveToYear.Value);

        if (minCitations.HasValue && minCitations.Value > 0)
            query = query.Where(p => p.CitationCount >= minCitations.Value);

        if (!string.IsNullOrWhiteSpace(docType))
            query = query.Where(p => p.DocType == docType);

        if (!string.IsNullOrWhiteSpace(topicId))
            query = query.Where(p => p.Topics.Any(t => t.TopicId == topicId));

        query = sort switch
        {
            "cited_by_count:asc" => query.OrderBy(p => p.CitationCount),
            "publication_year:asc" => query.OrderBy(p => p.PublicationYear),
            "publication_year:desc" => query.OrderByDescending(p => p.PublicationYear),
            _ => query.OrderByDescending(p => p.CitationCount),
        };

        var total = await query.CountAsync(cancellationToken);
        var items = await query
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
                p.Language,
                p.DocType,
                Journal = p.Journal != null ? new { p.Journal.JournalId, p.Journal.Name } : null,
                Authors = p.Authors.Take(5).Select(a => new { a.AuthorId, a.Name }).ToList()
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

    [HttpGet("latest")]
    public async Task<IActionResult> GetLatest(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var items = await _context.Papers
            .Include(p => p.Journal)
            .Where(p => p.PublicationYear.HasValue)
            .OrderByDescending(p => p.PublicationYear)
            .ThenByDescending(p => p.CitationCount)
            .Take(take)
            .Select(p => new
            {
                p.PaperId, p.Title, p.PublicationYear, p.CitationCount, p.DocType,
                Journal = p.Journal != null ? new { p.Journal.JournalId, p.Journal.Name } : null
            })
            .ToListAsync(cancellationToken);

        return Ok(items);
    }

    [HttpGet("trending")]
    public async Task<IActionResult> GetTrending(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var currentYear = DateTime.UtcNow.Year;
        var items = await _context.Papers
            .Include(p => p.Journal)
            .Where(p => p.PublicationYear >= currentYear - 3 && p.CitationCount > 0)
            .OrderByDescending(p => p.CitationCount)
            .Take(take)
            .Select(p => new
            {
                p.PaperId, p.Title, p.PublicationYear, p.CitationCount, p.DocType,
                Journal = p.Journal != null ? new { p.Journal.JournalId, p.Journal.Name } : null
            })
            .ToListAsync(cancellationToken);

        return Ok(items);
    }

    [HttpGet("popular")]
    public async Task<IActionResult> GetPopular(
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 100);
        var items = await _context.Papers
            .Include(p => p.Journal)
            .Where(p => p.CitationCount > 0)
            .OrderByDescending(p => p.CitationCount)
            .ThenByDescending(p => p.PublicationYear)
            .Take(take)
            .Select(p => new
            {
                p.PaperId, p.Title, p.PublicationYear, p.CitationCount, p.DocType,
                Journal = p.Journal != null ? new { p.Journal.JournalId, p.Journal.Name } : null
            })
            .ToListAsync(cancellationToken);

        return Ok(items);
    }

    [HttpGet("export")]
    public async Task<IActionResult> ExportCsv(
        [FromQuery] string? q,
        [FromQuery] string? topicId,
        [FromQuery] string? authorId,
        [FromQuery] string? journalId,
        [FromQuery] int? fromYear,
        [FromQuery] int? toYear,
        [FromQuery] int? minCitations,
        [FromQuery] string? docType,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Papers
            .Include(p => p.Journal)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(p =>
                (p.Title != null && EF.Functions.ILike(p.Title, $"%{q}%")) ||
                (p.Abstract != null && EF.Functions.ILike(p.Abstract, $"%{q}%")) ||
                p.Topics.Any(t => EF.Functions.ILike(t.Name, $"%{q}%")) ||
                p.Keywords.Any(k => EF.Functions.ILike(k.Name, $"%{q}%")));

        if (!string.IsNullOrWhiteSpace(authorId))
            query = query.Where(p => p.Authors.Any(a => a.AuthorId == authorId));

        if (!string.IsNullOrWhiteSpace(journalId))
            query = query.Where(p => p.JournalId == journalId);

        if (!string.IsNullOrWhiteSpace(topicId))
            query = query.Where(p => p.Topics.Any(t => t.TopicId == topicId));

        if (fromYear.HasValue)
            query = query.Where(p => p.PublicationYear >= fromYear.Value);
        if (toYear.HasValue)
            query = query.Where(p => p.PublicationYear <= toYear.Value);
        if (minCitations.HasValue)
            query = query.Where(p => p.CitationCount >= minCitations.Value);
        if (!string.IsNullOrWhiteSpace(docType))
            query = query.Where(p => p.DocType == docType);

        var papers = await query
            .OrderByDescending(p => p.CitationCount)
            .Take(500)
            .Select(p => new
            {
                p.PaperId, p.Title, p.Doi, p.PublicationYear, p.CitationCount, p.DocType,
                JournalName = p.Journal != null ? p.Journal.Name : ""
            })
            .ToListAsync(cancellationToken);

        var sb = new StringBuilder();
        sb.AppendLine("PaperId,Title,DOI,Year,Citations,DocType,Journal");
        foreach (var p in papers)
        {
            sb.AppendLine(
                $"{CsvEscape(p.PaperId)},{CsvEscape(p.Title ?? "")},{CsvEscape(p.Doi ?? "")}," +
                $"{p.PublicationYear},{p.CitationCount},{CsvEscape(p.DocType ?? "")},{CsvEscape(p.JournalName)}");
        }

        var bytes = Encoding.UTF8.GetBytes(sb.ToString());
        return File(bytes, "text/csv", "papers.csv");
    }

    [HttpGet("{paperId}")]
    public async Task<IActionResult> GetById(string paperId, CancellationToken cancellationToken)
    {
        var paper = await _context.Papers
            .Include(p => p.Journal)
            .Include(p => p.Topics)
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
            paper.Language,
            paper.DocType,
            Journal = paper.Journal != null ? new
            {
                paper.Journal.JournalId,
                paper.Journal.Name,
                paper.Journal.Publisher,
                paper.Journal.Issn
            } : null,
            Authors = authors,
            Keywords = keywords,
            Topics = paper.Topics.Select(t => new { t.TopicId, t.Name, t.Field, t.Domain }),
        });
    }

    private static string CsvEscape(string value)
    {
        if (value.Contains(',') || value.Contains('"') || value.Contains('\n'))
            return $"\"{value.Replace("\"", "\"\"")}\"";
        return value;
    }
}
