using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Domain.Dtos.Auth;
using FirebaseToken = Sciencific_Article.Domain.Dtos.Auth.FirebaseToken;

namespace Sciencific_Article.Infastructure.Services;

public class FirebaseAuthService : IFirebaseAuthService
{
    async Task<Domain.Dtos.Auth.FirebaseToken> IFirebaseAuthService.VerifyIdTokenAsync(string idToken, CancellationToken cancellationToken)
    {
        var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(idToken);

        var token = new FirebaseToken
        {
            Uid = decodedToken.Uid,
            Claims = decodedToken.Claims.ToDictionary(k => k.Key, v => (object)v.Value.ToString())
        };
        return token;
        
    }
}