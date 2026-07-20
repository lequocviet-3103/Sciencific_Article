namespace Sciencific_Article.Application.Interfaces.Services;

public interface IOpenAlexClient
{
    Task<OpenAlexResponse<OpenAlexWork>> GetWorksAsync(
        string? search = null,
        string? filter = null,
        string? cursor = null,
        int perPage = 25,
        string? sort = null,
        CancellationToken cancellationToken = default);

    /// Forwards a path+query (relative to the OpenAlex base URL, e.g.
    /// "works?search=ai&page=1") and returns the raw JSON response
    /// untouched, so callers can pass OpenAlex's response straight through
    /// to a client that already knows how to parse OpenAlex's JSON shape.
    Task<(int StatusCode, string Body)> GetRawJsonAsync(
        string relativePathAndQuery,
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
    public string? Language { get; set; }
    public OpenAlexLocation? PrimaryLocation { get; set; }
    public List<OpenAlexLocation> Locations { get; set; } = new();
    public List<OpenAlexAuthorship> Authorships { get; set; } = new();
    public List<OpenAlexConcept> Concepts { get; set; } = new();
    public List<OpenAlexConcept> Topics { get; set; } = new();
    public OpenAlexConcept? PrimaryTopic { get; set; }
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
    public string? Subfield { get; set; }
    public double? Score { get; set; }
}
