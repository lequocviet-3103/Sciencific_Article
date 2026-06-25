using System;
using System.Collections.Generic;

namespace Sciencific_Article.Domain.Entities;

public partial class Notification
{
    public string NotificationId { get; set; } = null!;

    public string? UserId { get; set; }

    public string? Title { get; set; }

    public string? Content { get; set; }

    public bool? IsRead { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual User? User { get; set; }
}
