using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class PublicationTrend
{
    public string TrendId { get; set; } = null!;

    public string? TopicId { get; set; }

    public int? Year { get; set; }

    public int? PublicationCount { get; set; }

    public double? CitationAverage { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ResearchTopic? Topic { get; set; }
}
