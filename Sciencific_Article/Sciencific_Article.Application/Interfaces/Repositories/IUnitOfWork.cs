using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Repositories;

public interface IUnitOfWork : IDisposable
{
    IQueryable<User> Users { get; }
    IQueryable<Paper> Papers { get; }
    IQueryable<Journal> Journals { get; }
    IQueryable<Author> Authors { get; }
    IQueryable<Keyword> Keywords { get; }
    IQueryable<Bookmark> Bookmarks { get; }
    IQueryable<Notification> Notifications { get; }
    IQueryable<Report> Reports { get; }
    IQueryable<Role> Roles { get; }
    IQueryable<FollowTopic> FollowTopics { get; }
    IQueryable<SyncLog> SyncLogs { get; }
    IQueryable<ResearchTopic> ResearchTopics { get; }
    IQueryable<PublicationTrend> PublicationTrends { get; }
    IQueryable<PaperAuthor> PaperAuthors { get; }
    IQueryable<PaperKeyword> PaperKeywords { get; }

    // Add methods for sync operations
    void Add<T>(T entity) where T : class;
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
