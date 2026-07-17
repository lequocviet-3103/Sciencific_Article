using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/sync")]
public class SyncController : ControllerBase
{
    private readonly IOpenAlexSyncService _syncService;
    private readonly ILogger<SyncController> _logger;

    public SyncController(
        IOpenAlexSyncService syncService,
        ILogger<SyncController> logger)
    {
        _syncService = syncService;
        _logger = logger;
    }

    [HttpPost("works")]
    public async Task<IActionResult> SyncWorks(
        [FromQuery] int requestedCount = 50,
        CancellationToken cancellationToken = default)
    {
        if (requestedCount < 1 || requestedCount > 1000)
        {
            return BadRequest(new
            {
                message = "requestedCount must be between 1 and 1000."
            });
        }

        try
        {
            var result = await _syncService.SyncWorksAsync(requestedCount, cancellationToken);
            return Ok(new
            {
                message = result.Message,
                result.RequestedCount,
                result.InsertedCount,
                result.SkippedDuplicates,
                result.ScannedCount,
                result.SourceExhausted,
            });
        }
        catch (OperationCanceledException)
        {
            // Client disconnected — no need to log as an error.
            return StatusCode(499, new { message = "Sync was cancelled by the client." });
        }
        catch (HttpRequestException ex)
        {
            // Most likely cause: cannot reach api.openalex.org
            // (network outage, DNS failure, OpenAlex 4xx/5xx, etc.).
            _logger.LogError(ex, "OpenAlex HTTP error during SyncWorks");
            return StatusCode(StatusCodes.Status502BadGateway, new
            {
                message = "Failed to reach OpenAlex. " + ex.Message,
                source = "OpenAlex"
            });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SyncWorks failed");
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Sync failed: " + ex.Message,
                // Surface the type so the client can decide whether to retry
                // (e.g. transient DB errors) or escalate.
                errorType = ex.GetType().Name
            });
        }
    }

    [HttpPost("trends")]
    public async Task<IActionResult> RecomputeTrends(CancellationToken cancellationToken)
    {
        try
        {
            var result = await _syncService.RecomputeTrendsAsync(cancellationToken);
            return Ok(new { message = result });
        }
        catch (OperationCanceledException)
        {
            return StatusCode(499, new { message = "Recompute was cancelled by the client." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RecomputeTrends failed");
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Recompute failed: " + ex.Message,
                errorType = ex.GetType().Name
            });
        }
    }
}
