using FirebaseAdmin.Messaging;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Infastructure.Services;

public class FirebaseNotificationService : IFirebaseNotificationService
{
    public async Task SendAsync(string token, string title, string body, CancellationToken cancellationToken = default)
    {
        var message = new Message
        {
            Token = token,
            Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body },
        };
        await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }

    public async Task SendToTopicAsync(string topic, string title, string body, CancellationToken cancellationToken = default)
    {
        var message = new Message
        {
            Topic = topic,
            Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body },
        };
        await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }
}
