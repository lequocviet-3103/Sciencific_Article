namespace Sciencific_Article.Application.Common;

public class PaginationParams
{
    public int Page { get; set; } = 1;

    public int PageSize { get; set; } = 20;

    public string? Search { get; set; }

    public string? SortBy { get; set; }

    public bool Desc { get; set; }
}
