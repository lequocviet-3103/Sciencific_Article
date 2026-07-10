using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Sciencific_Article.Infastructure.Data;

namespace Sciencific_Article.Tests;

public static class TruncateHelper
{
    public static async Task<(int TablesCount, string Detail)> TruncateAllAsync(string connectionString)
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();

        var tables = new System.Collections.Generic.List<string>();
        await using (var cmd = new NpgsqlCommand(
            "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;", conn))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
                tables.Add(reader.GetString(0));
        }

        if (tables.Count == 0)
            return (0, "(no tables in public schema)");

        var detail = "Tables: " + string.Join(", ", tables) + "\n";

        foreach (var t in tables)
        {
            var sql = $"TRUNCATE TABLE \"{t}\" RESTART IDENTITY CASCADE;";
            await using var cmd = new NpgsqlCommand(sql, conn);
            await cmd.ExecuteNonQueryAsync();
            detail += $"OK {t}\n";
        }

        return (tables.Count, detail);
    }
}
