namespace Sciencific_Article.Domain.Dtos;

public class TopicDto
{
    public string TopicId { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? Field { get; set; }

    public string? Subfield { get; set; }

    public string? Domain { get; set; }

    public int WorksCount { get; set; }

    public string? OpenAlexId { get; set; }
}
