using System;
using System.Threading.Tasks;
using Npgsql;

namespace Sciencific_Article.Tests;

public static class DbInspector
{
    public static async Task<string> GetStateAsync(string conn)
    {
        await using var conn2 = new NpgsqlConnection(conn);
        await conn2.OpenAsync();

        var sb = new System.Text.StringBuilder();
        await using (var cmd = new NpgsqlCommand(
            @"SELECT
                (SELECT COUNT(*) FROM papers)              AS papers,
                (SELECT COUNT(*) FROM research_topics)     AS topics,
                (SELECT COUNT(*) FROM authors)             AS authors,
                (SELECT COUNT(*) FROM keywords)            AS keywords,
                (SELECT COUNT(*) FROM journals)            AS journals,
                (SELECT COUNT(*) FROM paper_topics)        AS paper_topics,
                (SELECT COUNT(*) FROM paper_authors)       AS paper_authors,
                (SELECT COUNT(*) FROM paper_keywords)      AS paper_keywords,
                (SELECT COUNT(*) FROM users)               AS users,
                (SELECT COUNT(*) FROM reports)             AS reports,
                (SELECT COUNT(*) FROM follow_topics)       AS follow_topics,
                (SELECT COUNT(*) FROM publication_trends)  AS pub_trends,
                (SELECT COUNT(*) FROM bookmarks)           AS bookmarks,
                (SELECT COUNT(*) FROM sync_logs)           AS sync_logs;", conn2))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                for (int i = 0; i < reader.FieldCount; i++)
                    sb.AppendLine($"{reader.GetName(i),-20} = {reader.GetValue(i)}");
            }
        }

        // Sample duplicate check on research_topics
        sb.AppendLine();
        sb.AppendLine("--- Duplicate topic_id check ---");
        await using (var cmd = new NpgsqlCommand(
            @"SELECT topic_id, COUNT(*) AS c
              FROM research_topics
              GROUP BY topic_id
              HAVING COUNT(*) > 1
              LIMIT 5;", conn2))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            int n = 0;
            while (await reader.ReadAsync())
            {
                sb.AppendLine($"DUP topic_id={reader.GetString(0)} count={reader.GetInt32(1)}");
                n++;
            }
            if (n == 0) sb.AppendLine("(none)");
        }

        sb.AppendLine("--- Duplicate topic name check ---");
        await using (var cmd = new NpgsqlCommand(
            @"SELECT name, COUNT(*) AS c
              FROM research_topics
              GROUP BY name
              HAVING COUNT(*) > 1
              LIMIT 5;", conn2))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            int n = 0;
            while (await reader.ReadAsync())
            {
                sb.AppendLine($"DUP name='{reader.GetString(0)}' count={reader.GetInt32(1)}");
                n++;
            }
            if (n == 0) sb.AppendLine("(none)");
        }

        return sb.ToString();
    }
}
