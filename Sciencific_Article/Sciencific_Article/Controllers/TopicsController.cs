using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/topics")]
public class TopicsController : ControllerBase
{
    private readonly ITopicRepository _topicRepository;

    public TopicsController(ITopicRepository topicRepository)
    {
        _topicRepository = topicRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ResearchTopic>>> Search([FromQuery] string? q, [FromQuery] int take = 20, CancellationToken cancellationToken = default)
    {
        var result = await _topicRepository.SearchAsync(q ?? string.Empty, take, cancellationToken);
        return Ok(result);
    }

    [HttpGet("featured")]
    public async Task<ActionResult<IEnumerable<ResearchTopic>>> Featured([FromQuery] int take = 20, CancellationToken cancellationToken = default)
    {
        var result = await _topicRepository.GetFeaturedAsync(take, cancellationToken);
        return Ok(result);
    }
}
