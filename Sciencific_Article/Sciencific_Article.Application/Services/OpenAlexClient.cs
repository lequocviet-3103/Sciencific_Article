using Sciencific_Article.Application.Interfaces.Services;
using System.Net.Http.Json;
using System.Text.Json;

namespace Sciencific_Article.Application.Services;

public class OpenAlexClient : IOpenAlexClient
{
    private readonly HttpClient _httpClient;

    public OpenAlexClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<(int StatusCode, string Body)> GetRawJsonAsync(
        string relativePathAndQuery,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync(relativePathAndQuery, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        return ((int)response.StatusCode, body);
    }

    public async Task<OpenAlexResponse<OpenAlexWork>> GetWorksAsync(
        string? search = null,
        string? filter = null,
        string? cursor = null,
        int perPage = 25,
        string? sort = null,
        CancellationToken cancellationToken = default)
    {
        var queryParams = new Dictionary<string, string>
        {
            ["per_page"] = perPage.ToString(),
            ["sort"] = string.IsNullOrWhiteSpace(sort)
                ? "publication_year:desc"
                : sort
        };

        if (!string.IsNullOrWhiteSpace(search))
            queryParams["search"] = search;
        if (!string.IsNullOrWhiteSpace(filter))
            queryParams["filter"] = filter;
        if (!string.IsNullOrWhiteSpace(cursor))
            queryParams["cursor"] = cursor;

        //queryParams["filter"] = "authors_count:>0,publication_year:>2018,type:journal-article|proceedings-article";
        queryParams["select"] = "id,doi,title,publication_year,cited_by_count,type," +
            "primary_location,locations,authorships,language,topics,primary_topic,abstract_inverted_index";

        var url = "https://api.openalex.org/works?" + string.Join("&",
            queryParams.Select(kv => $"{kv.Key}={Uri.EscapeDataString(kv.Value)}"));

        using var response = await _httpClient.GetAsync(url, cancellationToken);

        // Read the body ONCE — calling ReadAsStringAsync or ReadFromJsonAsync
        // twice on the same HttpContent throws / returns empty because the
        // underlying stream is buffered and consumed after the first read.
        // On non-2xx, throw with the response body for diagnostics; otherwise
        // deserialize it as JSON.
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException(
                $"OpenAlex error {(int)response.StatusCode}: {errorBody}\nURL: {url}");
        }

        Dictionary<string, object>? data;
        try
        {
            data = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>(
                cancellationToken: cancellationToken);
        }
        catch (JsonException ex)
        {
            throw new HttpRequestException(
                $"Failed to parse OpenAlex response: {ex.Message}\nURL: {url}", ex);
        }

        var results = new List<OpenAlexWork>();

        if (data != null
            && data.TryGetValue("results", out var resultsRaw)
            && resultsRaw is System.Text.Json.JsonElement resultsElement
            && resultsElement.ValueKind == System.Text.Json.JsonValueKind.Array)
        {
            foreach (var item in resultsElement.EnumerateArray())
            {
                try
                {
                    results.Add(ParseWork(item));
                }
                catch (Exception ex)
                {
                    // A single malformed work shouldn't kill the whole sync.
                    Console.WriteLine($"OpenAlex: skipped malformed work: {ex.Message}");
                }
            }
        }

        var meta = new OpenAlexMeta();
        if (data != null
            && data.TryGetValue("meta", out var metaRaw)
            && metaRaw is System.Text.Json.JsonElement metaElement
            && metaElement.ValueKind == System.Text.Json.JsonValueKind.Object)
        {
            if (metaElement.TryGetProperty("count", out var countEl)
                && countEl.ValueKind == System.Text.Json.JsonValueKind.Number)
                meta.Count = countEl.GetInt32();
            if (metaElement.TryGetProperty("next_cursor", out var cursorEl)
                && cursorEl.ValueKind == System.Text.Json.JsonValueKind.String)
                meta.NextCursor = cursorEl.GetString();
        }

        return new OpenAlexResponse<OpenAlexWork> { Results = results, Meta = meta };
    }

    private static OpenAlexWork ParseWork(System.Text.Json.JsonElement e)
    {
        var work = new OpenAlexWork
        {
            Id = e.TryGetProperty("id", out var id) ? id.GetString() ?? "" : "",
            Doi = e.TryGetProperty("doi", out var doi) ? doi.GetString() : null,
            Title = e.TryGetProperty("title", out var title) ? title.GetString() ?? "" : "",
            PublicationYear = e.TryGetProperty("publication_year", out var yr) ? yr.GetInt32() : null,
            CitedByCount = e.TryGetProperty("cited_by_count", out var cc) ? cc.GetInt32() : 0,
            Type = e.TryGetProperty("type", out var tp) ? tp.GetString() : null,
            Language = e.TryGetProperty("language", out var lang) && lang.ValueKind == JsonValueKind.String
                ? lang.GetString()
                : null
        };

        if (e.TryGetProperty("primary_location", out var pl) && pl.ValueKind != System.Text.Json.JsonValueKind.Null)
            work.PrimaryLocation = ParseLocation(pl);
        if (e.TryGetProperty("locations", out var locs) && locs.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Locations = locs.EnumerateArray().Select(ParseLocation).ToList();
        if (e.TryGetProperty("authorships", out var auths) && auths.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Authorships = auths.EnumerateArray().Select(ParseAuthorship).ToList();
        if (e.TryGetProperty("concepts", out var concepts) && concepts.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Concepts = concepts.EnumerateArray().Select(ParseConcept).ToList();
        if (e.TryGetProperty("topics", out var topics) && topics.ValueKind == JsonValueKind.Array)
            work.Topics = topics.EnumerateArray().Select(ParseConcept).ToList();
        if (e.TryGetProperty("primary_topic", out var primaryTopic) && primaryTopic.ValueKind == JsonValueKind.Object)
            work.PrimaryTopic = ParseConcept(primaryTopic);
        if (e.TryGetProperty("abstract_inverted_index", out var abs) && abs.ValueKind == System.Text.Json.JsonValueKind.Object)
            work.AbstractInvertedIndex = ParseAbstract(abs);

        return work;
    }

    private static OpenAlexLocation ParseLocation(System.Text.Json.JsonElement e)
    {
        var loc = new OpenAlexLocation
        {
            Doi = e.TryGetProperty("doi", out var d) ? d.GetString() : null,
            LandingPageUrl = e.TryGetProperty("landing_page_url", out var lp) ? lp.GetString() : null,
            PdfUrl = e.TryGetProperty("pdf_url", out var pdf) ? pdf.GetString() : null,
            IsOa = e.TryGetProperty("is_oa", out var oa) ? oa.GetBoolean() : null
        };
        if (e.TryGetProperty("source", out var src) && src.ValueKind != System.Text.Json.JsonValueKind.Null)
        {
            loc.Source = new OpenAlexSource
            {
                Id = src.TryGetProperty("id", out var sid) ? sid.GetString() : null,
                DisplayName = src.TryGetProperty("display_name", out var sdn) ? sdn.GetString() : null,
                HostPublisher = src.TryGetProperty("host_publisher", out var hp) ? hp.GetString() : null,
                HostOrganizationName = src.TryGetProperty("host_organization_name", out var hon) ? hon.GetString() : null,
                Issn = src.TryGetProperty("issn", out var issn) ? ParseIssn(issn) : null
            };
        }
        return loc;
    }

    // OpenAlex returns `source.issn` as either a JSON array of strings
    // (most sources, since a journal can have multiple ISSNs) or, rarely,
    // a single string — handle both rather than assuming one shape.
    private static string? ParseIssn(System.Text.Json.JsonElement e)
    {
        if (e.ValueKind == System.Text.Json.JsonValueKind.Array)
        {
            foreach (var item in e.EnumerateArray())
            {
                return item.ValueKind == System.Text.Json.JsonValueKind.String ? item.GetString() : null;
            }
            return null;
        }
        if (e.ValueKind == System.Text.Json.JsonValueKind.String)
        {
            return e.GetString();
        }
        return null;
    }

    private static OpenAlexAuthorship ParseAuthorship(System.Text.Json.JsonElement e)
    {
        var auth = new OpenAlexAuthorship
        {
            AuthorNumber = e.TryGetProperty("author_number", out var an) ? an.GetInt32() : null,
            IsCorresponding = e.TryGetProperty("is_corresponding", out var ic) ? ic.GetBoolean() : null
        };
        if (e.TryGetProperty("author", out var a) && a.ValueKind != System.Text.Json.JsonValueKind.Null)
        {
            auth.Authors = new List<OpenAlexAuthor>
            {
                new OpenAlexAuthor
                {
                    Id = a.TryGetProperty("id", out var aid) ? aid.GetString() : null,
                    DisplayName = a.TryGetProperty("display_name", out var adn) ? adn.GetString() : null,
                    Orcid = a.TryGetProperty("orcid", out var o) ? o.GetString() : null
                }
            };
        }
        return auth;
    }

    private static OpenAlexConcept ParseConcept(JsonElement e)
    {
        return new OpenAlexConcept
        {
            Id = e.TryGetProperty("id", out var id) ? id.GetString() : null,

            DisplayName = e.TryGetProperty("display_name", out var dn)
                ? dn.GetString()
                : null,

            Level = e.TryGetProperty("level", out var lv) && lv.ValueKind == JsonValueKind.Number
                ? lv.GetInt32().ToString()
                : null,

            Field = e.TryGetProperty("field", out var f) &&
                    f.ValueKind == JsonValueKind.Object &&
                    f.TryGetProperty("display_name", out var fd)
                        ? fd.GetString()
                        : null,

            Domain = e.TryGetProperty("domain", out var dm) &&
                     dm.ValueKind == JsonValueKind.Object &&
                     dm.TryGetProperty("display_name", out var dd)
                        ? dd.GetString()
                        : null,

            Subfield = e.TryGetProperty("subfield", out var sf) &&
                       sf.ValueKind == JsonValueKind.Object &&
                       sf.TryGetProperty("display_name", out var sfd)
                           ? sfd.GetString()
                           : null,

            Score = e.TryGetProperty("score", out var sc)
                ? sc.GetDouble()
                : null
        };
    }

    private static Dictionary<string, int[]>? ParseAbstract(System.Text.Json.JsonElement e)
    {
        var result = new Dictionary<string, int[]>();
        foreach (var prop in e.EnumerateObject())
        {
            result[prop.Name] = prop.Value.EnumerateArray().Select(v => v.GetInt32()).ToArray();
        }
        return result.Count > 0 ? result : null;
    }
}
