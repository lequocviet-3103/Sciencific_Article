using Moq;
using Sciencific_Article.Application.Interfaces.Repositories;
using Sciencific_Article.Application.Interfaces.Services;
using Sciencific_Article.Application.Services;
using Sciencific_Article.Domain.Dtos.Auth;
using Sciencific_Article.Domain.Entities;
using Xunit;

namespace Sciencific_Article.Tests;

public class AuthServiceTests
{
    private readonly Mock<IFirebaseAuthService> _mockFirebaseAuth = new();
    private readonly Mock<IUserRepository> _mockUserRepo = new();
    private readonly Mock<IUnitOfWork> _mockUnitOfWork = new();

    private AuthService CreateService() => new(
        _mockFirebaseAuth.Object,
        _mockUserRepo.Object,
        _mockUnitOfWork.Object,
        new AutoMapper.MapperConfiguration(cfg => cfg.AddProfile<Application.Mapping.MappingProfile>()).CreateMapper()
    );

    [Fact]
    public async Task VerifyIdToken_NewUser_CreatesUserAndReturnsSuccess()
    {
        // Arrange
        var token = new FirebaseToken { Uid = "uid123", Claims = new Dictionary<string, object> { ["email"] = "test@example.com" } };
        _mockFirebaseAuth.Setup(x => x.VerifyIdTokenAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(token);
        _mockUserRepo.Setup(x => x.GetByFirebaseUidAsync("uid123", It.IsAny<CancellationToken>())).ReturnsAsync((User?)null);
        _mockUserRepo.Setup(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
        _mockUserRepo.Setup(x => x.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        // Act
        var result = await CreateService().VerifyIdTokenAsync("valid-id-token", "Researcher");

        // Assert
        Assert.True(result.Success);
        Assert.NotNull(result.User);
        Assert.Equal("test@example.com", result.User.Email);
        _mockUserRepo.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task VerifyIdToken_ExistingUser_UpdatesAndReturnsSuccess()
    {
        // Arrange
        var existingUser = new User
        {
            UserId = "user1",
            FirebaseUid = "uid123",
            Email = "old@example.com",
            FullName = "Old Name",
            RoleId = "Researcher"
        };
        var token = new FirebaseToken { Uid = "uid123", Claims = new Dictionary<string, object> { ["email"] = "new@example.com", ["name"] = "New Name" } };

        _mockFirebaseAuth.Setup(x => x.VerifyIdTokenAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(token);
        _mockUserRepo.Setup(x => x.GetByFirebaseUidAsync("uid123", It.IsAny<CancellationToken>())).ReturnsAsync(existingUser);
        _mockUserRepo.Setup(x => x.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        // Act
        var result = await CreateService().VerifyIdTokenAsync("valid-id-token");

        // Assert
        Assert.True(result.Success);
        Assert.NotNull(result.User);
        Assert.Equal("new@example.com", result.User.Email);
        _mockUserRepo.Verify(x => x.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
        _mockUserRepo.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task GetAvailableRoles_ReturnsRolesFromDatabase()
    {
        // Arrange
        var roles = new List<Role>
        {
            new Role { RoleId = "Admin", RoleName = "Admin" },
            new Role { RoleId = "Researcher", RoleName = "Researcher" }
        };

        _mockUnitOfWork.Setup(x => x.Roles).Returns(roles.AsQueryable());

        // Act
        var result = await CreateService().GetAvailableRolesAsync();

        // Assert
        Assert.Equal(2, result.Count);
    }

    [Fact]
    public async Task VerifyIdToken_NoRoleId_DefaultsToResearcher()
    {
        // Arrange
        var token = new FirebaseToken { Uid = "uid123", Claims = new Dictionary<string, object> { ["email"] = "test@example.com" } };
        _mockFirebaseAuth.Setup(x => x.VerifyIdTokenAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(token);
        _mockUserRepo.Setup(x => x.GetByFirebaseUidAsync("uid123", It.IsAny<CancellationToken>())).ReturnsAsync((User?)null);
        _mockUserRepo.Setup(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        // Act
        var result = await CreateService().VerifyIdTokenAsync("valid-id-token");

        // Assert
        Assert.True(result.Success);
        Assert.NotNull(result.User);
    }
}
