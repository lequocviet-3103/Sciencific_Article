namespace Sciencific_Article.Application.Interfaces.Services;

public interface IFirebaseStorageService
{
    Task<string> UploadAsync(string bucket, string objectPath, Stream content, string contentType, CancellationToken cancellationToken = default);
    Task<string> GetSignedUrlAsync(string bucket, string objectPath, TimeSpan? lifetime = null, CancellationToken cancellationToken = default);
}
