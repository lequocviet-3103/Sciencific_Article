using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Report
{
    public string ReportId { get; set; } = null!;

    public string? UserId { get; set; }

    public string? ReportType { get; set; }

    public string? FileUrl { get; set; }

    public DateTime? CreatedAt { get; set; }

    public string? TopicId { get; set; }

    public virtual ResearchTopic? Topic { get; set; }

    public virtual User? User { get; set; }
}
