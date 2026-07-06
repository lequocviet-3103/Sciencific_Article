using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class ReportGeneratorService : IReportGeneratorService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IReportRepository _reportRepository;
    private readonly IFirebaseStorageService _storageService;

    public ReportGeneratorService(
        IUnitOfWork unitOfWork,
        IReportRepository reportRepository,
        IFirebaseStorageService storageService)
    {
        _unitOfWork = unitOfWork;
        _reportRepository = reportRepository;
        _storageService = storageService;
    }

    public async Task<Report> GenerateDashboardReportAsync(
        string userId,
        string? query,
        string? topicId,
        CancellationToken cancellationToken = default)
    {
        var searchTerm = query?.Trim();
        if (string.IsNullOrWhiteSpace(searchTerm) && !string.IsNullOrWhiteSpace(topicId))
        {
            var topic = await _unitOfWork.ResearchTopics
                .FirstOrDefaultAsync(t => t.TopicId == topicId, cancellationToken);
            searchTerm = topic?.Name;
        }

        var papers = _unitOfWork.Papers.AsQueryable();
        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLower();
            papers = papers.Where(p =>
                (p.Title != null && p.Title.ToLower().Contains(term)) ||
                (p.Abstract != null && p.Abstract.ToLower().Contains(term)));
        }

        var matched = await papers
            .Select(p => new { p.PaperId, p.Title, p.PublicationYear, p.CitationCount, p.JournalId })
            .ToListAsync(cancellationToken);
        var matchedIds = matched.Select(p => p.PaperId).ToHashSet();

        var trendByYear = matched
            .Where(p => p.PublicationYear.HasValue)
            .GroupBy(p => p.PublicationYear!.Value)
            .Select(g => (Year: g.Key, Count: g.Count()))
            .OrderBy(x => x.Year)
            .ToList();

        var topJournals = matched
            .Where(p => p.JournalId != null)
            .GroupBy(p => p.JournalId)
            .Select(g => (JournalId: g.Key!, Count: g.Count()))
            .OrderByDescending(x => x.Count)
            .Take(5)
            .ToList();
        var journalNames = await _unitOfWork.Journals
            .Where(j => topJournals.Select(t => t.JournalId).Contains(j.JournalId))
            .ToDictionaryAsync(j => j.JournalId, j => j.Name, cancellationToken);

        var topAuthors = await _unitOfWork.PaperAuthors
            .Where(pa => matchedIds.Contains(pa.PaperId))
            .GroupBy(pa => pa.AuthorId)
            .Select(g => new { AuthorId = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(5)
            .ToListAsync(cancellationToken);
        var authorNames = await _unitOfWork.Authors
            .Where(a => topAuthors.Select(t => t.AuthorId).Contains(a.AuthorId))
            .ToDictionaryAsync(a => a.AuthorId, a => a.Name, cancellationToken);

        var pdfBytes = BuildPdf(
            searchTerm,
            matched.Count,
            trendByYear,
            topJournals.Select(j => (journalNames.GetValueOrDefault(j.JournalId, "Unknown"), j.Count)).ToList(),
            topAuthors.Select(a => (authorNames.GetValueOrDefault(a.AuthorId, "Unknown"), a.Count)).ToList());

        var reportId = Guid.NewGuid().ToString();
        string? fileUrl;
        using (var stream = new MemoryStream(pdfBytes))
        {
            fileUrl = await _storageService.UploadAsync(
                string.Empty,
                $"reports/{reportId}.pdf",
                stream,
                "application/pdf",
                cancellationToken);
        }

        var report = new Report
        {
            ReportId = reportId,
            UserId = userId,
            TopicId = topicId,
            ReportType = "Dashboard Report",
            FileUrl = fileUrl,
            CreatedAt = DateTime.Now,
        };

        return await _reportRepository.AddAsync(report, cancellationToken);
    }

    private static byte[] BuildPdf(
        string? searchTerm,
        int totalPapers,
        List<(int Year, int Count)> trendByYear,
        List<(string Name, int Count)> topJournals,
        List<(string Name, int Count)> topAuthors)
    {
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Margin(36);
                page.Size(PageSizes.A4);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Column(col =>
                {
                    col.Item().Text("Dashboard Report").FontSize(22).Bold();
                    col.Item().Text(string.IsNullOrWhiteSpace(searchTerm)
                        ? "All papers"
                        : $"Topic: \"{searchTerm}\"").FontSize(13).FontColor(Colors.Grey.Darken1);
                    col.Item().Text($"Generated {DateTime.Now:yyyy-MM-dd HH:mm}").FontSize(9).FontColor(Colors.Grey.Medium);
                    col.Item().PaddingTop(4).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                });

                page.Content().PaddingTop(16).Column(col =>
                {
                    col.Spacing(20);

                    col.Item().Text($"Matched papers: {totalPapers}").FontSize(12).SemiBold();

                    col.Item().Column(section =>
                    {
                        section.Item().Text("Publication Trend by Year").FontSize(14).Bold();
                        section.Item().PaddingTop(4).Table(table =>
                        {
                            table.ColumnsDefinition(c => { c.RelativeColumn(); c.RelativeColumn(); });
                            table.Header(h =>
                            {
                                h.Cell().Text("Year").Bold();
                                h.Cell().Text("Papers").Bold();
                            });
                            if (trendByYear.Count == 0)
                            {
                                table.Cell().ColumnSpan(2).Text("No data");
                            }
                            foreach (var (year, count) in trendByYear)
                            {
                                table.Cell().Text(year.ToString());
                                table.Cell().Text(count.ToString());
                            }
                        });
                    });

                    col.Item().Column(section =>
                    {
                        section.Item().Text("Top Authors").FontSize(14).Bold();
                        section.Item().PaddingTop(4).Table(table =>
                        {
                            table.ColumnsDefinition(c => { c.RelativeColumn(3); c.RelativeColumn(); });
                            table.Header(h =>
                            {
                                h.Cell().Text("Author").Bold();
                                h.Cell().Text("Papers").Bold();
                            });
                            if (topAuthors.Count == 0)
                            {
                                table.Cell().ColumnSpan(2).Text("No data");
                            }
                            foreach (var (name, count) in topAuthors)
                            {
                                table.Cell().Text(name);
                                table.Cell().Text(count.ToString());
                            }
                        });
                    });

                    col.Item().Column(section =>
                    {
                        section.Item().Text("Top Journals").FontSize(14).Bold();
                        section.Item().PaddingTop(4).Table(table =>
                        {
                            table.ColumnsDefinition(c => { c.RelativeColumn(3); c.RelativeColumn(); });
                            table.Header(h =>
                            {
                                h.Cell().Text("Journal").Bold();
                                h.Cell().Text("Papers").Bold();
                            });
                            if (topJournals.Count == 0)
                            {
                                table.Cell().ColumnSpan(2).Text("No data");
                            }
                            foreach (var (name, count) in topJournals)
                            {
                                table.Cell().Text(name);
                                table.Cell().Text(count.ToString());
                            }
                        });
                    });
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Generated by ResearchHub — Scientific Article Trend Analysis");
                    x.DefaultTextStyle(s => s.FontSize(8).FontColor(Colors.Grey.Medium));
                });
            });
        });

        return document.GeneratePdf();
    }
}
