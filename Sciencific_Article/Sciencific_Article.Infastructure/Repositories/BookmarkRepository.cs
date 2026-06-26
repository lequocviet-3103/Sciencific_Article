using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Infastructure.Repositories;

public class BookmarkRepository : IBookmarkRepository
{
    private readonly AppDbContext _context;

    public BookmarkRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<Bookmark>> GetByUserAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var q = _context.Bookmarks.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAt);
        var total = await q.CountAsync(cancellationToken);
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(cancellationToken);
        return new PagedResult<Bookmark> { Items = items, TotalCount = total, Page = page, PageSize = pageSize };
    }

    public async Task<Bookmark?> GetAsync(string userId, string paperId, CancellationToken cancellationToken = default)
        => await _context.Bookmarks.FirstOrDefaultAsync(x => x.UserId == userId && x.PaperId == paperId, cancellationToken);

    public async Task<Bookmark> AddAsync(Bookmark bookmark, CancellationToken cancellationToken = default)
    {
        _context.Bookmarks.Add(bookmark);
        await _context.SaveChangesAsync(cancellationToken);
        return bookmark;
    }

    public async Task RemoveAsync(Bookmark bookmark, CancellationToken cancellationToken = default)
    {
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task RemoveAsync(string bookmarkId, CancellationToken cancellationToken = default)
    {
        var bookmark = await _context.Bookmarks.FirstOrDefaultAsync(x => x.BookmarkId == bookmarkId, cancellationToken);
        if (bookmark == null) return;
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> CountByUserAsync(string userId, CancellationToken cancellationToken = default)
        => await _context.Bookmarks.CountAsync(x => x.UserId == userId, cancellationToken);
}
