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

    public async Task<OpenAlexResponse<OpenAlexWork>> GetWorksAsync(
        string? search = null,
        string? cursor = null,
        int perPage = 25,
        CancellationToken cancellationToken = default)
    {
        var queryParams = new Dictionary<string, string>
        {
            ["per_page"] = perPage.ToString(),
            ["sort"] = "publication_year:desc"
        };

        if (!string.IsNullOrWhiteSpace(search))
            queryParams["search"] = search;
        if (!string.IsNullOrWhiteSpace(cursor))
            queryParams["cursor"] = cursor;

        //queryParams["filter"] = "authors_count:>0,publication_year:>2018,type:journal-article|proceedings-article";
        queryParams["select"] = "id,doi,title,publication_year,cited_by_count,type," +
            "primary_location,locations,authorships,concepts,abstract_inverted_index";

        var url = "https://api.openalex.org/works?" + string.Join("&",
            queryParams.Select(kv => $"{kv.Key}={Uri.EscapeDataString(kv.Value)}"));
        var response = await _httpClient.GetAsync(url, cancellationToken);

        var errorBody = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
                $"OpenAlex error {(int)response.StatusCode}: {errorBody}\nURL: {url}"
            );
        }
        response.EnsureSuccessStatusCode();

        var data = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>(cancellationToken);

        var results = new List<OpenAlexWork>();

        if (data != null && data.TryGetValue("results", out var resultsRaw) && resultsRaw is System.Text.Json.JsonElement resultsElement)
        {
            foreach (var item in resultsElement.EnumerateArray())
            {
                results.Add(ParseWork(item));

            }
            Console.WriteLine(
 $"OpenAlex returned: {resultsElement.GetArrayLength()} works"
);
        }
        Console.WriteLine(response.StatusCode);
        Console.WriteLine(results.Count);
        var meta = new OpenAlexMeta();
        if (data != null && data.TryGetValue("meta", out var metaRaw) && metaRaw is System.Text.Json.JsonElement metaElement)
        {
            if (metaElement.TryGetProperty("count", out var countEl))
                meta.Count = countEl.GetInt32();
            if (metaElement.TryGetProperty("next_cursor", out var cursorEl))
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
            Type = e.TryGetProperty("type", out var tp) ? tp.GetString() : null
        };

        if (e.TryGetProperty("primary_location", out var pl) && pl.ValueKind != System.Text.Json.JsonValueKind.Null)
            work.PrimaryLocation = ParseLocation(pl);
        if (e.TryGetProperty("locations", out var locs) && locs.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Locations = locs.EnumerateArray().Select(ParseLocation).ToList();
        if (e.TryGetProperty("authorships", out var auths) && auths.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Authorships = auths.EnumerateArray().Select(ParseAuthorship).ToList();
        if (e.TryGetProperty("concepts", out var concepts) && concepts.ValueKind == System.Text.Json.JsonValueKind.Array)
            work.Concepts = concepts.EnumerateArray().Select(ParseConcept).ToList();
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
                Issn = src.TryGetProperty("issn", out var issn) ? issn.GetString() : null
            };
        }
        return loc;
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

            Level = e.TryGetProperty("level", out var lv)
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
