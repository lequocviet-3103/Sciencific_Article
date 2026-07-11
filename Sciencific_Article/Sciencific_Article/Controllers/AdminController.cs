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

    /// <summary>
    /// One-shot fix: recompute <c>works_count</c> on every topic from the actual
    /// rows in <c>paper_topics</c>. Useful when the column got stuck on 1 due
    /// to a previous bug in the sync service. Safe to call repeatedly.
    /// </summary>
    [HttpPost("recompute-topic-works-counts")]
    public async Task<IActionResult> RecomputeTopicWorksCounts(CancellationToken cancellationToken = default)
    {
        // Pull the real counts first so we can return them even if the
        // UPDATE step blows up (e.g. Npgsql DateTime kind issues).
        var countsByTopicId = await _context.PaperTopics
            .GroupBy(pt => pt.TopicId)
            .Select(g => new { TopicId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.TopicId, x => x.Count, cancellationToken);

        var topics = await _context.ResearchTopics
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        // Run the UPDATE as raw SQL so we don't fight with Npgsql's
        // DateTime/Kind mapping for an unrelated timestamp column.
        // updated_at uses PG NOW() (timestamp without time zone) which
        // matches the column type.
        var updatedRows = 0;
        try
        {
            foreach (var topic in topics)
            {
                var realCount = countsByTopicId.TryGetValue(topic.TopicId, out var c) ? c : 0;
                if (topic.WorksCount == realCount) continue;

                updatedRows += await _context.Database.ExecuteSqlRawAsync(
                    "UPDATE research_topics SET works_count = {0}, updated_at = NOW() WHERE topic_id = {1}",
                    new object[] { realCount, topic.TopicId },
                    cancellationToken);
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                message = "Recompute partially failed",
                updatedRows,
                error = ex.Message,
                innerError = ex.InnerException?.Message
            });
        }

        var top10 = topics
            .Select(t => new
            {
                t.TopicId,
                t.Name,
                WorksCount = countsByTopicId.TryGetValue(t.TopicId, out var c) ? c : 0
            })
            .OrderByDescending(t => t.WorksCount)
            .Take(10)
            .ToList();

        return Ok(new
        {
            updatedRows,
            totalTopics = topics.Count,
            topicsWithPapers = countsByTopicId.Count,
            top10
        });
    }

    /// <summary>
    /// Diagnostic: for every topic with works_count > 0, also report the
    /// actual paper_count we can find through the navigation property, so we
    /// can see whether anything is orphaned or whether the navigation is
    /// wired wrong.
    /// </summary>
    [HttpGet("topic-works-counts-audit")]
    public async Task<IActionResult> AuditTopicCounts(CancellationToken cancellationToken = default)
    {
        var byJoinTable = await _context.PaperTopics
            .GroupBy(pt => pt.TopicId)
            .Select(g => new { TopicId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.TopicId, x => x.Count, cancellationToken);

        var byNavigation = await _context.ResearchTopics
            .AsNoTracking()
            .Where(t => t.WorksCount > 0 || t.Papers.Any())
            .Take(50)
            .Select(t => new
            {
                t.TopicId,
                t.Name,
                WorksCount = t.WorksCount,
                NavCount = t.Papers.Count()
            })
            .ToListAsync(cancellationToken);

        var rows = byNavigation.Select(t => new
        {
            t.TopicId,
            t.Name,
            WorksCount = t.WorksCount,
            JoinTableCount = byJoinTable.TryGetValue(t.TopicId, out var c) ? c : 0,
            t.NavCount,
            Mismatch = (byJoinTable.TryGetValue(t.TopicId, out var cc) ? cc : 0) != t.NavCount
                      || (byJoinTable.TryGetValue(t.TopicId, out var ccc) ? ccc : 0) != t.WorksCount
        }).ToList();

        return Ok(rows);
    }
}
