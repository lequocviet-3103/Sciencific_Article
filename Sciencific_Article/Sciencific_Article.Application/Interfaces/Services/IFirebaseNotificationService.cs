namespace Sciencific_Article.Application.Interfaces.Services;

public interface IFirebaseNotificationService
{
    Task SendAsync(string token, string title, string body, CancellationToken cancellationToken = default);

    /// Sends a push notification to every device subscribed to the given
    /// FCM topic (e.g. "new_papers"), so the backend doesn't need to track
    /// per-device tokens to broadcast "new paper published" alerts.
    Task SendToTopicAsync(string topic, string title, string body, CancellationToken cancellationToken = default);
}
