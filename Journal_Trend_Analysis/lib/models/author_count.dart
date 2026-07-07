/// One author with the list of publications they appear on. Returned
/// by the analytics service so the dashboard / trend screen can
/// display the underlying evidence ("Henry N. Chapman appears in 3
/// papers: …, …, …"), not just a bare count.
class AuthorCount {
  AuthorCount({
    required this.name,
    required this.count,
    required this.sampleTitles,
    this.firstPublicationId,
  });

  final String name;
  final int count;

  /// Up to 3 publication titles this author appears on, so reviewers
  /// can quickly verify the count by tapping through.
  final List<String> sampleTitles;

  /// First paper's id, used to deep-link to a sample if the user
  /// wants to dig in. Nullable so the constructor can stay flexible.
  String? firstPublicationId;
}
