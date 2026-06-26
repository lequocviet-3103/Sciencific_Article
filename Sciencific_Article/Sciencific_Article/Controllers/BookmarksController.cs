using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/bookmarks")]
public class BookmarksController : ControllerBase
{
    private readonly IBookmarkRepository _bookmarkRepository;

    public BookmarksController(IBookmarkRepository bookmarkRepository)
    {
        _bookmarkRepository = bookmarkRepository;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<Bookmark>>> GetByUser([FromQuery] string userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var result = await _bookmarkRepository.GetByUserAsync(userId, page, pageSize, cancellationToken);
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<Bookmark>> Create([FromBody] Bookmark bookmark, CancellationToken cancellationToken)
    {
        var created = await _bookmarkRepository.AddAsync(bookmark, cancellationToken);
        return CreatedAtAction(nameof(GetByUser), new { userId = bookmark.UserId }, created);
    }

    [HttpDelete("{bookmarkId}")]
    public async Task<IActionResult> Delete([FromRoute] string bookmarkId, CancellationToken cancellationToken)
    {
        await _bookmarkRepository.RemoveAsync(bookmarkId, cancellationToken);
        return NoContent();
    }
}
