using Google.Apis.Auth.OAuth2;
using Google.Cloud.Storage.V1;
using Sciencific_Article.Application.Interfaces.Services;

namespace Sciencific_Article.Infastructure.Services;

/// Name of the default Firebase Storage bucket to upload to when the
/// caller doesn't specify one (Firebase Storage buckets are just GCS
/// buckets named "{project-id}.appspot.com").
public record FirebaseStorageOptions(string DefaultBucket);

public class FirebaseStorageService : IFirebaseStorageService
{
    private readonly GoogleCredential _credential;
    private readonly FirebaseStorageOptions _options;
    private readonly StorageClient _storageClient;

    public FirebaseStorageService(GoogleCredential credential, FirebaseStorageOptions options)
    {
        _credential = credential;
        _options = options;
        _storageClient = StorageClient.Create(credential);
    }

    public async Task<string> UploadAsync(string bucket, string objectPath, Stream content, string contentType, CancellationToken cancellationToken = default)
    {
        var bucketName = string.IsNullOrWhiteSpace(bucket) ? _options.DefaultBucket : bucket;
        await _storageClient.UploadObjectAsync(
            bucketName,
            objectPath,
            contentType,
            content,
            cancellationToken: cancellationToken);

        // Signed URLs work regardless of the bucket's public-access/ACL
        // settings, since they're authorized via the service account's
        // own signing key rather than object permissions.
        return await GetSignedUrlAsync(bucketName, objectPath, TimeSpan.FromDays(7), cancellationToken);
    }

    public Task<string> GetSignedUrlAsync(string bucket, string objectPath, TimeSpan? lifetime = null, CancellationToken cancellationToken = default)
    {
        var bucketName = string.IsNullOrWhiteSpace(bucket) ? _options.DefaultBucket : bucket;
        var signer = UrlSigner.FromCredential(_credential);
        return signer.SignAsync(
            bucketName,
            objectPath,
            lifetime ?? TimeSpan.FromDays(7),
            HttpMethod.Get);
    }
}
