namespace Sciencific_Article.Domain.Dtos.Auth;

public class UserDto
{
    public string UserId { get; set; } = string.Empty;

    public string FirebaseUid { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string FullName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    public string RoleId { get; set; } = string.Empty;

    public string RoleName { get; set; } = string.Empty;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
