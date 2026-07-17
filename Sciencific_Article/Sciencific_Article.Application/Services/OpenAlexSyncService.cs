using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class OpenAlexSyncService : IOpenAlexSyncService
{
    public const string NewPapersTopic = "new_papers";
    private const int DefaultSyncCount = 50;
    private const int MaxManualSyncCount = 1000;
    private static readonly SemaphoreSlim SyncGate = new(1, 1);

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
        => (await SyncWorksAsync(DefaultSyncCount, cancellationToken)).Message;

    public async Task<SyncWorksResult> SyncWorksAsync(
        int requestedCount,
        CancellationToken cancellationToken = default)
    {
        if (requestedCount < 1 || requestedCount > MaxManualSyncCount)
        {
            throw new ArgumentOutOfRangeException(
                nameof(requestedCount),
                $"Requested count must be between 1 and {MaxManualSyncCount}.");
        }

        if (!await SyncGate.WaitAsync(0, cancellationToken))
        {
            throw new InvalidOperationException("Another OpenAlex sync is already running.");
        }

        try
        {
            // Scan well beyond the requested number so already-synced works do
            // not prevent the admin from receiving the requested number of new
            // rows. The cap prevents an unbounded request when OpenAlex mostly
            // returns records that already exist locally.
            var maxPages = Math.Clamp(
                (int)Math.Ceiling(requestedCount / 100d) * 5,
                20,
                100);

            var ingest = await IngestWorksAsync(
                search: null,
                filter: "authors_count:>0",
                maxPages: maxPages,
                maxNewPapers: requestedCount,
                cancellationToken: cancellationToken);

            var result = new SyncWorksResult(
                requestedCount,
                ingest.InsertedCount,
                ingest.SkippedDuplicates,
                ingest.ScannedCount,
                ingest.SourceExhausted);

            _unitOfWork.Add(new SyncLog
            {
                SyncLogId = Guid.NewGuid().ToString(),
                SourceApi = "OpenAlex",
                Status = ingest.InsertedCount >= requestedCount ? "Success" : "Partial",
                RecordsInserted = ingest.InsertedCount,
                ErrorMessage = ingest.InsertedCount >= requestedCount ? null : result.Message,
                SyncTime = DateTime.Now,
            });
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return result;
        }
        finally
        {
            SyncGate.Release();
        }
    }

    /// Resolves a topic display name (e.g. "Computer science") into an
    /// OpenAlex topic ID (e.g. "T11925") that can be used as a
    /// `topics.id:<id>` filter on the works endpoint.
    ///
    /// Uses the cached ID on ResearchTopic.OpenAlexId when available so we
    /// don't hit the /topics lookup on every sync. Falls back to the /topics
    /// endpoint for topics we haven't seen before, then persists the new ID
    /// so future syncs can skip the lookup.
    ///
    /// Returns null when the topic name can't be resolved (no match, network
    /// error, etc.) so the caller can fall back to a full-text search.
    private async Task<string?> ResolveTopicOpenAlexIdAsync(
        string topicName,
        Dictionary<string, string> cachedIdsByName,
        CancellationToken cancellationToken)
    {
        if (cachedIdsByName.TryGetValue(topicName, out var cached) && !string.IsNullOrWhiteSpace(cached))
            return cached;

        try
        {
            var (statusCode, body) = await _openAlexClient.GetRawJsonAsync(
                $"topics?search={Uri.EscapeDataString(topicName)}&per_page=1",
                cancellationToken);
            if (statusCode != 200 || string.IsNullOrWhiteSpace(body))
                return null;

            using var doc = JsonDocument.Parse(body);
            if (!doc.RootElement.TryGetProperty("results", out var results)
                || results.ValueKind != JsonValueKind.Array
                || results.GetArrayLength() == 0)
                return null;

            var first = results[0];
            if (!first.TryGetProperty("id", out var idEl) || idEl.ValueKind != JsonValueKind.String)
                return null;

            // OpenAlex returns IDs as full URLs like
            // "https://openalex.org/T12345"; strip them down to the bare
            // short form that `topics.id:<id>` accepts.
            var rawId = idEl.GetString();
            var shortId = ExtractOpenAlexId(rawId);
            if (string.IsNullOrEmpty(shortId) || !shortId.StartsWith("T", StringComparison.Ordinal))
                return null;

            // Persist on the matching DB row (if any) so the next sync can
            // reuse this without a network lookup.
            try
            {
                var tracked = _unitOfWork.ResearchTopics
                    .FirstOrDefault(t => t.Name.ToLower() == topicName.ToLower());
                if (tracked != null && string.IsNullOrWhiteSpace(tracked.OpenAlexId))
                {
                    tracked.OpenAlexId = shortId;
                    tracked.UpdatedAt = DateTime.Now;
                    await _unitOfWork.SaveChangesAsync(cancellationToken);
                }
            }
            catch (Exception ex)
            {
                // Caching the ID is a perf nicety; don't fail the whole
                // sync if the cache write fails.
                Console.WriteLine($"ResolveTopicOpenAlexIdAsync: cache write failed for '{topicName}': {ex.Message}");
            }

            return shortId;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ResolveTopicOpenAlexIdAsync: lookup failed for '{topicName}': {ex.Message}");
            return null;
        }
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

        var result = await IngestWorksAsync(
            search: query,
            filter: null,
            maxPages: maxPages,
            maxNewPapers: int.MaxValue,
            cancellationToken: cancellationToken);
        return result.InsertedCount;
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

    private async Task<IngestWorksResult> IngestWorksAsync(
        string? search,
        string? filter,
        int maxPages,
        int maxNewPapers,
        CancellationToken cancellationToken)
    {
        var cursor = "*";
        var page = 0;
        var inserted = 0;
        var scanned = 0;
        var skippedDuplicates = 0;
        var sourceExhausted = false;
        var newPaperTitles = new List<string>();
        var journals = new Dictionary<string, Journal>(StringComparer.OrdinalIgnoreCase);
        var keywordsDict = new Dictionary<string, Keyword>(StringComparer.OrdinalIgnoreCase);
        var authorsDict = new Dictionary<string, Author>(StringComparer.OrdinalIgnoreCase);
        var knownDoiKeys = (await _unitOfWork.Papers
                .AsNoTracking()
                .Where(p => p.Doi != null && p.Doi != "")
                .Select(p => p.Doi!)
                .ToListAsync(cancellationToken))
            .Select(NormalizeDoi)
            .Where(doi => doi != null)
            .Cast<string>()
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        while (page < maxPages && inserted < maxNewPapers)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var response = await _openAlexClient.GetWorksAsync(
                search: search,
                filter: filter,
                // OpenAlex cursor pagination must start with cursor="*".
                // Omitting it only returns the first page and no next cursor.
                cursor: cursor,
                perPage: 100,
                cancellationToken: cancellationToken);

            if (response.Results.Count == 0)
            {
                sourceExhausted = true;
                break;
            }

            // Pre-fetch all journals/topics/authors/keywords that we'll need
            // in one go, instead of issuing per-row lookups below.
            var incomingIds = response.Results
                .Select(w => ExtractOpenAlexId(w.Id))
                .Where(id => !string.IsNullOrEmpty(id))
                .Cast<string>()
                .ToList();

            var existingPapers = incomingIds.Count == 0
                ? new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                : (await _unitOfWork.Papers
                    .AsNoTracking()
                    .Where(p => p.ExternalId != null && incomingIds.Contains(p.ExternalId))
                    .Select(p => p.ExternalId!)
                    .ToListAsync(cancellationToken))
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);

            var journalNames = response.Results
                .Select(w => w.PrimaryLocation?.Source?.DisplayName
                    ?? w.Locations.FirstOrDefault()?.Source?.DisplayName)
                .Where(n => !string.IsNullOrWhiteSpace(n))
                .Cast<string>()
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            // DB rows can contain duplicates of the same journal name from
            // older syncs (the page-level cache now uses OrdinalIgnoreCase
            // but the underlying table has been written without deduping).
            // GroupBy ensures we hand back one entry per normalized name
            // instead of crashing ToDictionary with "An item with the same
            // key has already been added".
            var existingJournals = journalNames.Count == 0
                ? new Dictionary<string, Journal>(StringComparer.OrdinalIgnoreCase)
                : (await _unitOfWork.Journals
                    .AsNoTracking()
                    .Where(j => journalNames.Contains(j.Name))
                    .GroupBy(j => j.Name)
                    .Select(g => g.OrderBy(x => x.JournalId).First())
                    .ToListAsync(cancellationToken))
                    .ToDictionary(j => j.Name, j => j, StringComparer.OrdinalIgnoreCase);

            var incomingAuthorIds = response.Results
                .SelectMany(w => w.Authorships ?? Enumerable.Empty<OpenAlexAuthorship>())
                .Select(a => a.Authors?.FirstOrDefault()?.Id)
                .Where(id => !string.IsNullOrEmpty(id))
                .Select(id => ExtractOpenAlexId(id)!)
                .Where(id => !string.IsNullOrEmpty(id))
                .Distinct()
                .ToList();

            var existingAuthorsByExtId = incomingAuthorIds.Count == 0
                ? new Dictionary<string, Author>(StringComparer.OrdinalIgnoreCase)
                : (await _unitOfWork.Authors
                    .AsNoTracking()
                    .Where(a => a.ExternalAuthorId != null && incomingAuthorIds.Contains(a.ExternalAuthorId))
                    .GroupBy(a => a.ExternalAuthorId!)
                    .Select(g => g.OrderBy(x => x.AuthorId).First())
                    .ToListAsync(cancellationToken))
                    .ToDictionary(a => a.ExternalAuthorId!, a => a, StringComparer.OrdinalIgnoreCase);

            var incomingKeywords = response.Results
                .SelectMany(w => w.Concepts ?? Enumerable.Empty<OpenAlexConcept>())
                .Where(c => c.Score > 0.3 && !string.IsNullOrWhiteSpace(c.DisplayName))
                .Select(c => c.DisplayName!)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            var existingKeywords = incomingKeywords.Count == 0
                ? new Dictionary<string, Keyword>(StringComparer.OrdinalIgnoreCase)
                : (await _unitOfWork.Keywords
                    .AsNoTracking()
                    .Where(k => incomingKeywords.Contains(k.Name))
                    .ToListAsync(cancellationToken))
                    .ToDictionary(k => k.Name, k => k, StringComparer.OrdinalIgnoreCase);

            var incomingTopicNames = response.Results
                .SelectMany(w => w.Concepts ?? Enumerable.Empty<OpenAlexConcept>())
                .Where(c => c.Level == "1" && !string.IsNullOrWhiteSpace(c.DisplayName))
                .Select(c => c.DisplayName!)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            // Map name -> existing topic id only. Storing the tracked entity here
            // would let EF try to re-attach it across papers/pages in the same
            // DbContext, which is what causes "duplicate key value violates
            // unique constraint research_topics_pkey" when the same topic is
            // touched in two consecutive sync calls.
            // GroupBy dedupes any historical duplicate topic rows in the
            // table before ToDictionary tries to insert a duplicate key.
            var existingTopicIdsByName = incomingTopicNames.Count == 0
                ? new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                : (await _unitOfWork.ResearchTopics
                    .AsNoTracking()
                    .Where(t => incomingTopicNames.Contains(t.Name))
                    .GroupBy(t => t.Name)
                    .Select(g => new { Name = g.Key, TopicId = g.OrderBy(x => x.TopicId).First().TopicId })
                    .ToListAsync(cancellationToken))
                    .ToDictionary(x => x.Name, x => x.TopicId, StringComparer.OrdinalIgnoreCase);

            // Track topics that were newly created in this page so we can
            // reuse them (and not re-query DB) when the same name appears
            // again on a later work in the same page.
            var localTopicsByName = new Dictionary<string, ResearchTopic>(StringComparer.OrdinalIgnoreCase);
            foreach (var work in response.Results)
            {
                if (inserted >= maxNewPapers) break;
                scanned++;

                var openAlexId = ExtractOpenAlexId(work.Id);
                if (string.IsNullOrEmpty(openAlexId)) continue;

                // OpenAlex ids are the primary identity. DOI is a second guard
                // for legacy rows or records imported before ExternalId existed.
                var doiKey = NormalizeDoi(work.Doi);
                if (existingPapers.Contains(openAlexId) ||
                    (doiKey != null && knownDoiKeys.Contains(doiKey)))
                {
                    skippedDuplicates++;
                    continue;
                }

                // Get or create Journal
                Journal? journal = null;
                var sourceName = work.PrimaryLocation?.Source?.DisplayName
                    ?? work.Locations.FirstOrDefault()?.Source?.DisplayName;

                if (!string.IsNullOrWhiteSpace(sourceName))
                {
                    if (!journals.TryGetValue(sourceName, out journal!) &&
                        !existingJournals.TryGetValue(sourceName, out journal))
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
                        existingJournals[sourceName] = journal;
                    }
                    journals[sourceName] = journal!;
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
                var seenAuthorKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var seenTopicNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var authorship in work.Authorships ?? Enumerable.Empty<OpenAlexAuthorship>())
                {
                    var authorName = authorship.Authors?.FirstOrDefault()?.DisplayName;
                    if (string.IsNullOrWhiteSpace(authorName)) continue;

                    var authorExtId = authorship.Authors!.First().Id;
                    var authorExtIdShort = !string.IsNullOrEmpty(authorExtId)
                        ? ExtractOpenAlexId(authorExtId) : null;

                    var authorKey = authorExtIdShort ?? authorName;
                    // Skip if we've already linked this author to this paper
                    // (OpenAlex sometimes lists the same author twice in one work).
                    if (!seenAuthorKeys.Add(authorKey)) continue;

                    if (!authorsDict.TryGetValue(authorKey, out var author))
                    {
                        author = authorExtIdShort != null && existingAuthorsByExtId.TryGetValue(authorExtIdShort, out var existing)
                            ? existing
                            : null;

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
                            if (authorExtIdShort != null)
                                existingAuthorsByExtId[authorExtIdShort] = author;
                        }
                        authorsDict[authorKey] = author;
                    }

                    // Use explicit join row so attaching this author to the
                    // paper doesn't accidentally re-attach an existing tracked
                    // entity from earlier in the same SyncWorksAsync loop.
                    _unitOfWork.Add(new PaperAuthor
                    {
                        PaperId = paper.PaperId,
                        AuthorId = author.AuthorId
                    });
                }

                // Keywords from Concepts
                var seenKeywordNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var concept in (work.Concepts ?? Enumerable.Empty<OpenAlexConcept>())
                    .Where(c => c.Score > 0.3)
                    .OrderByDescending(c => c.Score)
                    .Take(5))
                {
                    if (string.IsNullOrWhiteSpace(concept.DisplayName)) continue;
                    if (!seenKeywordNames.Add(concept.DisplayName)) continue;

                    if (!keywordsDict.TryGetValue(concept.DisplayName, out var keyword))
                    {
                        keyword = existingKeywords.TryGetValue(concept.DisplayName, out var existing)
                            ? existing
                            : null;

                        if (keyword == null)
                        {
                            keyword = new Keyword
                            {
                                KeywordId = Guid.NewGuid().ToString(),
                                Name = concept.DisplayName,
                                CreatedAt = DateTime.Now
                            };
                            _unitOfWork.Add(keyword);
                            existingKeywords[concept.DisplayName] = keyword;
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
                        if (!seenTopicNames.Add(concept.DisplayName)) continue;

                        // Look in local cache first (inserted earlier this page).
                        // Then fall back to existing in DB. Either way we use
                        // the entity's TopicId directly without ever assigning
                        // an existing (untracked) entity as a nav-collection
                        // target on a brand-new Paper, which is what causes
                        // EF to re-attach a duplicate tracked instance and
                        // trip the primary-key constraint.
                        if (!localTopicsByName.TryGetValue(concept.DisplayName, out var topic))
                        {
                            if (existingTopicIdsByName.TryGetValue(concept.DisplayName, out var existingId))
                            {
                                // Existing topic already in DB. Find the
                                // tracked instance (if any) so we reuse it
                                // instead of creating a brand-new stub.
                                // Creating a stub and forcing Unchanged
                                // breaks on the 2nd sync call within the
                                // same Scoped DbContext because EF refuses
                                // to track two instances with the same key.
                                var tracked = _unitOfWork.Context
                                    .Set<ResearchTopic>()
                                    .Local
                                    .FirstOrDefault(t => t.TopicId == existingId);
                                if (tracked != null)
                                {
                                    topic = tracked;
                                }
                                else
                                {
                                    topic = new ResearchTopic
                                    {
                                        TopicId = existingId,
                                        Name = concept.DisplayName
                                    };
                                    var entry = _unitOfWork.Context.Entry(topic);
                                    if (entry.State == EntityState.Detached)
                                        entry.State = EntityState.Unchanged;
                                }
                                localTopicsByName[concept.DisplayName] = topic;
                            }
                            else
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
                                localTopicsByName[concept.DisplayName] = topic;
                            }
                        }
                        paper.Topics.Add(topic);
                    }
                }

                inserted++;
                existingPapers.Add(openAlexId);
                if (doiKey != null) knownDoiKeys.Add(doiKey);
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
            if (string.IsNullOrEmpty(cursor))
            {
                sourceExhausted = true;
                break;
            }
            page++;
        }

        if (newPaperTitles.Count > 0)
        {
            await NotifyNewPapersAsync(newPaperTitles, cancellationToken);
        }

        // Recompute WorksCount for every topic based on actual rows in
        // paper_topics, so the home page and topic cards show the real
        // number of papers linked to each topic rather than the stale
        // value (1) we set on first insert.
        await RecomputeTopicWorksCountsAsync(cancellationToken);

        return new IngestWorksResult(
            inserted,
            skippedDuplicates,
            scanned,
            sourceExhausted);
    }

    private async Task RecomputeTopicWorksCountsAsync(CancellationToken cancellationToken)
    {
        try
        {
            // Count the real rows in the join table per topic, then
            // push that count back onto ResearchTopic.WorksCount. We
            // explicitly do this with two LINQ queries instead of
            // SQL because the Application project doesn't reference
            // Microsoft.EntityFrameworkCore.Relational, so GetDbConnection
            // isn't available here.
            var countsByTopicId = await _unitOfWork.Context
                .Set<PaperTopic>()
                .GroupBy(pt => pt.TopicId)
                .Select(g => new { TopicId = g.Key, Count = g.Count() })
                .ToListAsync(cancellationToken);

            var counts = countsByTopicId.ToDictionary(x => x.TopicId, x => x.Count);
            var topics = await _unitOfWork.ResearchTopics
                .AsNoTracking()
                .ToListAsync(cancellationToken);

            var now = DateTime.Now;
            foreach (var topic in topics)
            {
                var realCount = counts.TryGetValue(topic.TopicId, out var c) ? c : 0;
                if (topic.WorksCount == realCount) continue;

                // If the same TopicId was already added to the change tracker
                // during this sync (e.g. we just inserted brand-new topics
                // while ingesting works), updating it through that tracked
                // instance is the only safe option — Attach(stub) on a key
                // EF already knows about throws "another instance with the
                // same key value is already being tracked".
                var tracked = _unitOfWork.Context
                    .Set<ResearchTopic>()
                    .Local
                    .FirstOrDefault(t => t.TopicId == topic.TopicId);
                if (tracked != null)
                {
                    tracked.WorksCount = realCount;
                    tracked.UpdatedAt = now;
                    continue;
                }

                // Otherwise, attach a stub with just the fields we want to
                // change so EF doesn't blow away unrelated columns.
                var stub = new ResearchTopic
                {
                    TopicId = topic.TopicId,
                    WorksCount = realCount,
                    UpdatedAt = now,
                };
                _unitOfWork.Context.Attach(stub);
                var entry = _unitOfWork.Context.Entry(stub);
                entry.Property(e => e.WorksCount).IsModified = true;
                entry.Property(e => e.UpdatedAt).IsModified = true;
            }
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            Console.WriteLine($"RecomputeTopicWorksCountsAsync: updated {countsByTopicId.Count} topics with papers, {topics.Count - countsByTopicId.Count} topics have 0 papers");
        }
        catch (Exception ex)
        {
            // Recompute is a display-only side effect; never fail the whole
            // sync just because this fails.
            Console.WriteLine($"RecomputeTopicWorksCountsAsync failed: {ex.Message}");
        }
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

    private sealed record IngestWorksResult(
        int InsertedCount,
        int SkippedDuplicates,
        int ScannedCount,
        bool SourceExhausted);

    private static string? NormalizeDoi(string? doi)
    {
        if (string.IsNullOrWhiteSpace(doi)) return null;

        var value = doi.Trim();
        if (value.StartsWith("https://doi.org/", StringComparison.OrdinalIgnoreCase))
            value = value["https://doi.org/".Length..];
        else if (value.StartsWith("http://doi.org/", StringComparison.OrdinalIgnoreCase))
            value = value["http://doi.org/".Length..];
        else if (value.StartsWith("doi:", StringComparison.OrdinalIgnoreCase))
            value = value["doi:".Length..];

        value = value.Trim();
        return value.Length == 0 ? null : value.ToLowerInvariant();
    }

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
