namespace Sciencific_Article.Domain.Dtos;

public class PublicationTrendDto
{
    public string TrendId { get; set; } = string.Empty;

    public string TopicId { get; set; } = string.Empty;

    public string TopicName { get; set; } = string.Empty;

    public int Year { get; set; }

    public int PublicationCount { get; set; }

    public double? AverageCitation { get; set; }
}
