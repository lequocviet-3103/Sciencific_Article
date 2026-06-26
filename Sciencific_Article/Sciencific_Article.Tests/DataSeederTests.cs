using Microsoft.EntityFrameworkCore;
using Sciencific_Article.Infastructure.Data;
using Sciencific_Article.Services;
using Xunit;

namespace Sciencific_Article.Tests;

public class DataSeederTests
{
    [Fact]
    public void SeedIfEmpty_EmptyDatabase_AddsData()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        using var context = new AppDbContext(options);

        var seeder = new DataSeeder(context);
        seeder.SeedIfEmpty();

        Assert.True(context.Papers.Any());
        Assert.True(context.Journals.Any());
        Assert.True(context.Authors.Any());
        Assert.True(context.Keywords.Any());
        Assert.True(context.ResearchTopics.Any());
        Assert.True(context.Roles.Any());
        Assert.Equal(50, context.Papers.Count());
    }

    [Fact]
    public void SeedIfEmpty_AlreadySeeded_DoesNotDuplicate()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        using var context = new AppDbContext(options);

        var seeder = new DataSeeder(context);
        seeder.SeedIfEmpty();
        var firstCount = context.Papers.Count();

        seeder.SeedIfEmpty();
        var secondCount = context.Papers.Count();

        Assert.Equal(50, firstCount);
        Assert.Equal(50, secondCount);
    }
}
