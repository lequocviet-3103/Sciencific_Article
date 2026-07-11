using System.Text.Json;
using Npgsql;

// ----------------------------------------------------------------------------
// Loads appsettings.json from the Sciencific_Article.Web project, opens a
// PostgreSQL connection, then either runs the diagnostic queries (default)
// or the dedupe migration (which uses raw SQL DO $$ blocks; each block is
// its own atomic subtransaction in Postgres).
//
// Usage:
//   dotnet run --project Sciencific_Article.DedupeTool -- diagnostic
//   dotnet run --project Sciencific_Article.DedupeTool -- apply
//   dotnet run --project Sciencific_Article.DedupeTool -- indexes
// ----------------------------------------------------------------------------

var mode = args.Length > 0 ? args[0].ToLowerInvariant() : "diagnostic";
var modeIsApply = mode == "apply";
var modeIsIndexes = mode == "indexes";

var repoRoot = FindRepoRoot();
var appSettingsPath = Path.Combine(repoRoot,
    "Sciencific_Article", "Sciencific_Article", "appsettings.json");

if (!File.Exists(appSettingsPath))
{
    Console.Error.WriteLine($"appsettings.json not found at {appSettingsPath}");
    return 1;
}

string connectionString;
try
{
    var json = JsonDocument.Parse(File.ReadAllText(appSettingsPath));
    var cs = json.RootElement
        .GetProperty("ConnectionStrings")
        .GetProperty("DefaultConnection")
        .GetString();
    if (string.IsNullOrWhiteSpace(cs))
    {
        Console.Error.WriteLine("ConnectionStrings.DefaultConnection is empty.");
        return 1;
    }
    connectionString = cs!;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Failed to parse appsettings.json: {ex.Message}");
    return 1;
}

Console.WriteLine($"Mode: {mode}");
Console.WriteLine($"Connection target: {MaskConnectionString(connectionString)}");

await using var conn = new NpgsqlConnection(connectionString);
try
{
    await conn.OpenAsync();
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Could not connect: {ex.Message}");
    return 2;
}

Console.WriteLine($"Connected to PostgreSQL {conn.PostgreSqlVersion} on {conn.Host}:{conn.Port}");

if (modeIsIndexes)
{
    // Read-only inspection: list every index on the four tables of interest.
    // Useful to confirm whether ux_journals_name_lower /
    // ux_authors_external_author_id were actually created by `apply`.
    const string indexSql = @"
SELECT tablename, indexname, indexdef
  FROM pg_indexes
 WHERE tablename IN ('journals', 'authors', 'research_topics', 'keywords')
 ORDER BY tablename, indexname;";

    await using var cmd = new NpgsqlCommand(indexSql, conn);
    await using var r = await cmd.ExecuteReaderAsync();
    int n = 0;
    string? lastTable = null;
    while (await r.ReadAsync())
    {
        var table = r.GetString(0);
        if (table != lastTable)
        {
            Console.WriteLine();
            Console.WriteLine($"--- {table} ---");
            lastTable = table;
        }
        Console.WriteLine($"  {r.GetString(1),-40} {r.GetString(2)}");
        n++;
    }
    Console.WriteLine();
    Console.WriteLine($"Indexes listed: {n}");
    return 0;
}

// We don't open an explicit transaction: Npgsql 9 + the Supabase pooler
// can trip "transaction has completed" when a single command contains
// multiple DO $$ blocks. Each block is its own atomic subtransaction in
// Postgres, so atomicity between blocks isn't strictly needed for this
// migration (each block only operates on a single dedupe group).

try
{
    if (modeIsApply)
    {
        var sqlPath = Path.Combine(repoRoot, "dedupe_openalex_entities.sql");
        var sql = File.ReadAllText(sqlPath);
        await using var cmd = new NpgsqlCommand(sql, conn) { CommandTimeout = 600 };
        var affected = await cmd.ExecuteNonQueryAsync();
        Console.WriteLine();
        Console.WriteLine($"Dedupe migration done. Rows affected (cumulative): {affected}");
        Console.WriteLine("Re-run with `diagnostic` to verify there are no duplicates left.");
    }
    else
    {
        var diagnosticSql = @"
SELECT 'journals' AS table_name, name AS key, COUNT(*) AS dup_count,
       array_agg(journal_id ORDER BY journal_id) AS ids
  FROM journals
 GROUP BY name
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC, name
 LIMIT 50;

SELECT 'authors (by ext_id)' AS table_name, external_author_id AS key, COUNT(*) AS dup_count,
       array_agg(author_id ORDER BY author_id) AS ids
  FROM authors
 WHERE external_author_id IS NOT NULL
 GROUP BY external_author_id
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC
 LIMIT 50;

SELECT 'research_topics' AS table_name, name AS key, COUNT(*) AS dup_count,
       array_agg(topic_id ORDER BY topic_id) AS ids
  FROM research_topics
 GROUP BY name
HAVING COUNT(*) > 1
 ORDER BY dup_count DESC, name
 LIMIT 50;

SELECT tablename, indexname, indexdef
  FROM pg_indexes
 WHERE tablename IN ('journals', 'authors', 'research_topics', 'keywords')
   AND indexdef LIKE '%UNIQUE%'
 ORDER BY tablename, indexname;
";

        int totalRows = 0;
        await using (var cmd = new NpgsqlCommand(diagnosticSql, conn))
        await using (var r = await cmd.ExecuteReaderAsync())
        {
            string currentHeader = "";
            while (await r.ReadAsync())
            {
                if (r.FieldCount == 4 && r.GetName(0) == "table_name")
                {
                    var tableName = r.GetString(0);
                    if (tableName != currentHeader)
                    {
                        Console.WriteLine();
                        Console.WriteLine($"--- {tableName} ---");
                        currentHeader = tableName;
                    }
                    Console.WriteLine($"  dup={r.GetInt32(2),3}  name={Truncate(r.GetString(1), 80)}");
                    totalRows++;
                }
                else if (r.FieldCount == 3)
                {
                    Console.WriteLine($"  {r.GetString(0),-30}  index={r.GetString(1)}");
                    Console.WriteLine($"      def={r.GetString(2)}");
                    totalRows++;
                }
            }
        }
        Console.WriteLine();
        Console.WriteLine($"Diagnostic returned {totalRows} row(s).");
    }
}
catch (Exception ex)
{
    Console.Error.WriteLine($"FAILED: {ex.Message}");
    return 3;
}

return 0;

static string FindRepoRoot()
{
    var dir = AppContext.BaseDirectory;
    while (!string.IsNullOrEmpty(dir))
    {
        if (Directory.Exists(Path.Combine(dir, "dedupe_openalex_entities.sql")))
            return dir;
        var parent = Directory.GetParent(dir);
        if (parent is null) break;
        dir = parent.FullName;
    }
    return Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));
}

static string MaskConnectionString(string cs)
{
    return System.Text.RegularExpressions.Regex.Replace(cs,
        @"(?i)(Password\s*=\s*)([^;]*)", "$1***");
}

static string Truncate(string s, int n) => s.Length <= n ? s : s.Substring(0, n) + "...";
