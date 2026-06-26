using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Infastructure.Services;

public class FirebaseNotificationService : IFirebaseNotificationService
{
    public Task SendAsync(string token, string title, string body, CancellationToken cancellationToken = default)
    {
        return Task.CompletedTask;
    }
}
