namespace Sciencific_Article.Domain.Dtos.Auth;

public class FirebaseToken
{
    public string Uid { get; set; } = string.Empty;
    public Dictionary<string, object> Claims { get; set; } = new();
}

