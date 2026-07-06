using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationRepository _notificationRepository;
    private readonly AppDbContext _context;

    public NotificationsController(INotificationRepository notificationRepository, AppDbContext context)
    {
        _notificationRepository = notificationRepository;
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<Notification>>> GetByUser(
        [FromQuery] string userId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await _notificationRepository.GetByUserAsync(userId, page, pageSize, cancellationToken);
        return Ok(result);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount(
        [FromQuery] string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return BadRequest(new { message = "userId is required" });
        var count = await _notificationRepository.CountUnreadAsync(userId, cancellationToken);
        return Ok(new { count });
    }

    [HttpPatch("{notificationId}/read")]
    public async Task<IActionResult> MarkRead(
        [FromRoute] string notificationId,
        CancellationToken cancellationToken = default)
    {
        await _notificationRepository.MarkAsReadAsync(notificationId, cancellationToken);
        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllRead(
        [FromQuery] string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return BadRequest(new { message = "userId is required" });

        await _context.Notifications
            .Where(n => n.UserId == userId && n.IsRead != true)
            .ExecuteUpdateAsync(setters => setters.SetProperty(n => n.IsRead, true), cancellationToken);

        return NoContent();
    }

    [HttpDelete("{notificationId}")]
    public async Task<IActionResult> Delete(
        [FromRoute] string notificationId,
        CancellationToken cancellationToken = default)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.NotificationId == notificationId, cancellationToken);

        if (notification == null) return NotFound();

        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}
