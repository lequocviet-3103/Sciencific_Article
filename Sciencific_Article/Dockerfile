FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY Sciencific_Article.Domain/Sciencific_Article.Domain.csproj Sciencific_Article.Domain/
COPY Sciencific_Article.Application/Sciencific_Article.Application.csproj Sciencific_Article.Application/
COPY Sciencific_Article.Infastructure/Sciencific_Article.Infastructure.csproj Sciencific_Article.Infastructure/
COPY Sciencific_Article/Sciencific_Article.csproj Sciencific_Article/

RUN dotnet restore Sciencific_Article/Sciencific_Article.csproj

COPY . .
WORKDIR /src/Sciencific_Article
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "Sciencific_Article.dll"]
