using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface INotificationRepository
{
    Task<PagedResult<Notification>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<Notification> AddAsync(Notification notification, CancellationToken cancellationToken = default);
    Task MarkAsReadAsync(string notificationId, CancellationToken cancellationToken = default);
    Task<int> CountUnreadAsync(string userId, CancellationToken cancellationToken = default);
}
