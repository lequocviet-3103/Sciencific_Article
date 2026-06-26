namespace Sciencific_Article.Domain.Dtos;

public class FollowTopicDto
{
    public string FollowTopicId { get; set; } = string.Empty;

    public string? UserId { get; set; }

    public string? KeywordId { get; set; }

    public string? TopicId { get; set; }

    public DateTime? CreatedAt { get; set; }
}
