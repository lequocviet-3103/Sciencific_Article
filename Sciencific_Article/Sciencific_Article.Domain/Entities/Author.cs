using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Author
{
    public string AuthorId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? ExternalAuthorId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Paper> Papers { get; set; } = new List<Paper>();
}
