using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>System overview stats for the Admin dashboard.</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken = default)
    {
        var userCount = await _context.Users.CountAsync(cancellationToken);
        var paperCount = await _context.Papers.CountAsync(cancellationToken);
        var topicCount = await _context.ResearchTopics.CountAsync(cancellationToken);
        var journalCount = await _context.Journals.CountAsync(cancellationToken);
        var authorCount = await _context.Authors.CountAsync(cancellationToken);
        var notificationCount = await _context.Notifications.CountAsync(cancellationToken);
        var syncLogCount = await _context.SyncLogs.CountAsync(cancellationToken);
        var bannedCount = await _context.Users.CountAsync(u => u.IsBanned == true, cancellationToken);

        var recentSyncLogs = await _context.SyncLogs
            .OrderByDescending(s => s.SyncTime)
            .Take(5)
            .Select(s => new { s.SyncLogId, s.SourceApi, s.Status, s.RecordsInserted, s.SyncTime, s.ErrorMessage })
            .ToListAsync(cancellationToken);

        var papersByYear = await _context.Papers
            .Where(p => p.PublicationYear.HasValue)
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => new { year = g.Key, count = g.Count() })
            .OrderByDescending(x => x.year)
            .Take(10)
            .ToListAsync(cancellationToken);

        return Ok(new
        {
            userCount,
            paperCount,
            topicCount,
            journalCount,
            authorCount,
            notificationCount,
            syncLogCount,
            bannedCount,
            recentSyncLogs,
            papersByYear
        });
    }

    /// <summary>Ban a user (soft ban — sets is_banned = true).</summary>
    [HttpPut("users/{userId}/ban")]
    public async Task<IActionResult> BanUser(string userId, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken);
        if (user == null) return NotFound(new { message = "User not found" });

        user.IsBanned = true;
        await _context.SaveChangesAsync(cancellationToken);
        return Ok(new { message = "User banned", userId });
    }

    /// <summary>Unban a user.</summary>
    [HttpPut("users/{userId}/unban")]
    public async Task<IActionResult> UnbanUser(string userId, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId, cancellationToken);
        if (user == null) return NotFound(new { message = "User not found" });

        user.IsBanned = false;
        await _context.SaveChangesAsync(cancellationToken);
        return Ok(new { message = "User unbanned", userId });
    }

    /// <summary>Sync logs viewer.</summary>
    [HttpGet("sync/logs")]
    public async Task<IActionResult> GetSyncLogs(
        [FromQuery] int take = 50,
        CancellationToken cancellationToken = default)
    {
        var logs = await _context.SyncLogs
            .OrderByDescending(s => s.SyncTime)
            .Take(take)
            .Select(s => new
            {
                s.SyncLogId,
                s.SourceApi,
                s.Status,
                s.RecordsInserted,
                s.ErrorMessage,
                SyncTime = s.SyncTime
            })
            .ToListAsync(cancellationToken);

        return Ok(logs);
    }

    /// <summary>All users with ban status — richer than /api/auth/users.</summary>
    [HttpGet("users")]
    public async Task<IActionResult> GetUsers(
        [FromQuery] string? q,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 200) pageSize = 50;

        var query = _context.Users.Include(u => u.Role).AsQueryable();

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = query.Where(u =>
                EF.Functions.ILike(u.FullName, $"%{q}%") ||
                EF.Functions.ILike(u.Email, $"%{q}%"));
        }

        var total = await query.CountAsync(cancellationToken);
        var users = await query
            .OrderBy(u => u.FullName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.UserId,
                u.FullName,
                u.Email,
                u.RoleId,
                RoleName = u.Role.RoleName,
                u.CreatedAt,
                u.IsBanned,
                u.AvatarUrl
            })
            .ToListAsync(cancellationToken);

        return Ok(new { users, total, page, pageSize });
    }

    /// <summary>System statistics (alias for dashboard — more granular).</summary>
    [HttpGet("statistics")]
    public async Task<IActionResult> GetStatistics(CancellationToken cancellationToken = default)
    {
        var topTopics = await _context.ResearchTopics
            .OrderByDescending(t => t.WorksCount)
            .Take(5)
            .Select(t => new { t.TopicId, t.Name, t.WorksCount })
            .ToListAsync(cancellationToken);

        var topJournals = await _context.Papers
            .Where(p => p.JournalId != null)
            .GroupBy(p => new { p.JournalId, p.Journal!.Name })
            .Select(g => new { journalId = g.Key.JournalId, name = g.Key.Name, paperCount = g.Count() })
            .OrderByDescending(x => x.paperCount)
            .Take(5)
            .ToListAsync(cancellationToken);

        var usersByRole = await _context.Users
            .GroupBy(u => new { u.RoleId, u.Role.RoleName })
            .Select(g => new { roleId = g.Key.RoleId, roleName = g.Key.RoleName, count = g.Count() })
            .ToListAsync(cancellationToken);

        return Ok(new { topTopics, topJournals, usersByRole });
    }
}
