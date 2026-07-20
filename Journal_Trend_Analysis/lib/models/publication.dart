import 'author.dart';
import 'journal.dart';
import 'topic.dart';

class Publication {
  final String id;
  final String? doi;
  final String title;
  final int? year;
  final Journal journal;
  final int citedByCount;
  final String? abstractText;
  final List<Author> authors;
  final String? landingPageUrl;
  final String? type;
  final String? language;
  final List<Topic> topics;

  const Publication({
    required this.id,
    required this.title,
    required this.citedByCount,
    required this.journal,
    this.doi,
    this.year,
    this.abstractText,
    this.authors = const [],
    this.landingPageUrl,
    this.type,
    this.language,
    this.topics = const [],
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return _fromJson(json, full: true);
  }

  /// Parses the flat shape returned by the .NET backend's DB-backed
  /// endpoints (`GET /api/papers`, `GET /api/papers/{id}`) — camelCase
  /// keys, no nested `primary_location`/`abstract_inverted_index`, and
  /// `authors`/`topics` (when present) are already flat lists rather than
  /// OpenAlex's authorship/topic-score wrapper objects.
  factory Publication.fromBackendJson(Map<String, dynamic> json) {
    final journalMap = json['journal'] as Map<String, dynamic>?;
    final authorsJson = (json['authors'] as List?) ?? const [];
    final topicsJson = (json['topics'] as List?) ?? const [];
    final keywordsJson = (json['keywords'] as List?) ?? const [];
    final docType = json['docType']?.toString();
    final doi = _normalizeDoi(json['doi']?.toString());

    // Older synced rows may not have a paper_topics relationship even though
    // their OpenAlex concepts were persisted into paper_keywords. Use those
    // names as a detail-screen fallback instead of showing Topics as N/A.
    final researchAreas = topicsJson.isNotEmpty ? topicsJson : keywordsJson;

    return Publication(
      id: json['paperId']?.toString() ?? '',
      title: _cleanTitle(json['title']?.toString() ?? 'Untitled'),
      doi: doi,
      year: _parseYear(json['publicationYear']),
      citedByCount: (json['citationCount'] as num?)?.toInt() ?? 0,
      abstractText: json['abstract']?.toString(),
      journal: Journal(
        id: journalMap?['journalId']?.toString() ?? '',
        name: journalMap?['name']?.toString() ?? 'Unknown Journal',
        publisher: journalMap?['publisher']?.toString(),
        issn: journalMap?['issn']?.toString(),
      ),
      authors: authorsJson
          .map((e) => Author.fromBackendJson(e as Map<String, dynamic>))
          .toList(),
      type: (docType != null && docType.isNotEmpty)
          ? _formatDocType(docType)
          : null,
      language: json['language']?.toString(),
      topics: researchAreas
          .map((e) => Topic.fromBackendJson(_asBackendTopic(e)))
          .toList(),
    );
  }

  /// Lightweight factory used by the search/list endpoint. Skips the
  /// expensive abstract reconstruction and drops authors / topics /
  /// language that the list view does not need. Used together with
  /// OpenAlex's `select=` filter so the payload itself is smaller.
  factory Publication.fromSummaryJson(Map<String, dynamic> json) {
    return _fromJson(json, full: false);
  }

  static Publication _fromJson(
    Map<String, dynamic> json, {
    required bool full,
  }) {
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final source = primaryLocation?['source'] as Map<String, dynamic>?;
    // Try locations as fallback for journal info
    final locations = (json['locations'] as List?) ?? const [];
    Map<String, dynamic>? journalSource;
    if (source != null) {
      journalSource = source;
    } else if (locations.isNotEmpty) {
      // Try to find the first location with a valid source
      for (final loc in locations) {
        if (loc is Map<String, dynamic>) {
          final locSource = loc['source'] as Map<String, dynamic>?;
          if (locSource != null &&
              (locSource['display_name'] as String?)?.isNotEmpty == true) {
            journalSource = locSource;
            break;
          }
        }
      }
    }
    final doiRaw = json['doi'] as String?;
    final doi = doiRaw?.replaceFirst('https://doi.org/', '').trim();

    String? docType;
    final typeRaw = json['type'] as String?;
    if (typeRaw != null && typeRaw.isNotEmpty) {
      docType = _formatDocType(typeRaw);
    }

    if (!full) {
      // Summary path: still parse authors, topics and language because
      // the dashboard analytics and the detail screen need them
      // (top authors, per-field breakdown, language display on the
      // detail screen). We still skip the expensive abstract
      // reconstruction.
      final authorsJson = (json['authorships'] as List?) ?? const [];
      final topicsJson = (json['topics'] as List?) ?? const [];
      final langRaw = json['language'] as String?;
      return Publication(
        id: (json['id'] as String?) ?? '',
        title: _cleanTitle(json['title'] as String? ?? 'Untitled'),
        doi: (doi != null && doi.isNotEmpty) ? doi : null,
        year: _parseYear(json['publication_year']),
        journal: Journal.fromJson(journalSource),
        citedByCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
        authors: authorsJson
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList(),
        language: (langRaw != null && langRaw.isNotEmpty) ? langRaw : null,
        type: docType,
        topics: topicsJson
            .take(5)
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final authorsJson = (json['authorships'] as List?) ?? const [];
    final topicsJson = (json['topics'] as List?) ?? const [];
    final langRaw = json['language'] as String?;

    return Publication(
      id: (json['id'] as String?) ?? '',
      title: _cleanTitle(json['title'] as String? ?? 'Untitled'),
      doi: (doi != null && doi.isNotEmpty) ? doi : null,
      year: _parseYear(json['publication_year']),
      journal: Journal.fromJson(journalSource),
      citedByCount: (json['cited_by_count'] as num?)?.toInt() ?? 0,
      abstractText: _reconstructAbstract(
        json['abstract_inverted_index'] as Map<String, dynamic>?,
      ),
      authors: authorsJson
          .map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList(),
      landingPageUrl: journalSource?['homepage_url'] as String?,
      type: docType,
      language: (langRaw != null && langRaw.isNotEmpty) ? langRaw : null,
      topics: topicsJson
          .take(10)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doi': doi,
    'title': title,
    'publication_year': year,
    'cited_by_count': citedByCount,
    'abstract_inverted_index': null,
    'authorships': authors.map((a) => a.toJson()).toList(),
    'type': type,
    'language': language,
    'topics': topics.map((t) => t.toJson()).toList(),
  };

  static String _cleanTitle(String raw) =>
      raw.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String? _normalizeDoi(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .replaceFirst(
          RegExp(r'^https?://(dx\.)?doi\.org/', caseSensitive: false),
          '',
        )
        .trim();
  }

  static Map<String, dynamic> _asBackendTopic(dynamic value) {
    final map = value as Map<String, dynamic>;
    if (map.containsKey('topicId')) return map;
    return {'topicId': map['keywordId'], 'name': map['name']};
  }

  static int? _parseYear(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String? _reconstructAbstract(Map<String, dynamic>? inverted) {
    if (inverted == null || inverted.isEmpty) return null;

    final sorted = <int, String>{};
    inverted.forEach((word, positions) {
      if (positions is List) {
        for (final p in positions) {
          if (p is int) sorted[p] = word;
        }
      }
    });

    if (sorted.isEmpty) return null;

    final maxPos = sorted.keys.reduce((a, b) => a > b ? a : b);
    final buffer = StringBuffer();
    for (var i = 0; i <= maxPos; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(sorted[i] ?? '');
    }
    return buffer.toString().trim();
  }

  static String _formatDocType(String raw) {
    final types = {
      'journal-article': 'Journal Article',
      'book-chapter': 'Book Chapter',
      'book': 'Book',
      'proceedings-article': 'Conference Paper',
      'dissertation': 'Dissertation',
      'patent': 'Patent',
      'preprint': 'Preprint',
      'report': 'Report',
      'dataset': 'Dataset',
      'software': 'Software',
      'platform': 'Platform',
      'component': 'Component',
      'paratext': 'Paratext',
      'reference-entry': 'Reference Entry',
      'peer-review': 'Peer Review',
    };
    return types[raw] ?? raw.replaceAll('-', ' ').replaceAll('_', ' ');
  }
}
