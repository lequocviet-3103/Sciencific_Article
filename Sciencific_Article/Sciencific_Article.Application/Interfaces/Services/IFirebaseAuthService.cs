using Sciencific_Article.Domain.Dtos.Auth;

namespace Sciencific_Article.Application.Interfaces.Services;

public interface IFirebaseAuthService
{
    Task<FirebaseToken> VerifyIdTokenAsync(string idToken, CancellationToken cancellationToken = default);
}
