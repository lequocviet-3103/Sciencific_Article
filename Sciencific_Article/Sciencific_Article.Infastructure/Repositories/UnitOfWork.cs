using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;

    public UnitOfWork(AppDbContext context)
    {
        _context = context;
    }

    public Microsoft.EntityFrameworkCore.DbContext Context => _context;

    public IQueryable<User> Users => _context.Users;
    public IQueryable<Paper> Papers => _context.Papers;
    public IQueryable<Journal> Journals => _context.Journals;
    public IQueryable<Author> Authors => _context.Authors;
    public IQueryable<Keyword> Keywords => _context.Keywords;
    public IQueryable<Bookmark> Bookmarks => _context.Bookmarks;
    public IQueryable<Notification> Notifications => _context.Notifications;
    public IQueryable<Report> Reports => _context.Reports;
    public IQueryable<Role> Roles => _context.Roles;
    public IQueryable<FollowTopic> FollowTopics => _context.FollowTopics;
    public IQueryable<SyncLog> SyncLogs => _context.SyncLogs;
    public IQueryable<ResearchTopic> ResearchTopics => _context.ResearchTopics;
    public IQueryable<PublicationTrend> PublicationTrends => _context.PublicationTrends;
    public IQueryable<PaperAuthor> PaperAuthors => _context.PaperAuthors;
    public IQueryable<PaperKeyword> PaperKeywords => _context.PaperKeywords;

    public void Add<T>(T entity) where T : class
    {
        _context.Add(entity);
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => _context.SaveChangesAsync(cancellationToken);

    public void Dispose()
    {
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}
