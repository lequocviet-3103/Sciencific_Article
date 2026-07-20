namespace Sciencific_Article.Domain.Dtos;

public sealed class SendTokenNotificationRequest
{
    public string Token { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public string Body { get; init; } = string.Empty;
}

public sealed class BroadcastNotificationRequest
{
    public string Title { get; init; } = string.Empty;
    public string Body { get; init; } = string.Empty;
}
