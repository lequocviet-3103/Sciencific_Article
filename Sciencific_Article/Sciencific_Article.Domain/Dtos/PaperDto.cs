namespace Sciencific_Article.Domain.Dtos;

public class PaperDto
{
    public string PaperId { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string? Abstract { get; set; }

    public int? PublicationYear { get; set; }

    public int? CitationCount { get; set; }

    public string? Doi { get; set; }

    public string? JournalId { get; set; }

    public string? ExternalId { get; set; }

    public string? SourceApi { get; set; }

    public string? Type { get; set; }

    public string? Language { get; set; }

    public List<AuthorDto> Authors { get; set; } = new();

    public JournalDto? Journal { get; set; }

    public List<TopicDto> Topics { get; set; } = new();

    public List<KeywordDto> Keywords { get; set; } = new();
}
