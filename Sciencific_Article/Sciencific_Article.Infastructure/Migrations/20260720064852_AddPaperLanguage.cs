using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sciencific_Article.Infastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPaperLanguage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "language",
                table: "papers",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "language",
                table: "papers");
        }
    }
}
