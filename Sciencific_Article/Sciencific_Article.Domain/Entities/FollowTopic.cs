using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class FollowTopic
{
    public string FollowTopicId { get; set; } = null!;

    public string? UserId { get; set; }

    public string? KeywordId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Keyword? Keyword { get; set; }

    public virtual User? User { get; set; }
}
