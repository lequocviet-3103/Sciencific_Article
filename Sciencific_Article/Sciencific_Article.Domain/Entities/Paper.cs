using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Paper
{
    public string PaperId { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string? Abstract { get; set; }

    public string? Doi { get; set; }

    public int? PublicationYear { get; set; }

    public int? CitationCount { get; set; }

    public string? JournalId { get; set; }

    public string? ExternalId { get; set; }

    public string? SourceApi { get; set; }

    public string? DocType { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Bookmark> Bookmarks { get; set; } = new List<Bookmark>();

    public virtual Journal? Journal { get; set; }

    public virtual ICollection<Author> Authors { get; set; } = new List<Author>();

    public virtual ICollection<Keyword> Keywords { get; set; } = new List<Keyword>();

    public virtual ICollection<ResearchTopic> Topics { get; set; } = new List<ResearchTopic>();
}
