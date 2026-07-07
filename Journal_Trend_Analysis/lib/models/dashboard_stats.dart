class DashboardStats {
  final int totalPublications;
  final double averageCitations;
  final int? mostActiveYear;
  final int mostActiveYearCount;
  final String? topJournal;
  final int topJournalCount;
  final String? topAuthor;
  final int topAuthorCount;
  final String? mostInfluentialTitle;
  final String? mostInfluentialId;
  final int mostInfluentialCitations;
  final int? mostInfluentialYear;

  /// Distribution of publications grouped by their primary topic's
  /// parent field. Key is the field display name; value is the count of
  /// publications that have at least one topic in that field.
  final Map<String, int> fieldBreakdown;
  final int totalUniqueAuthors;

  /// Sum of (number of authors) across all publications. Always >=
  /// [totalUniqueAuthors] (only equal when no paper has more than one
  /// author). Surfaced so the methodology card can show "20 distinct
  /// authors contributed 47 authorships across 30 papers".
  final int totalAuthorships;

  const DashboardStats({
    required this.totalPublications,
    required this.averageCitations,
    this.mostActiveYear,
    this.mostActiveYearCount = 0,
    this.topJournal,
    this.topJournalCount = 0,
    this.topAuthor,
    this.topAuthorCount = 0,
    this.mostInfluentialTitle,
    this.mostInfluentialId,
    this.mostInfluentialCitations = 0,
    this.mostInfluentialYear,
    this.fieldBreakdown = const {},
    this.totalUniqueAuthors = 0,
    this.totalAuthorships = 0,
  });

  static const empty = DashboardStats(
    totalPublications: 0,
    averageCitations: 0,
  );
}
