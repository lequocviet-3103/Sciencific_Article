namespace Sciencific_Article.Domain.Dtos;

public class AuthorDto
{
    public string AuthorId { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? ExternalAuthorId { get; set; }

    public int PaperCount { get; set; }
}
