namespace Sciencific_Article.Application.Interfaces.Services;

public interface IOpenAlexClient
{
    Task<OpenAlexResponse<OpenAlexWork>> GetWorksAsync(
        string? search = null,
        string? cursor = null,
        int perPage = 25,
        CancellationToken cancellationToken = default);
}

// ── Shared DTOs (same namespace so the interface can reference them) ──

public class OpenAlexResponse<T>
{
    public List<T> Results { get; set; } = new();
    public OpenAlexMeta Meta { get; set; } = new();
}

public class OpenAlexMeta
{
    public int Count { get; set; }
    public string? NextCursor { get; set; }
}

public class OpenAlexWork
{
    public string Id { get; set; } = string.Empty;
    public string? Doi { get; set; }
    public string Title { get; set; } = string.Empty;
    public int? PublicationYear { get; set; }
    public int? CitedByCount { get; set; }
    public string? Type { get; set; }
    public OpenAlexLocation? PrimaryLocation { get; set; }
    public List<OpenAlexLocation> Locations { get; set; } = new();
    public List<OpenAlexAuthorship> Authorships { get; set; } = new();
    public List<OpenAlexConcept> Concepts { get; set; } = new();
    public Dictionary<string, int[]>? AbstractInvertedIndex { get; set; }
}

public class OpenAlexLocation
{
    public string? Doi { get; set; }
    public string? LandingPageUrl { get; set; }
    public string? PdfUrl { get; set; }
    public OpenAlexSource? Source { get; set; }
    public bool? IsOa { get; set; }
}

public class OpenAlexSource
{
    public string? Id { get; set; }
    public string? DisplayName { get; set; }
    public string? HostPublisher { get; set; }
    public string? HostOrganizationName { get; set; }
    public string? Issn { get; set; }
}

public class OpenAlexAuthorship
{
    public int? AuthorNumber { get; set; }
    public bool? IsCorresponding { get; set; }
    public List<OpenAlexAuthor>? Authors { get; set; }
}

public class OpenAlexAuthor
{
    public string? Id { get; set; }
    public string? DisplayName { get; set; }
    public string? Orcid { get; set; }
}

public class OpenAlexConcept
{
    public string? Id { get; set; }
    public string? DisplayName { get; set; }
    public string? Level { get; set; }
    public string? Field { get; set; }
    public string? Domain { get; set; }
    public double? Score { get; set; }
}
