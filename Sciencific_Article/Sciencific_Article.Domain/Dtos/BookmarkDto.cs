namespace Sciencific_Article.Domain.Dtos;

public class BookmarkDto
{
    public string BookmarkId { get; set; } = string.Empty;

    public string? UserId { get; set; }

    public string? PaperId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public PaperDto? Paper { get; set; }
}
