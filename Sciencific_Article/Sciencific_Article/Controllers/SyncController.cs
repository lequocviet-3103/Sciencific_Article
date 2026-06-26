using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/sync")]
public class SyncController : ControllerBase
{
    private readonly IOpenAlexSyncService _syncService;

    public SyncController(IOpenAlexSyncService syncService)
    {
        _syncService = syncService;
    }

    [HttpPost("works")]
    public async Task<IActionResult> SyncWorks(CancellationToken cancellationToken)
    {
        var result = await _syncService.SyncWorksAsync(cancellationToken);
        return Ok(new { message = result });
    }

    [HttpPost("trends")]
    public async Task<IActionResult> RecomputeTrends(CancellationToken cancellationToken)
    {
        var result = await _syncService.RecomputeTrendsAsync(cancellationToken);
        return Ok(new { message = result });
    }
}
