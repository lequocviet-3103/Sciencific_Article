class Topic {
  final String id;
  final String displayName;
  final String? subfield;
  final String? field;
  final String? domain;
  final double? score;
  final int? worksCount;
  final String? description;

  const Topic({
    required this.id,
    required this.displayName,
    this.subfield,
    this.field,
    this.domain,
    this.score,
    this.worksCount,
    this.description,
  });

  /// The short label used in chips and cards. Prefers subfield, then field,
  /// then domain. Falls back to display name.
  String get category => subfield ?? field ?? domain ?? displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
      };

  factory Topic.fromJson(Map<String, dynamic> json) {
    final subfield = json['subfield'] as Map<String, dynamic>?;
    final field = json['field'] as Map<String, dynamic>?;
    final domain = json['domain'] as Map<String, dynamic>?;

    return Topic(
      id: (json['id'] as String?) ?? '',
      displayName: (json['display_name'] as String?)?.trim() ?? 'Unknown',
      subfield: subfield?['display_name'] as String?,
      field: field?['display_name'] as String?,
      domain: domain?['display_name'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      worksCount: (json['works_count'] as num?)?.toInt(),
      description: json['description'] as String?,
    );
  }

  /// Parses the flat `{topicId, name, field, domain, subfield, worksCount}`
  /// shape returned by the .NET backend (`GET /api/topics`,
  /// `GET /api/topics/featured`, and the `Topics` list nested in
  /// `GET /api/papers/{id}`) — field/domain/subfield are plain strings here,
  /// unlike OpenAlex's nested `{display_name: ...}` objects.
  factory Topic.fromBackendJson(Map<String, dynamic> json) {
    return Topic(
      id: json['topicId']?.toString() ?? '',
      displayName: json['name']?.toString().trim() ?? 'Unknown',
      field: json['field']?.toString(),
      domain: json['domain']?.toString(),
      subfield: json['subfield']?.toString(),
      worksCount: (json['worksCount'] as num?)?.toInt(),
    );
  }
}
