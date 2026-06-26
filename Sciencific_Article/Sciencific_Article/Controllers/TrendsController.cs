using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/trends")]
public class TrendsController : ControllerBase
{
    private readonly ITrendRepository _trendRepository;

    public TrendsController(ITrendRepository trendRepository)
    {
        _trendRepository = trendRepository;
    }

    [HttpGet("{topicId}")]
    public async Task<ActionResult<IEnumerable<PublicationTrend>>> Get([FromRoute] string topicId, [FromQuery] int? fromYear, [FromQuery] int? toYear, CancellationToken cancellationToken = default)
    {
        var result = await _trendRepository.GetByTopicAsync(topicId, fromYear, toYear, cancellationToken);
        return Ok(result);
    }
}
