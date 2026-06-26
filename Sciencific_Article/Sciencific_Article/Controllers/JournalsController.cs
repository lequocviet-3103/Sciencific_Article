using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/journals")]
public class JournalsController : ControllerBase
{
    private readonly IJournalRepository _journalRepository;

    public JournalsController(IJournalRepository journalRepository)
    {
        _journalRepository = journalRepository;
    }

    /*[HttpGet]
    public async Task<ActionResult<IEnumerable<Journal>>> GetAll(CancellationToken cancellationToken)
    {
        var journals = await _journalRepository.GetAllAsync(cancellationToken);
        return Ok(journals);
    }*/

    [HttpGet("{journalId}")]
    public async Task<ActionResult<Journal>> Get([FromRoute] string journalId, CancellationToken cancellationToken)
    {
        var journal = await _journalRepository.GetByIdAsync(journalId, cancellationToken);
        if (journal == null) return NotFound();
        return Ok(journal);
    }
}
