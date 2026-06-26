using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly AppDbContext _context;

    public NotificationRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<Notification>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.Notifications.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAt);
        var total = await q.CountAsync(cancellationToken);
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<Notification> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<Notification> AddAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(cancellationToken);
        return notification;
    }

    public async Task MarkAsReadAsync(string notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await _context.Notifications.FirstOrDefaultAsync(x => x.NotificationId == notificationId, cancellationToken);
        if (notification == null) return;
        notification.IsRead = true;
        await _context.SaveChangesAsync(cancellationToken);
    }

    public Task<int> CountUnreadAsync(string userId, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    /*public async Task<int> CountUnreadAsync(string userId, CancellationToken cancellationToken = default)
        => await _context.Notifications.CountAsync(x => x.UserId == userId && !x.IsRead, cancellationToken);*/
}
