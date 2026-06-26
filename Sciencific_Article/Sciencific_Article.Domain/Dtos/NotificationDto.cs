namespace Sciencific_Article.Domain.Dtos;

public class NotificationDto
{
    public string NotificationId { get; set; } = string.Empty;

    public string? UserId { get; set; }

    public string? Title { get; set; }

    public string? Content { get; set; }

    public bool? IsRead { get; set; }

    public DateTime? CreatedAt { get; set; }
}
