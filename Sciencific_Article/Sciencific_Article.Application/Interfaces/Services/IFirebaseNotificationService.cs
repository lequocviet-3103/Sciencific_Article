namespace Sciencific_Article.Application.Interfaces.Services;

public interface IFirebaseNotificationService
{
    Task SendAsync(string token, string title, string body, CancellationToken cancellationToken = default);
}
