using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class OpenAlexSyncService : IOpenAlexSyncService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IOpenAlexClient _openAlexClient;

    public OpenAlexSyncService(
        IUnitOfWork unitOfWork,
        IOpenAlexClient openAlexClient)
    {
        _unitOfWork = unitOfWork;
        _openAlexClient = openAlexClient;
    }

    public async Task<string> SyncWorksAsync(CancellationToken cancellationToken = default)
    {
        var cursor = "*";
        var page = 0;
        var inserted = 0;
        var journals = new Dictionary<string, Journal>(StringComparer.OrdinalIgnoreCase);
        var topics = new Dictionary<string, ResearchTopic>(StringComparer.OrdinalIgnoreCase);
        var keywordsDict = new Dictionary<string, Keyword>(StringComparer.OrdinalIgnoreCase);
        var authorsDict = new Dictionary<string, Author>(StringComparer.OrdinalIgnoreCase);

        while (page < 2)    
        {
            cancellationToken.ThrowIfCancellationRequested();

            var response = await _openAlexClient.GetWorksAsync(
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

                    // Track L1 topic
                    if (concept.Level == "1" && !topics.ContainsKey(concept.DisplayName))
                    {
                        var topic = _unitOfWork.ResearchTopics
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
                }

                inserted++;
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

        return $"Synced {inserted} papers from OpenAlex";
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
