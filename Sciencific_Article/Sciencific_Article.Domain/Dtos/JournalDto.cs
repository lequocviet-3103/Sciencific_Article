namespace Sciencific_Article.Domain.Dtos;

public class JournalDto
{
    public string JournalId { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? Publisher { get; set; }

    public string? Issn { get; set; }

    public int PaperCount { get; set; }
}
