using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;

namespace Sciencific_Article.Tests;

public class TruncateDb
{
    private readonly ITestOutputHelper _output;

    public TruncateDb(ITestOutputHelper output)
    {
        _output = output;
    }

    [Fact(DisplayName = "truncate-everything")]
    public async Task Run()
    {
        var conn = "Host=aws-1-ap-southeast-1.pooler.supabase.com;Database=postgres;Username=postgres.kszsoovqqpaiphohdubf;Password=Journalprn232.";
        var (n, detail) = await TruncateHelper.TruncateAllAsync(conn);
        _output.WriteLine(detail);
        Assert.True(n > 0, detail);
    }
}
