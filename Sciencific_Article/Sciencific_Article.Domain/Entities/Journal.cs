using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Journal
{
    public string JournalId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? Publisher { get; set; }

    public string? Issn { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Paper> Papers { get; set; } = new List<Paper>();
}
