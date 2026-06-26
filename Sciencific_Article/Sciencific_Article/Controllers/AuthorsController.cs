using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/authors")]
public class AuthorsController : ControllerBase
{
    private readonly IAuthorRepository _authorRepository;

    public AuthorsController(IAuthorRepository authorRepository)
    {
        _authorRepository = authorRepository;
    }

    /*[HttpGet]
    public async Task<ActionResult<IEnumerable<Author>>> GetAll(CancellationToken cancellationToken)
    {
        var authors = await _authorRepository.GetAllAsync(cancellationToken);
        return Ok(authors);
    }*/
}
