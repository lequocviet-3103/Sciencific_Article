using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sciencific_Article.Infastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "authors",
                columns: table => new
                {
                    author_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    external_author_id = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("authors_pkey", x => x.author_id);
                });

            migrationBuilder.CreateTable(
                name: "journals",
                columns: table => new
                {
                    journal_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    publisher = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    issn = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("journals_pkey", x => x.journal_id);
                });

            migrationBuilder.CreateTable(
                name: "keywords",
                columns: table => new
                {
                    keyword_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("keywords_pkey", x => x.keyword_id);
                });

            migrationBuilder.CreateTable(
                name: "roles",
                columns: table => new
                {
                    role_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    role_name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    description = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("roles_pkey", x => x.role_id);
                });

            migrationBuilder.CreateTable(
                name: "sync_logs",
                columns: table => new
                {
                    sync_log_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    source_api = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    records_inserted = table.Column<int>(type: "integer", nullable: true, defaultValue: 0),
                    error_message = table.Column<string>(type: "text", nullable: true),
                    sync_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("sync_logs_pkey", x => x.sync_log_id);
                });

            migrationBuilder.CreateTable(
                name: "papers",
                columns: table => new
                {
                    paper_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    title = table.Column<string>(type: "text", nullable: false),
                    @abstract = table.Column<string>(name: "abstract", type: "text", nullable: true),
                    doi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    publication_year = table.Column<int>(type: "integer", nullable: true),
                    citation_count = table.Column<int>(type: "integer", nullable: true, defaultValue: 0),
                    journal_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    external_id = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    source_api = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("papers_pkey", x => x.paper_id);
                    table.ForeignKey(
                        name: "fk_paper_journal",
                        column: x => x.journal_id,
                        principalTable: "journals",
                        principalColumn: "journal_id");
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    user_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    full_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    email = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    password_hash = table.Column<string>(type: "text", nullable: true),
                    role_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    firebase_uid = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    avatar_url = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("users_pkey", x => x.user_id);
                    table.ForeignKey(
                        name: "fk_users_role",
                        column: x => x.role_id,
                        principalTable: "roles",
                        principalColumn: "role_id");
                });

            migrationBuilder.CreateTable(
                name: "paper_authors",
                columns: table => new
                {
                    paper_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    author_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("paper_authors_pkey", x => new { x.paper_id, x.author_id });
                    table.ForeignKey(
                        name: "paper_authors_author_id_fkey",
                        column: x => x.author_id,
                        principalTable: "authors",
                        principalColumn: "author_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "paper_authors_paper_id_fkey",
                        column: x => x.paper_id,
                        principalTable: "papers",
                        principalColumn: "paper_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "paper_keywords",
                columns: table => new
                {
                    paper_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    keyword_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("paper_keywords_pkey", x => new { x.paper_id, x.keyword_id });
                    table.ForeignKey(
                        name: "paper_keywords_keyword_id_fkey",
                        column: x => x.keyword_id,
                        principalTable: "keywords",
                        principalColumn: "keyword_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "paper_keywords_paper_id_fkey",
                        column: x => x.paper_id,
                        principalTable: "papers",
                        principalColumn: "paper_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "research_topics",
                columns: table => new
                {
                    topic_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    field = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    subfield = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    domain = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    works_count = table.Column<int>(type: "integer", nullable: true),
                    open_alex_id = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    PaperId = table.Column<string>(type: "character varying(40)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("research_topics_pkey", x => x.topic_id);
                    table.ForeignKey(
                        name: "FK_research_topics_papers_PaperId",
                        column: x => x.PaperId,
                        principalTable: "papers",
                        principalColumn: "paper_id");
                });

            migrationBuilder.CreateTable(
                name: "bookmarks",
                columns: table => new
                {
                    bookmark_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    user_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    paper_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("bookmarks_pkey", x => x.bookmark_id);
                    table.ForeignKey(
                        name: "bookmarks_paper_id_fkey",
                        column: x => x.paper_id,
                        principalTable: "papers",
                        principalColumn: "paper_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "bookmarks_user_id_fkey",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                columns: table => new
                {
                    notification_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    user_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    title = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    content = table.Column<string>(type: "text", nullable: true),
                    is_read = table.Column<bool>(type: "boolean", nullable: true, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("notifications_pkey", x => x.notification_id);
                    table.ForeignKey(
                        name: "notifications_user_id_fkey",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "follow_topics",
                columns: table => new
                {
                    follow_topic_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    user_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    keyword_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    topic_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("follow_topics_pkey", x => x.follow_topic_id);
                    table.ForeignKey(
                        name: "fk_follow_topic_topic",
                        column: x => x.topic_id,
                        principalTable: "research_topics",
                        principalColumn: "topic_id");
                    table.ForeignKey(
                        name: "follow_topics_keyword_id_fkey",
                        column: x => x.keyword_id,
                        principalTable: "keywords",
                        principalColumn: "keyword_id");
                    table.ForeignKey(
                        name: "follow_topics_user_id_fkey",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "publication_trends",
                columns: table => new
                {
                    trend_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    topic_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    year = table.Column<int>(type: "integer", nullable: true),
                    publication_count = table.Column<int>(type: "integer", nullable: true),
                    average_citation = table.Column<double>(type: "double precision", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("publication_trends_pkey", x => x.trend_id);
                    table.ForeignKey(
                        name: "fk_trend_topic",
                        column: x => x.topic_id,
                        principalTable: "research_topics",
                        principalColumn: "topic_id");
                });

            migrationBuilder.CreateTable(
                name: "reports",
                columns: table => new
                {
                    report_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    user_id = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    report_type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    file_url = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP"),
                    topic_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("reports_pkey", x => x.report_id);
                    table.ForeignKey(
                        name: "fk_report_topic",
                        column: x => x.topic_id,
                        principalTable: "research_topics",
                        principalColumn: "topic_id");
                    table.ForeignKey(
                        name: "reports_user_id_fkey",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_bookmarks_paper_id",
                table: "bookmarks",
                column: "paper_id");

            migrationBuilder.CreateIndex(
                name: "IX_bookmarks_user_id",
                table: "bookmarks",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_follow_topics_keyword_id",
                table: "follow_topics",
                column: "keyword_id");

            migrationBuilder.CreateIndex(
                name: "IX_follow_topics_topic_id",
                table: "follow_topics",
                column: "topic_id");

            migrationBuilder.CreateIndex(
                name: "IX_follow_topics_user_id",
                table: "follow_topics",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "keywords_name_key",
                table: "keywords",
                column: "name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_notifications_user_id",
                table: "notifications",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_paper_authors_author_id",
                table: "paper_authors",
                column: "author_id");

            migrationBuilder.CreateIndex(
                name: "IX_paper_keywords_keyword_id",
                table: "paper_keywords",
                column: "keyword_id");

            migrationBuilder.CreateIndex(
                name: "IX_papers_journal_id",
                table: "papers",
                column: "journal_id");

            migrationBuilder.CreateIndex(
                name: "IX_publication_trends_topic_id",
                table: "publication_trends",
                column: "topic_id");

            migrationBuilder.CreateIndex(
                name: "IX_reports_topic_id",
                table: "reports",
                column: "topic_id");

            migrationBuilder.CreateIndex(
                name: "IX_reports_user_id",
                table: "reports",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_research_topics_PaperId",
                table: "research_topics",
                column: "PaperId");

            migrationBuilder.CreateIndex(
                name: "research_topics_open_alex_id_key",
                table: "research_topics",
                column: "open_alex_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_role_id",
                table: "users",
                column: "role_id");

            migrationBuilder.CreateIndex(
                name: "users_email_key",
                table: "users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "users_firebase_uid_key",
                table: "users",
                column: "firebase_uid",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "bookmarks");

            migrationBuilder.DropTable(
                name: "follow_topics");

            migrationBuilder.DropTable(
                name: "notifications");

            migrationBuilder.DropTable(
                name: "paper_authors");

            migrationBuilder.DropTable(
                name: "paper_keywords");

            migrationBuilder.DropTable(
                name: "publication_trends");

            migrationBuilder.DropTable(
                name: "reports");

            migrationBuilder.DropTable(
                name: "sync_logs");

            migrationBuilder.DropTable(
                name: "authors");

            migrationBuilder.DropTable(
                name: "keywords");

            migrationBuilder.DropTable(
                name: "research_topics");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "papers");

            migrationBuilder.DropTable(
                name: "roles");

            migrationBuilder.DropTable(
                name: "journals");
        }
    }
}
