using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class SyncLog
{
    public string SyncLogId { get; set; } = null!;

    public string? SourceApi { get; set; }

    public string? Status { get; set; }

    public int? RecordsInserted { get; set; }

    public string? ErrorMessage { get; set; }

    public DateTime? SyncTime { get; set; }
}
