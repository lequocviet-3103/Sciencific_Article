using AutoMapper;
using Sciencific_Article.Domain.Entities;
using Sciencific_Article.Domain.Dtos;
using Sciencific_Article.Domain.Dtos.Auth;

namespace Sciencific_Article.Application.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserDto>()
            .ForMember(d => d.RoleName, opt => opt.Ignore());

        CreateMap<Paper, PaperDto>()
            .ForMember(d => d.Authors, opt => opt.Ignore())
            .ForMember(d => d.Journal, opt => opt.Ignore())
            .ForMember(d => d.Topics, opt => opt.Ignore())
            .ForMember(d => d.Keywords, opt => opt.Ignore());

        CreateMap<Journal, JournalDto>()
            .ForMember(d => d.PaperCount, opt => opt.Ignore());

        CreateMap<Author, AuthorDto>()
            .ForMember(d => d.PaperCount, opt => opt.Ignore());

        CreateMap<Keyword, KeywordDto>()
            .ForMember(d => d.Followers, opt => opt.Ignore());

        CreateMap<ResearchTopic, TopicDto>()
            .ForMember(d => d.OpenAlexId, opt => opt.MapFrom(s => s.OpenAlexId));

        CreateMap<PublicationTrend, PublicationTrendDto>()
            .ForMember(d => d.TopicName, opt => opt.Ignore());

        CreateMap<Notification, NotificationDto>();
        CreateMap<Report, ReportDto>();
        CreateMap<Bookmark, BookmarkDto>();
        CreateMap<FollowTopic, FollowTopicDto>();
    }
}
