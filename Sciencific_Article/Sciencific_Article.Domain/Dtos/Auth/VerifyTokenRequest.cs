namespace Sciencific_Article.Domain.Dtos.Auth;

public class VerifyTokenRequest
{
    public string IdToken { get; set; } = string.Empty;
    public string RoleId { get; set; } = string.Empty;
}
