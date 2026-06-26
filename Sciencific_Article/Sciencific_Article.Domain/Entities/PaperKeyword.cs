using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Sciencific_Article.Domain.Entities
{
    public class PaperKeyword
    {
            public string PaperId { get; set; } = null!;
            public string KeywordId { get; set; } = null!;

            public virtual Paper Paper { get; set; } = null!;
            public virtual Keyword Keyword { get; set; } = null!;
        
    }
}
