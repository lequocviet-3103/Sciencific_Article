using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/follow-topics")]
public class FollowTopicController : ControllerBase
{
    private readonly IFollowTopicRepository _followTopicRepository;

    public FollowTopicController(IFollowTopicRepository followTopicRepository)
    {
        _followTopicRepository = followTopicRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<FollowTopic>>> GetByUser([FromQuery] string userId, CancellationToken cancellationToken = default)
    {
        var result = await _followTopicRepository.GetByUserAsync(userId, 1, 100, cancellationToken);
        return Ok(result.Items);
    }

    [HttpPost]
    public async Task<ActionResult<FollowTopic>> Create([FromBody] FollowTopic followTopic, CancellationToken cancellationToken)
    {
        var created = await _followTopicRepository.AddAsync(followTopic, cancellationToken);
        return Ok(created);
    }

    [HttpDelete("{followTopicId}")]
    public async Task<IActionResult> Delete([FromRoute] string followTopicId, CancellationToken cancellationToken)
    {
        await _followTopicRepository.RemoveAsync(followTopicId, cancellationToken);
        return NoContent();
    }
}
