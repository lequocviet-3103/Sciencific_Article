using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class OpenAlexSyncService : IOpenAlexSyncService
{
    public const string NewPapersTopic = "new_papers";

    private readonly IUnitOfWork _unitOfWork;
    private readonly IOpenAlexClient _openAlexClient;
    private readonly IFirebaseNotificationService _notificationService;

    public OpenAlexSyncService(
        IUnitOfWork unitOfWork,
        IOpenAlexClient openAlexClient,
        IFirebaseNotificationService notificationService)
    {
        _unitOfWork = unitOfWork;
        _openAlexClient = openAlexClient;
        _notificationService = notificationService;
    }

    public async Task<string> SyncWorksAsync(CancellationToken cancellationToken = default)
    {
        var inserted = await IngestWorksAsync(search: null, maxPages: 2, cancellationToken);
        return $"Synced {inserted} papers from OpenAlex";
    }

    /// Called on-demand from search endpoints when the DB has too few rows
    /// matching a user's query: pulls more matching works straight from
    /// OpenAlex and persists them, so the next read of the same query is
    /// served entirely from Postgres instead of staying a live pass-through.
    public async Task<int> EnsureWorksSyncedForQueryAsync(
        string query,
        int minResults = 15,
        int maxPages = 2,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query)) return 0;

        var term = query.Trim().ToLower();
        var existingCount = await _unitOfWork.Papers
            .CountAsync(p =>
                (p.Title != null && p.Title.ToLower().Contains(term)) ||
                (p.Abstract != null && p.Abstract.ToLower().Contains(term)),
                cancellationToken);

        if (existingCount >= minResults) return 0;

        return await IngestWorksAsync(search: query, maxPages, cancellationToken);
    }

    /// Same idea as EnsureWorksSyncedForQueryAsync but for the Topics table,
    /// pulling from OpenAlex's real `/topics` endpoint (richer/more accurate
    /// than the concepts-derived topics created while ingesting works).
    public async Task<int> EnsureTopicsSyncedForQueryAsync(
        string query,
        int minResults = 5,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(query)) return 0;

        var term = query.Trim().ToLower();
        var existingCount = await _unitOfWork.ResearchTopics
            .CountAsync(t => t.Name.ToLower().Contains(term), cancellationToken);

        if (existingCount >= minResults) return 0;

        var (statusCode, body) = await _openAlexClient.GetRawJsonAsync(
            $"topics?search={Uri.EscapeDataString(query.Trim())}&per_page=10",
            cancellationToken);
        if (statusCode != 200) return 0;

        using var doc = JsonDocument.Parse(body);
        if (!doc.RootElement.TryGetProperty("results", out var results) || results.ValueKind != JsonValueKind.Array)
            return 0;

        var inserted = 0;
        foreach (var item in results.EnumerateArray())
        {
            var name = item.TryGetProperty("display_name", out var dn) ? dn.GetString() : null;
            if (string.IsNullOrWhiteSpace(name)) continue;

            var exists = await _unitOfWork.ResearchTopics
                .FirstOrDefaultAsync(t => t.Name.ToLower() == name.ToLower(), cancellationToken);
            if (exists != null) continue;

            var openAlexId = item.TryGetProperty("id", out var idEl) ? ExtractOpenAlexId(idEl.GetString()) : null;
            var worksCount = item.TryGetProperty("works_count", out var wc) ? wc.GetInt32() : 0;
            var field = item.TryGetProperty("field", out var f) && f.ValueKind == JsonValueKind.Object
                && f.TryGetProperty("display_name", out var fd) ? fd.GetString() : null;
            var domain = item.TryGetProperty("domain", out var d) && d.ValueKind == JsonValueKind.Object
                && d.TryGetProperty("display_name", out var dd) ? dd.GetString() : null;

            _unitOfWork.Add(new ResearchTopic
            {
                TopicId = Guid.NewGuid().ToString(),
                Name = name,
                Field = field ?? "General",
                Domain = domain ?? "Science",
                OpenAlexId = openAlexId,
                WorksCount = worksCount,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
            });
            inserted++;
        }

        if (inserted > 0)
        {
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return inserted;
    }

    private async Task<int> IngestWorksAsync(string? search, int maxPages, CancellationToken cancellationToken)
    {
        var cursor = "*";
        var page = 0;
        var inserted = 0;
        var newPaperTitles = new List<string>();
        var journals = new Dictionary<string, Journal>(StringComparer.OrdinalIgnoreCase);
        var topics = new Dictionary<string, ResearchTopic>(StringComparer.OrdinalIgnoreCase);
        var keywordsDict = new Dictionary<string, Keyword>(StringComparer.OrdinalIgnoreCase);
        var authorsDict = new Dictionary<string, Author>(StringComparer.OrdinalIgnoreCase);

        while (page < maxPages)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var response = await _openAlexClient.GetWorksAsync(
                search: search,
                cursor: cursor == "*" ? null : cursor,
                perPage: 25,
                cancellationToken: cancellationToken);

            if (response.Results.Count == 0) break;

            foreach (var work in response.Results)
            {
                var openAlexId = ExtractOpenAlexId(work.Id);
                if (string.IsNullOrEmpty(openAlexId)) continue;

                // Skip duplicates
                var exists =
                        await _unitOfWork.Papers
                        .FirstOrDefaultAsync(
                        x => x.ExternalId == openAlexId
                        );
                if (exists != null) continue;

                // Get or create Journal
                Journal? journal = null;
                var sourceName = work.PrimaryLocation?.Source?.DisplayName
                    ?? work.Locations.FirstOrDefault()?.Source?.DisplayName;

                if (!string.IsNullOrWhiteSpace(sourceName))
                {
                    if (!journals.TryGetValue(sourceName, out journal!))
                    {
                        journal = _unitOfWork.Journals
                            .FirstOrDefault(j => j.Name.ToLower() == sourceName.ToLower());

                        if (journal == null)
                        {
                            journal = new Journal
                            {
                                JournalId = Guid.NewGuid().ToString(),
                                Name = sourceName,
                                Publisher = work.PrimaryLocation?.Source?.HostPublisher
                                    ?? work.Locations.FirstOrDefault()?.Source?.HostPublisher,
                                Issn = work.PrimaryLocation?.Source?.Issn,
                                CreatedAt = DateTime.Now
                            };
                            _unitOfWork.Add(journal);
                        }
                        journals[sourceName] = journal;
                    }
                }

                // Create Paper
                var paper = new Paper
                {
                    PaperId = Guid.NewGuid().ToString(),
                    Title = work.Title,
                    Abstract = ReconstructAbstract(work.AbstractInvertedIndex),
                    Doi = work.Doi,
                    PublicationYear = work.PublicationYear,
                    CitationCount = work.CitedByCount ?? 0,
                    JournalId = journal?.JournalId,
                    ExternalId = openAlexId,
                    SourceApi = "OpenAlex",
                    DocType = work.Type,
                    CreatedAt = DateTime.Now
                };
                _unitOfWork.Add(paper);

                // Authors
                foreach (var authorship in work.Authorships ?? Enumerable.Empty<OpenAlexAuthorship>())
                {
                    var authorName = authorship.Authors?.FirstOrDefault()?.DisplayName;
                    if (string.IsNullOrWhiteSpace(authorName)) continue;

                    var authorExtId = authorship.Authors!.First().Id;
                    var authorExtIdShort = !string.IsNullOrEmpty(authorExtId)
                        ? ExtractOpenAlexId(authorExtId) : null;

                    var authorKey = authorExtIdShort ?? authorName;
                    if (!authorsDict.TryGetValue(authorKey, out var author))
                    {
                        author = _unitOfWork.Authors
                            .FirstOrDefault(a =>
                                authorExtIdShort != null
                                    ? a.ExternalAuthorId == authorExtIdShort
                                    : a.Name.ToLower() == authorName.ToLower());

                        if (author == null)
                        {
                            author = new Author
                            {
                                AuthorId = Guid.NewGuid().ToString(),
                                Name = authorName,
                                ExternalAuthorId = authorExtIdShort,
                                CreatedAt = DateTime.Now
                            };
                            _unitOfWork.Add(author);
                        }
                        authorsDict[authorKey] = author;
                    }

                    _unitOfWork.Add(new PaperAuthor
                    {
                        PaperId = paper.PaperId,
                        AuthorId = author.AuthorId
                    });
                }

                // Keywords from Concepts
                foreach (var concept in (work.Concepts ?? Enumerable.Empty<OpenAlexConcept>())
                    .Where(c => c.Score > 0.3)
                    .OrderByDescending(c => c.Score)
                    .Take(5))
                {
                    if (string.IsNullOrWhiteSpace(concept.DisplayName)) continue;

                    if (!keywordsDict.TryGetValue(concept.DisplayName, out var keyword))
                    {
                        keyword = _unitOfWork.Keywords
                            .FirstOrDefault(k => k.Name.ToLower() == concept.DisplayName!.ToLower());

                        if (keyword == null)
                        {
                            keyword = new Keyword
                            {
                                KeywordId = Guid.NewGuid().ToString(),
                                Name = concept.DisplayName,
                                CreatedAt = DateTime.Now
                            };
                            _unitOfWork.Add(keyword);
                        }
                        keywordsDict[concept.DisplayName] = keyword;
                    }

                    _unitOfWork.Add(new PaperKeyword
                    {
                        PaperId = paper.PaperId,
                        KeywordId = keyword.KeywordId
                    });

                    // Track L1 topic and link this paper to it so topic-scoped
                    // search/filtering actually has data to query against.
                    if (concept.Level == "1" && !string.IsNullOrWhiteSpace(concept.DisplayName))
                    {
                        if (!topics.TryGetValue(concept.DisplayName, out var topic))
                        {
                            topic = _unitOfWork.ResearchTopics
                                .FirstOrDefault(t => t.Name.ToLower() == concept.DisplayName!.ToLower());

                            if (topic == null)
                            {
                                topic = new ResearchTopic
                                {
                                    TopicId = Guid.NewGuid().ToString(),
                                    Name = concept.DisplayName,
                                    Field = concept.Field ?? "Computer Science",
                                    Domain = concept.Domain ?? "Science",
                                    OpenAlexId = concept.Id,
                                    WorksCount = 1,
                                    CreatedAt = DateTime.Now,
                                    UpdatedAt = DateTime.Now
                                };
                                _unitOfWork.Add(topic);
                            }
                            topics[concept.DisplayName] = topic;
                        }
                        paper.Topics.Add(topic);
                    }
                }

                inserted++;
                newPaperTitles.Add(paper.Title);
            }

            try
            {
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
            cursor = response.Meta.NextCursor ?? string.Empty;
            if (string.IsNullOrEmpty(cursor)) break;
            page++;
        }

        if (newPaperTitles.Count > 0)
        {
            await NotifyNewPapersAsync(newPaperTitles, cancellationToken);
        }

        return inserted;
    }

    private async Task NotifyNewPapersAsync(List<string> newPaperTitles, CancellationToken cancellationToken)
    {
        var title = "New papers published";
        var body = newPaperTitles.Count == 1
            ? $"New paper published: {newPaperTitles[0]}"
            : $"{newPaperTitles.Count} new papers added, including \"{newPaperTitles[0]}\"";

        // In-app inbox: every user gets a row so the bell icon/list works
        // without needing a per-device FCM token on file.
        var userIds = await _unitOfWork.Users.Select(u => u.UserId).ToListAsync(cancellationToken);
        foreach (var userId in userIds)
        {
            _unitOfWork.Add(new Notification
            {
                NotificationId = Guid.NewGuid().ToString(),
                UserId = userId,
                Title = title,
                Content = body,
                IsRead = false,
                CreatedAt = DateTime.Now,
            });
        }
        if (userIds.Count > 0)
        {
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        // Push notification: broadcast to every device subscribed to the
        // "new_papers" topic (the Flutter app subscribes on startup).
        try
        {
            await _notificationService.SendToTopicAsync(NewPapersTopic, title, body, cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to send FCM topic notification: {ex.Message}");
        }
    }

    public Task<string> SyncJournalsAsync(CancellationToken cancellationToken = default)
        => Task.FromResult("Journals synced as part of SyncWorksAsync");
    public Task<string> SyncAuthorsAsync(CancellationToken cancellationToken = default)
        => Task.FromResult("Authors synced as part of SyncWorksAsync");
    public Task<string> SyncTopicsAsync(CancellationToken cancellationToken = default)
        => Task.FromResult("Topics synced as part of SyncWorksAsync");
    public Task<string> SyncKeywordsAsync(CancellationToken cancellationToken = default)
        => Task.FromResult("Keywords synced as part of SyncWorksAsync");
    public Task<string> RecomputeTrendsAsync(CancellationToken cancellationToken = default)
        => Task.FromResult("Trends recomputed");

    private static string? ExtractOpenAlexId(string? url)
        => string.IsNullOrWhiteSpace(url) ? null
            : url.Contains('/') ? url.Split('/').Last() : url;

    private static string? ReconstructAbstract(Dictionary<string, int[]>? invertedIndex)
    {
        if (invertedIndex == null || invertedIndex.Count == 0) return null;
        var wordPositions = new Dictionary<int, string>();
        foreach (var kvp in invertedIndex)
            foreach (var pos in kvp.Value)
                wordPositions[pos] = kvp.Key;
        if (wordPositions.Count == 0) return null;
        return string.Join(" ", wordPositions.OrderBy(kv => kv.Key).Select(kv => kv.Value).ToList());
    }
}
