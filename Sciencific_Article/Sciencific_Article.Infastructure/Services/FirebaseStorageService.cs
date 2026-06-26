using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Infastructure.Services;

public class FirebaseStorageService : IFirebaseStorageService
{
    public Task<string> UploadAsync(string bucket, string objectPath, Stream content, string contentType, CancellationToken cancellationToken = default)
    {
        var url = $"https://storage.example.com/{bucket}/{objectPath}";
        return Task.FromResult(url);
    }

    public Task<string> GetSignedUrlAsync(string bucket, string objectPath, TimeSpan? lifetime = null, CancellationToken cancellationToken = default)
    {
        var url = $"https://storage.example.com/{bucket}/{objectPath}?expires=3600";
        return Task.FromResult(url);
    }
}
