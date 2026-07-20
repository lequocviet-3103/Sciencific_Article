using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
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
    private readonly IFirebaseNotificationService _firebaseNotificationService;
    private readonly IFirebaseAuthService _firebaseAuthService;

    public NotificationsController(
        INotificationRepository notificationRepository,
        AppDbContext context,
        IFirebaseNotificationService firebaseNotificationService,
        IFirebaseAuthService firebaseAuthService)
    {
        _notificationRepository = notificationRepository;
        _context = context;
        _firebaseNotificationService = firebaseNotificationService;
        _firebaseAuthService = firebaseAuthService;
    }

    public const string AllUsersTopic = "all_users";

    [HttpPost("send-to-token")]
    public async Task<IActionResult> SendToToken(
        [FromBody] SendTokenNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        var caller = await GetCallerAsync(cancellationToken);
        if (caller == null) return Unauthorized(new { message = "A valid Firebase login is required" });

        var validationError = ValidateMessage(request.Title, request.Body);
        if (validationError != null) return BadRequest(new { message = validationError });
        if (string.IsNullOrWhiteSpace(request.Token) || request.Token.Trim().Length > 4096)
            return BadRequest(new { message = "A valid FCM token is required" });

        try
        {
            var messageId = await _firebaseNotificationService.SendAsync(
                request.Token.Trim(), request.Title.Trim(), request.Body.Trim(), cancellationToken);

            var notification = CreateNotification(caller.UserId, request.Title, request.Body);
            await _notificationRepository.AddAsync(notification, cancellationToken);

            return Ok(new
            {
                message = "Test notification sent",
                messageId,
                notificationId = notification.NotificationId
            });
        }
        catch (FirebaseAdmin.Messaging.FirebaseMessagingException ex)
        {
            return BadRequest(new { message = $"FCM rejected the token: {ex.Message}", code = ex.MessagingErrorCode?.ToString() });
        }
    }

    [HttpPost("broadcast")]
    public async Task<IActionResult> Broadcast(
        [FromBody] BroadcastNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        var caller = await GetCallerAsync(cancellationToken);
        if (caller == null) return Unauthorized(new { message = "A valid Firebase login is required" });
        if (caller.RoleId != "1") return StatusCode(StatusCodes.Status403Forbidden, new { message = "Admin role is required" });

        var validationError = ValidateMessage(request.Title, request.Body);
        if (validationError != null) return BadRequest(new { message = validationError });

        try
        {
            var messageId = await _firebaseNotificationService.SendToTopicAsync(
                AllUsersTopic, request.Title.Trim(), request.Body.Trim(), cancellationToken);

            var userIds = await _context.Users
                .AsNoTracking()
                .Where(user => user.IsBanned != true)
                .Select(user => user.UserId)
                .ToListAsync(cancellationToken);

            var notifications = userIds
                .Select(userId => CreateNotification(userId, request.Title, request.Body))
                .ToList();
            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync(cancellationToken);

            return Ok(new
            {
                message = "Broadcast notification sent",
                messageId,
                recipientCount = userIds.Count
            });
        }
        catch (FirebaseAdmin.Messaging.FirebaseMessagingException ex)
        {
            return BadRequest(new { message = $"FCM broadcast failed: {ex.Message}", code = ex.MessagingErrorCode?.ToString() });
        }
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

    private async Task<User?> GetCallerAsync(CancellationToken cancellationToken)
    {
        var authorization = Request.Headers.Authorization.ToString();
        if (!authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return null;

        var idToken = authorization["Bearer ".Length..].Trim();
        if (idToken.Length == 0) return null;

        try
        {
            var firebaseToken = await _firebaseAuthService.VerifyIdTokenAsync(idToken, cancellationToken);
            return await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(user => user.FirebaseUid == firebaseToken.Uid, cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    private static string? ValidateMessage(string title, string body)
    {
        if (string.IsNullOrWhiteSpace(title)) return "Title is required";
        if (title.Trim().Length > 100) return "Title must be 100 characters or fewer";
        if (string.IsNullOrWhiteSpace(body)) return "Message body is required";
        if (body.Trim().Length > 1000) return "Message body must be 1000 characters or fewer";
        return null;
    }

    private static Notification CreateNotification(string userId, string title, string body) => new()
    {
        NotificationId = Guid.NewGuid().ToString("N"),
        UserId = userId,
        Title = title.Trim(),
        Content = body.Trim(),
        IsRead = false,
        CreatedAt = DateTime.Now
    };
}
