using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/keywords")]
public class KeywordsController : ControllerBase
{
    private readonly IKeywordRepository _keywordRepository;

    public KeywordsController(IKeywordRepository keywordRepository)
    {
        _keywordRepository = keywordRepository;
    }

    /*[HttpGet]
    public async Task<ActionResult<IEnumerable<Keyword>>> GetAll(CancellationToken cancellationToken)
    {
        var keywords = await _keywordRepository.GetAllAsync(cancellationToken);
        return Ok(keywords);
    }*/
}
