namespace Sciencific_Article.Domain.Dtos.Auth;

public class AssignRoleRequest
{
    public string UserId { get; set; } = string.Empty;
    public string RoleId { get; set; } = string.Empty;
}
