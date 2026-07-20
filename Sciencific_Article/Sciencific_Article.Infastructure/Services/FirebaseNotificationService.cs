using FirebaseAdmin.Messaging;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Infastructure.Services;

public class FirebaseNotificationService : IFirebaseNotificationService
{
    public async Task<string> SendAsync(string token, string title, string body, CancellationToken cancellationToken = default)
    {
        var message = new Message
        {
            Token = token,
            Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body },
        };
        return await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }

    public async Task<string> SendToTopicAsync(string topic, string title, string body, CancellationToken cancellationToken = default)
    {
        var message = new Message
        {
            Topic = topic,
            Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body },
        };
        return await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken);
    }
}
