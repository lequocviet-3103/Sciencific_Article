using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Keyword
{
    public string KeywordId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<FollowTopic> FollowTopics { get; set; } = new List<FollowTopic>();

    public virtual ICollection<Paper> Papers { get; set; } = new List<Paper>();
}
