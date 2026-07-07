import '../models/author_count.dart';
import '../models/dashboard_stats.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';

class AnalyticsService {
  List<TrendPoint> publicationsByYear(List<Publication> pubs) {
    final map = <int, int>{};
    for (final p in pubs) {
      if (p.year != null) {
        map[p.year!] = (map[p.year!] ?? 0) + 1;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => TrendPoint(year: e.key, count: e.value)).toList();
  }

  List<Publication> topCited(List<Publication> pubs, {int n = 10}) {
    final sorted = [...pubs]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    return sorted.take(n).toList();
  }

  List<MapEntry<String, int>> topJournals(
    List<Publication> pubs, {
    int n = 5,
  }) {
    final map = <String, int>{};
    for (final p in pubs) {
      final name = p.journal.name;
      // Skip papers with no real journal: empty, the placeholder
      // string used by Journal.fromJson, or null-ish whitespace.
      if (name.isEmpty ||
          name == 'Unknown Journal' ||
          name.trim().isEmpty) {
        continue;
      }
      map[name] = (map[name] ?? 0) + 1;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(n).toList();
  }

  /// Convenience: top N authors as (name, count) pairs, derived from
  /// the full [authorBreakdown].
  List<AuthorCount> topAuthors(
    List<Publication> pubs, {
    int n = 5,
  }) {
    return authorBreakdown(pubs).take(n).toList();
  }

  /// Group publications by the parent field of their highest-scored
  /// topic. A publication is counted once per field, even if it has
  /// multiple topics in that field, so a single paper can't inflate
  /// the breakdown.
  Map<String, int> fieldBreakdown(List<Publication> pubs) {
    final map = <String, int>{};
    for (final p in pubs) {
      if (p.topics.isEmpty) continue;
      // Use the highest-scored topic as the "primary" topic for that
      // publication, then take its parent field.
      final primary = p.topics.reduce(
        (a, b) => (a.score ?? 0) >= (b.score ?? 0) ? a : b,
      );
      final field = primary.field;
      if (field == null || field.isEmpty) continue;
      map[field] = (map[field] ?? 0) + 1;
    }
    return map;
  }

  /// Count distinct author names across the corpus. Names are matched
  /// case-insensitively and trimmed so that "John Smith" and
  /// "john smith " are not double-counted.
  int countUniqueAuthors(List<Publication> pubs) {
    final seen = <String>{};
    for (final p in pubs) {
      for (final a in p.authors) {
        final normalized = a.name.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        seen.add(normalized);
      }
    }
    return seen.length;
  }

  /// Build the full per-author breakdown so the UI can show evidence
  /// ("X appears in N papers: A, B, C"). Returned list is sorted by
  /// count desc, then name asc for stability.
  List<AuthorCount> authorBreakdown(List<Publication> pubs) {
    final map = <String, _AuthorBucket>{};
    for (final p in pubs) {
      for (final a in p.authors) {
        final original = a.name.trim();
        final normalized = original.toLowerCase();
        if (normalized.isEmpty) continue;
        final bucket = map.putIfAbsent(
          normalized,
          () => _AuthorBucket(displayName: original),
        );
        // Use the longest-spelling occurrence as the display name so
        // "J. Smith" and "John Smith" collapse to "John Smith".
        if (original.length > bucket.displayName.length) {
          bucket.displayName = original;
        }
        bucket.count += 1;
        bucket.firstId ??= p.id;
        if (bucket.sampleTitles.length < 3) {
          bucket.sampleTitles.add(p.title);
        }
      }
    }
    final result = map.entries
        .map(
          (e) => AuthorCount(
            name: e.value.displayName,
            count: e.value.count,
            sampleTitles: List.unmodifiable(e.value.sampleTitles),
          )..firstPublicationId = e.value.firstId,
        )
        .toList();
    result.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List.unmodifiable(result);
  }

  DashboardStats computeStats(List<Publication> pubs) {
    if (pubs.isEmpty) return DashboardStats.empty;

    final totalCitations = pubs.fold<int>(0, (s, p) => s + p.citedByCount);
    final avg = totalCitations / pubs.length;

    final yearMap = <int, int>{};
    final journalMap = <String, int>{};
    final authorMap = <String, int>{};

    for (final p in pubs) {
      if (p.year != null) yearMap[p.year!] = (yearMap[p.year!] ?? 0) + 1;
      if (p.journal.name.isNotEmpty) {
        journalMap[p.journal.name] =
            (journalMap[p.journal.name] ?? 0) + 1;
      }
      for (final a in p.authors) {
        final normalized = a.name.trim();
        if (normalized.isEmpty) continue;
        authorMap[normalized] = (authorMap[normalized] ?? 0) + 1;
      }
    }

    final topYear = _topEntry(yearMap);
    final topJournal = _topEntry(journalMap);
    final topAuthor = _topEntry(authorMap);
    final mostInfluential = topCited(pubs, n: 1).firstOrNull;

    return DashboardStats(
      totalPublications: pubs.length,
      averageCitations: avg,
      mostActiveYear: topYear?.key,
      mostActiveYearCount: topYear?.value ?? 0,
      topJournal: topJournal?.key,
      topJournalCount: topJournal?.value ?? 0,
      topAuthor: topAuthor?.key,
      topAuthorCount: topAuthor?.value ?? 0,
      mostInfluentialTitle: mostInfluential?.title,
      mostInfluentialId: mostInfluential?.id,
      mostInfluentialCitations: mostInfluential?.citedByCount ?? 0,
      mostInfluentialYear: mostInfluential?.year,
      fieldBreakdown: fieldBreakdown(pubs),
      totalUniqueAuthors: countUniqueAuthors(pubs),
      totalAuthorships: authorMap.values.fold<int>(0, (s, v) => s + v),
    );
  }

  MapEntry<K, int>? _topEntry<K>(Map<K, int> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _AuthorBucket {
  _AuthorBucket({required this.displayName});
  String displayName;
  int count = 0;
  String? firstId;
  final List<String> sampleTitles = <String>[];
}
