using Microsoft.AspNetCore.Mvc;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Dtos.Auth;

namespace Sciencific_Article.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("verify-token")]
    public async Task<ActionResult<VerifyTokenResponse>> VerifyToken([FromBody] VerifyTokenRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.IdToken)) return BadRequest(new VerifyTokenResponse { Success = false, Message = "IdToken is required" });
        var result = await _authService.VerifyIdTokenAsync(request.IdToken, request.RoleId, cancellationToken);
        return Ok(result);
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me(CancellationToken cancellationToken)
    {
        // Demo: attach user after verify-token in production middleware
        return Ok(new UserDto());
    }

    [HttpPost("assign-role")]
    public async Task<ActionResult<VerifyTokenResponse>> AssignRole([FromBody] AssignRoleRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.UserId) || string.IsNullOrWhiteSpace(request.RoleId))
        {
            return BadRequest(new VerifyTokenResponse { Success = false, Message = "UserId and RoleId are required" });
        }

        var result = await _authService.AssignPrivilegedRoleAsync(request.UserId, request.RoleId, cancellationToken);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<UserDto>>> GetUsers(CancellationToken cancellationToken)
    {
        var users = await _authService.GetAllUsersAsync(cancellationToken);
        return Ok(users);
    }

    [HttpGet("roles")]
    public async Task<ActionResult<IReadOnlyList<RoleDto>>> GetRoles(CancellationToken cancellationToken)
    {
        var roles = await _authService.GetAvailableRolesAsync(cancellationToken);
        var data = roles.Select(r => new RoleDto
        {
            RoleId = r.RoleId,
            RoleName = r.RoleName,
            Description = r.Description
        }).ToList();
        return Ok(data);
    }
}
