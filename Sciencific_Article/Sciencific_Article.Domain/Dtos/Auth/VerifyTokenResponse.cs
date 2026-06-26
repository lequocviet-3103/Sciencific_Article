namespace Sciencific_Article.Domain.Dtos.Auth;

public class VerifyTokenResponse
{
    public bool Success { get; set; }

    public string? Message { get; set; }

    public UserDto? User { get; set; }

    public string? AccessToken { get; set; }
}
