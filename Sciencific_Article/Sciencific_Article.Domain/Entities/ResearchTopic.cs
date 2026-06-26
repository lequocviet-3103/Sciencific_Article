using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class ResearchTopic
{
    public string TopicId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? Field { get; set; }

    public string? Domain { get; set; }

    public string? Subfield { get; set; }

    public string? OpenAlexId { get; set; }

    public int? WorksCount { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<FollowTopic> FollowTopics { get; set; } = new List<FollowTopic>();

    public virtual ICollection<PublicationTrend> PublicationTrends { get; set; } = new List<PublicationTrend>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<Paper> Papers { get; set; } = new List<Paper>();
}
