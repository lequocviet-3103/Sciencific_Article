namespace Sciencific_Article.Domain.Dtos;

public class ReportDto
{
    public string ReportId { get; set; } = string.Empty;

    public string? UserId { get; set; }

    public string? ReportType { get; set; }

    public string? FileUrl { get; set; }

    public DateTime? CreatedAt { get; set; }
}
