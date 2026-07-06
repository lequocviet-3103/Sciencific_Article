using AutoMapper;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Dtos.Auth;
using Sciencific_Article.Domain.Entities;

namespace Sciencific_Article.Application.Services;

public class AuthService : IAuthService
{
    public const string CustomerRoleId = "3";
    public const string AdminRoleId = "1";
    public const string ResearcherRoleId = "2";

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
            // Public login/register can only create Customer accounts. Admin/Researcher
            // accounts are granted separately via AssignRoleAsync, never self-selected here.
            user = new User
            {
                UserId = Guid.NewGuid().ToString(),
                FirebaseUid = firebaseUid,
                Email = email ?? string.Empty,
                FullName = string.IsNullOrWhiteSpace(name) ? email ?? "User" : name,
                RoleId = CustomerRoleId,
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

    public async Task<VerifyTokenResponse> AssignPrivilegedRoleAsync(
        string userId,
        string roleId,
        CancellationToken cancellationToken = default)
    {
        // Used by the admin console only (never by public register/login),
        // so unlike VerifyIdTokenAsync this accepts any of the three known
        // roles — including demoting an Admin/Researcher back to Customer.
        if (roleId != AdminRoleId && roleId != ResearcherRoleId && roleId != CustomerRoleId)
        {
            return new VerifyTokenResponse { Success = false, Message = "Unknown roleId" };
        }

        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user == null)
        {
            return new VerifyTokenResponse { Success = false, Message = "User not found" };
        }

        user.RoleId = roleId;
        user.UpdatedAt = DateTime.Now;
        await _userRepository.UpdateAsync(user, cancellationToken);

        var dto = _mapper.Map<UserDto>(user);
        return new VerifyTokenResponse { Success = true, User = dto };
    }

    public async Task<IReadOnlyList<UserDto>> GetAllUsersAsync(CancellationToken cancellationToken = default)
    {
        var users = await Task.Run(
            () => _unitOfWork.Users
                .Select(u => new { u, u.Role.RoleName })
                .ToList(),
            cancellationToken);

        return users.Select(x =>
        {
            var dto = _mapper.Map<UserDto>(x.u);
            dto.RoleName = x.RoleName ?? string.Empty;
            return dto;
        }).ToList();
    }
}
