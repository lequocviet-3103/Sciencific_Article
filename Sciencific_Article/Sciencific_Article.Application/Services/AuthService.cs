using AutoMapper;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Dtos.Auth;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class AuthService : IAuthService
{
    private readonly IFirebaseAuthService _firebaseAuthService;
    private readonly IUserRepository _userRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public AuthService(
        IFirebaseAuthService firebaseAuthService,
        IUserRepository userRepository,
        IUnitOfWork unitOfWork,
        IMapper mapper)
    {
        _firebaseAuthService = firebaseAuthService;
        _userRepository = userRepository;
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<VerifyTokenResponse> VerifyIdTokenAsync(
        string idToken,
        string? roleId = null,
        CancellationToken cancellationToken = default)
    {
        var token = await _firebaseAuthService.VerifyIdTokenAsync(idToken, cancellationToken);
        var firebaseUid = token.Uid;
        var email = token.Claims.TryGetValue("email", out var emailObj) ? emailObj?.ToString() : null;
        var name = token.Claims.TryGetValue("name", out var nameObj) ? nameObj?.ToString() : null;

        var user = await _userRepository.GetByFirebaseUidAsync(firebaseUid, cancellationToken);

        if (user == null)
        {
            var resolvedRoleId = roleId ?? "Researcher";
            user = new User
            {
                UserId = Guid.NewGuid().ToString(),
                FirebaseUid = firebaseUid,
                Email = email ?? string.Empty,
                FullName = string.IsNullOrWhiteSpace(name) ? email ?? "User" : name,
                RoleId = resolvedRoleId,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
            };

            await _userRepository.AddAsync(user, cancellationToken);
        }
        else
        {
            user.Email = string.IsNullOrWhiteSpace(email) ? user.Email : email;
            user.FullName = string.IsNullOrWhiteSpace(name) ? user.FullName : name;
            user.UpdatedAt = DateTime.Now;
            await _userRepository.UpdateAsync(user, cancellationToken);
        }

        var dto = _mapper.Map<UserDto>(user);
        return new VerifyTokenResponse { Success = true, User = dto };
    }

    public async Task<IReadOnlyList<Role>> GetAvailableRolesAsync(CancellationToken cancellationToken = default)
    {
        var roles = await Task.Run(() => _unitOfWork.Roles.ToList(), cancellationToken);
        return roles;
    }
}
