using Sciencific_Article.Domain.Dtos.Auth;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Interfaces.Services;

public interface IAuthService
{
    Task<VerifyTokenResponse> VerifyIdTokenAsync(
        string idToken,
        string? roleId = null,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Role>> GetAvailableRolesAsync(CancellationToken cancellationToken = default);

    Task<VerifyTokenResponse> AssignPrivilegedRoleAsync(
        string userId,
        string roleId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<UserDto>> GetAllUsersAsync(CancellationToken cancellationToken = default);
}
