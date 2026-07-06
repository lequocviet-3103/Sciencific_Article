using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/topics")]
public class TopicsController : ControllerBase
{
    private readonly ITopicRepository _topicRepository;
    private readonly IOpenAlexSyncService _syncService;
    private readonly AppDbContext _context;

    public TopicsController(ITopicRepository topicRepository, IOpenAlexSyncService syncService, AppDbContext context)
    {
        _topicRepository = topicRepository;
        _syncService = syncService;
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ResearchTopic>>> Search([FromQuery] string? q, [FromQuery] int take = 20, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(q))
        {
            await _syncService.EnsureTopicsSyncedForQueryAsync(q, cancellationToken: cancellationToken);
        }

        var result = await _topicRepository.SearchAsync(q ?? string.Empty, take, cancellationToken);
        return Ok(result);
    }

    [HttpGet("featured")]
    public async Task<ActionResult<IEnumerable<ResearchTopic>>> Featured([FromQuery] int take = 20, CancellationToken cancellationToken = default)
    {
        var result = await _topicRepository.GetFeaturedAsync(take, cancellationToken);
        return Ok(result);
    }

    [HttpGet("emerging")]
    public async Task<IActionResult> GetEmerging([FromQuery] int take = 10, CancellationToken cancellationToken = default)
    {
        // "Emerging" = topics with papers in the last 2 years AND significant citation growth
        var currentYear = DateTime.UtcNow.Year;
        var recent = await _context.ResearchTopics
            .Where(t => t.Papers.Any(p => p.PublicationYear >= currentYear - 2))
            .Select(t => new
            {
                t.TopicId,
                t.Name,
                t.Field,
                t.Domain,
                t.WorksCount,
                recentPaperCount = t.Papers.Count(p => p.PublicationYear >= currentYear - 2),
                totalPaperCount = t.Papers.Count()
            })
            .Where(t => t.recentPaperCount > 0)
            .OrderByDescending(t => t.recentPaperCount)
            .Take(take)
            .ToListAsync(cancellationToken);

        return Ok(recent);
    }

    [HttpGet("{topicId}")]
    public async Task<IActionResult> GetById(string topicId, CancellationToken cancellationToken = default)
    {
        var topic = await _context.ResearchTopics
            .FirstOrDefaultAsync(t => t.TopicId == topicId, cancellationToken);

        if (topic == null) return NotFound(new { message = "Topic not found" });

        var paperCount = await _context.Papers
            .CountAsync(p => p.Topics.Any(t => t.TopicId == topicId), cancellationToken);

        var trendByYear = await _context.Papers
            .Where(p => p.Topics.Any(t => t.TopicId == topicId) && p.PublicationYear.HasValue)
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderBy(x => x.year)
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            topic.TopicId,
            topic.Name,
            topic.Field,
            topic.Domain,
            topic.Subfield,
            topic.WorksCount,
            topic.OpenAlexId,
            paperCount,
            trendByYear
        });
    }
}
