class Author {
  final String id;
  final String name;
  final String? institution;
  final String? displayName;
  final String? orcid;

  const Author({
    required this.id,
    required this.name,
    this.institution,
    this.displayName,
    this.orcid,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': name,
        'institution': institution,
      };

  factory Author.fromJson(Map<String, dynamic> json) {
    final authorObj = json['author'] as Map<String, dynamic>?;

    String? name = authorObj?['display_name'] as String?;
    name ??= json['raw_author_name'] as String?;

    String? orcid = authorObj?['orcid'] as String?;
    orcid ??= json['raw_orcid'] as String?;
    if (orcid != null && orcid.startsWith('https://orcid.org/')) {
      orcid = orcid.replaceFirst('https://orcid.org/', '');
    }

    String? institution;
    final institutions = json['institutions'] as List?;
    if (institutions != null && institutions.isNotEmpty) {
      final first = institutions.first as Map<String, dynamic>?;
      institution = first?['display_name'] as String?;
    }

    final finalName = (name?.trim());
    return Author(
      id: authorObj?['id'] as String? ?? '',
      name: (finalName != null && finalName.isNotEmpty) ? finalName : 'Unknown Author',
      institution: institution,
      displayName: (finalName != null && finalName.isNotEmpty) ? finalName : null,
      orcid: orcid,
    );
  }

  /// Parses the flat `{authorId, name}` shape returned by the .NET backend
  /// (`GET /api/papers/{id}`), as opposed to OpenAlex's nested authorship shape.
  factory Author.fromBackendJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim();
    return Author(
      id: json['authorId']?.toString() ?? '',
      name: (name != null && name.isNotEmpty) ? name : 'Unknown Author',
      displayName: name,
    );
  }
}
