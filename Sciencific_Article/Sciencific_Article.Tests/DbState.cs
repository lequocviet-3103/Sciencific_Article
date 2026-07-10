using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;

namespace Sciencific_Article.Tests;

public class DbState
{
    private readonly ITestOutputHelper _output;

    public DbState(ITestOutputHelper output)
    {
        _output = output;
    }

    [Fact(DisplayName = "inspect-database-state")]
    public async Task Run()
    {
        var conn = "Host=aws-1-ap-southeast-1.pooler.supabase.com;Database=postgres;Username=postgres.kszsoovqqpaiphohdubf;Password=Journalprn232.";
        var state = await DbInspector.GetStateAsync(conn);
        _output.WriteLine(state);
        Assert.NotEmpty(state);
    }
}
