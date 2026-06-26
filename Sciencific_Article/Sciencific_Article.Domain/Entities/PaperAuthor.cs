using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Sciencific_Article.Domain.Entities
{
    public class PaperAuthor
    {
        public string PaperId { get; set; } = null!;
        public string AuthorId { get; set; } = null!;

        public virtual Paper Paper { get; set; } = null!;
        public virtual Author Author { get; set; } = null!;
    }
}
