using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationRepository _notificationRepository;

    public NotificationsController(INotificationRepository notificationRepository)
    {
        _notificationRepository = notificationRepository;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<Notification>>> GetByUser([FromQuery] string userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var result = await _notificationRepository.GetByUserAsync(userId, page, pageSize, cancellationToken);
        return Ok(result);
    }

    [HttpPatch("{notificationId}/read")]
    public async Task<IActionResult> MarkRead([FromRoute] string notificationId, CancellationToken cancellationToken)
    {
        await _notificationRepository.MarkAsReadAsync(notificationId, cancellationToken);
        return NoContent();
    }
}
