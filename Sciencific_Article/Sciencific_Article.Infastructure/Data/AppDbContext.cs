using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Sciencific_Article.Domain.Entities;
using System;
using System.Collections.Generic;

namespace Sciencific_Article.Infastructure.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Author> Authors { get; set; }

    public virtual DbSet<Bookmark> Bookmarks { get; set; }

    public virtual DbSet<FollowTopic> FollowTopics { get; set; }

    public virtual DbSet<Journal> Journals { get; set; }

    public virtual DbSet<Keyword> Keywords { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Paper> Papers { get; set; }

    public virtual DbSet<Report> Reports { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<SyncLog> SyncLogs { get; set; }

    public virtual DbSet<User> Users { get; set; }

    private string GetConnectionString()
    {
        IConfiguration configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", true, true).Build();
        return configuration["ConnectionStrings:DefaultConnection"];
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseNpgsql(GetConnectionString());
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .HasPostgresEnum("auth", "aal_level", new[] { "aal1", "aal2", "aal3" })
            .HasPostgresEnum("auth", "code_challenge_method", new[] { "s256", "plain" })
            .HasPostgresEnum("auth", "factor_status", new[] { "unverified", "verified" })
            .HasPostgresEnum("auth", "factor_type", new[] { "totp", "webauthn", "phone" })
            .HasPostgresEnum("auth", "oauth_authorization_status", new[] { "pending", "approved", "denied", "expired" })
            .HasPostgresEnum("auth", "oauth_client_type", new[] { "public", "confidential" })
            .HasPostgresEnum("auth", "oauth_registration_type", new[] { "dynamic", "manual" })
            .HasPostgresEnum("auth", "oauth_response_type", new[] { "code" })
            .HasPostgresEnum("auth", "one_time_token_type", new[] { "confirmation_token", "reauthentication_token", "recovery_token", "email_change_token_new", "email_change_token_current", "phone_change_token" })
            .HasPostgresEnum("realtime", "action", new[] { "INSERT", "UPDATE", "DELETE", "TRUNCATE", "ERROR" })
            .HasPostgresEnum("realtime", "equality_op", new[] { "eq", "neq", "lt", "lte", "gt", "gte", "in" })
            .HasPostgresEnum("storage", "buckettype", new[] { "STANDARD", "ANALYTICS", "VECTOR" })
            .HasPostgresExtension("extensions", "pg_stat_statements")
            .HasPostgresExtension("extensions", "pgcrypto")
            .HasPostgresExtension("extensions", "uuid-ossp")
            .HasPostgresExtension("vault", "supabase_vault");

        modelBuilder.Entity<Author>(entity =>
        {
            entity.HasKey(e => e.AuthorId).HasName("authors_pkey");

            entity.ToTable("authors");

            entity.Property(e => e.AuthorId)
                .HasMaxLength(40)
                .HasColumnName("author_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.ExternalAuthorId)
                .HasMaxLength(255)
                .HasColumnName("external_author_id");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
        });

        modelBuilder.Entity<Bookmark>(entity =>
        {
            entity.HasKey(e => e.BookmarkId).HasName("bookmarks_pkey");

            entity.ToTable("bookmarks");

            entity.Property(e => e.BookmarkId)
                .HasMaxLength(40)
                .HasColumnName("bookmark_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.PaperId)
                .HasMaxLength(40)
                .HasColumnName("paper_id");
            entity.Property(e => e.UserId)
                .HasMaxLength(40)
                .HasColumnName("user_id");

            entity.HasOne(d => d.Paper).WithMany(p => p.Bookmarks)
                .HasForeignKey(d => d.PaperId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("bookmarks_paper_id_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.Bookmarks)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("bookmarks_user_id_fkey");
        });

        modelBuilder.Entity<FollowTopic>(entity =>
        {
            entity.HasKey(e => e.FollowTopicId).HasName("follow_topics_pkey");

            entity.ToTable("follow_topics");

            entity.Property(e => e.FollowTopicId)
                .HasMaxLength(40)
                .HasColumnName("follow_topic_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.KeywordId)
                .HasMaxLength(40)
                .HasColumnName("keyword_id");
            entity.Property(e => e.UserId)
                .HasMaxLength(40)
                .HasColumnName("user_id");

            entity.HasOne(d => d.Keyword).WithMany(p => p.FollowTopics)
                .HasForeignKey(d => d.KeywordId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("follow_topics_keyword_id_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.FollowTopics)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("follow_topics_user_id_fkey");
        });

        modelBuilder.Entity<Journal>(entity =>
        {
            entity.HasKey(e => e.JournalId).HasName("journals_pkey");

            entity.ToTable("journals");

            entity.Property(e => e.JournalId)
                .HasMaxLength(40)
                .HasColumnName("journal_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.Issn)
                .HasMaxLength(100)
                .HasColumnName("issn");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.Publisher)
                .HasMaxLength(255)
                .HasColumnName("publisher");
        });

        modelBuilder.Entity<Keyword>(entity =>
        {
            entity.HasKey(e => e.KeywordId).HasName("keywords_pkey");

            entity.ToTable("keywords");

            entity.HasIndex(e => e.Name, "keywords_name_key").IsUnique();

            entity.Property(e => e.KeywordId)
                .HasMaxLength(40)
                .HasColumnName("keyword_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationId).HasName("notifications_pkey");

            entity.ToTable("notifications");

            entity.Property(e => e.NotificationId)
                .HasMaxLength(40)
                .HasColumnName("notification_id");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRead)
                .HasDefaultValue(false)
                .HasColumnName("is_read");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");
            entity.Property(e => e.UserId)
                .HasMaxLength(40)
                .HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("notifications_user_id_fkey");
        });

        modelBuilder.Entity<Paper>(entity =>
        {
            entity.HasKey(e => e.PaperId).HasName("papers_pkey");

            entity.ToTable("papers");

            entity.Property(e => e.PaperId)
                .HasMaxLength(40)
                .HasColumnName("paper_id");
            entity.Property(e => e.Abstract).HasColumnName("abstract");
            entity.Property(e => e.CitationCount)
                .HasDefaultValue(0)
                .HasColumnName("citation_count");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.Doi)
                .HasMaxLength(255)
                .HasColumnName("doi");
            entity.Property(e => e.ExternalId)
                .HasMaxLength(255)
                .HasColumnName("external_id");
            entity.Property(e => e.JournalId)
                .HasMaxLength(40)
                .HasColumnName("journal_id");
            entity.Property(e => e.PublicationYear).HasColumnName("publication_year");
            entity.Property(e => e.SourceApi)
                .HasMaxLength(100)
                .HasColumnName("source_api");
            entity.Property(e => e.Title).HasColumnName("title");

            entity.HasOne(d => d.Journal).WithMany(p => p.Papers)
                .HasForeignKey(d => d.JournalId)
                .HasConstraintName("fk_paper_journal");

            entity.HasMany(d => d.Authors).WithMany(p => p.Papers)
                .UsingEntity<Dictionary<string, object>>(
                    "PaperAuthor",
                    r => r.HasOne<Author>().WithMany()
                        .HasForeignKey("AuthorId")
                        .HasConstraintName("paper_authors_author_id_fkey"),
                    l => l.HasOne<Paper>().WithMany()
                        .HasForeignKey("PaperId")
                        .HasConstraintName("paper_authors_paper_id_fkey"),
                    j =>
                    {
                        j.HasKey("PaperId", "AuthorId").HasName("paper_authors_pkey");
                        j.ToTable("paper_authors");
                        j.IndexerProperty<string>("PaperId")
                            .HasMaxLength(40)
                            .HasColumnName("paper_id");
                        j.IndexerProperty<string>("AuthorId")
                            .HasMaxLength(40)
                            .HasColumnName("author_id");
                    });

            entity.HasMany(d => d.Keywords).WithMany(p => p.Papers)
                .UsingEntity<Dictionary<string, object>>(
                    "PaperKeyword",
                    r => r.HasOne<Keyword>().WithMany()
                        .HasForeignKey("KeywordId")
                        .HasConstraintName("paper_keywords_keyword_id_fkey"),
                    l => l.HasOne<Paper>().WithMany()
                        .HasForeignKey("PaperId")
                        .HasConstraintName("paper_keywords_paper_id_fkey"),
                    j =>
                    {
                        j.HasKey("PaperId", "KeywordId").HasName("paper_keywords_pkey");
                        j.ToTable("paper_keywords");
                        j.IndexerProperty<string>("PaperId")
                            .HasMaxLength(40)
                            .HasColumnName("paper_id");
                        j.IndexerProperty<string>("KeywordId")
                            .HasMaxLength(40)
                            .HasColumnName("keyword_id");
                    });
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(e => e.ReportId).HasName("reports_pkey");

            entity.ToTable("reports");

            entity.Property(e => e.ReportId)
                .HasMaxLength(40)
                .HasColumnName("report_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.FileUrl).HasColumnName("file_url");
            entity.Property(e => e.ReportType)
                .HasMaxLength(100)
                .HasColumnName("report_type");
            entity.Property(e => e.UserId)
                .HasMaxLength(40)
                .HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Reports)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("reports_user_id_fkey");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.RoleId).HasName("roles_pkey");

            entity.ToTable("roles");

            entity.Property(e => e.RoleId)
                .HasMaxLength(40)
                .HasColumnName("role_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.RoleName)
                .HasMaxLength(50)
                .HasColumnName("role_name");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<SyncLog>(entity =>
        {
            entity.HasKey(e => e.SyncLogId).HasName("sync_logs_pkey");

            entity.ToTable("sync_logs");

            entity.Property(e => e.SyncLogId)
                .HasMaxLength(40)
                .HasColumnName("sync_log_id");
            entity.Property(e => e.ErrorMessage).HasColumnName("error_message");
            entity.Property(e => e.RecordsInserted)
                .HasDefaultValue(0)
                .HasColumnName("records_inserted");
            entity.Property(e => e.SourceApi)
                .HasMaxLength(100)
                .HasColumnName("source_api");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.SyncTime)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("sync_time");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("users_pkey");

            entity.ToTable("users");

            entity.HasIndex(e => e.Email, "users_email_key").IsUnique();

            entity.Property(e => e.UserId)
                .HasMaxLength(40)
                .HasColumnName("user_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(150)
                .HasColumnName("email");
            entity.Property(e => e.FullName)
                .HasMaxLength(100)
                .HasColumnName("full_name");
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash");
            entity.Property(e => e.RoleId)
                .HasMaxLength(40)
                .HasColumnName("role_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Role).WithMany(p => p.Users)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("fk_users_role");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
