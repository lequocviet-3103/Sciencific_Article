using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Bookmark
{
    public string BookmarkId { get; set; } = null!;

    public string? UserId { get; set; }

    public string? PaperId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Paper? Paper { get; set; }

    public virtual User? User { get; set; }
}
