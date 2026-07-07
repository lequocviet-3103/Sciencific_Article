import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab2_jta/services/analytics_service.dart';
import 'package:prm393_lab2_jta/models/publication.dart';
import 'package:prm393_lab2_jta/models/journal.dart';
import 'package:prm393_lab2_jta/models/topic.dart';
import 'package:prm393_lab2_jta/models/author.dart';

void main() {
  late AnalyticsService analyticsService;

  setUp(() {
    analyticsService = AnalyticsService();
  });

  group('AnalyticsService', () {
    test('publicationsByYear groups and sorts by year', () {
      final pubs = [
        _makePub('1', 2022),
        _makePub('2', 2022),
        _makePub('3', 2023),
      ];

      final result = analyticsService.publicationsByYear(pubs);

      expect(result.length, 2);
      expect(result[0].year, 2022);
      expect(result[0].count, 2);
      expect(result[1].year, 2023);
      expect(result[1].count, 1);
    });

    test('publicationsByYear handles empty list', () {
      final result = analyticsService.publicationsByYear([]);
      expect(result, isEmpty);
    });

    test('topCited returns top N by citation count', () {
      final pubs = [
        _makePub('1', 2022, citedByCount: 10),
        _makePub('2', 2022, citedByCount: 50),
        _makePub('3', 2022, citedByCount: 30),
      ];

      final result = analyticsService.topCited(pubs, n: 2);

      expect(result.length, 2);
      expect(result[0].citedByCount, 50);
      expect(result[1].citedByCount, 30);
    });

    test('topJournals groups and sorts by journal name', () {
      final pubs = [
        _makePub('1', 2022, journalName: 'Nature'),
        _makePub('2', 2022, journalName: 'Nature'),
        _makePub('3', 2022, journalName: 'Science'),
      ];

      final result = analyticsService.topJournals(pubs, n: 5);

      expect(result.length, 2);
      expect(result[0].key, 'Nature');
      expect(result[0].value, 2);
      expect(result[1].key, 'Science');
      expect(result[1].value, 1);
    });

    test('topJournals ignores Unknown Journal placeholder', () {
      final pubs = [
        _makePub('1', 2022, journalName: 'Nature'),
        _makePub('2', 2022, journalName: 'Unknown Journal'),
        _makePub('3', 2022, journalName: ''),
      ];

      final result = analyticsService.topJournals(pubs);

      expect(result.length, 1);
      expect(result[0].key, 'Nature');
    });

    test('computeStats returns correct stats', () {
      final pubs = [
        _makePub('1', 2022, citedByCount: 10),
        _makePub('2', 2022, citedByCount: 20),
        _makePub('3', 2023, citedByCount: 15),
      ];

      final stats = analyticsService.computeStats(pubs);

      expect(stats.totalPublications, 3);
      expect(stats.totalCitations, 45);
      expect(stats.averageCitations, closeTo(15, 0.01));
      expect(stats.mostActiveYear, isNotNull);
    });

    test('computeStats handles empty publications', () {
      final stats = analyticsService.computeStats([]);

      expect(stats.totalPublications, 0);
      expect(stats.totalCitations, 0);
      expect(stats.averageCitations, 0);
    });

    test('countUniqueAuthors counts distinct names', () {
      final pubs = [
        _makePub('1', 2022, authors: [
          Author(id: '1', name: 'John Smith', displayName: 'John Smith'),
          Author(id: '2', name: 'Jane Doe', displayName: 'Jane Doe'),
        ]),
        _makePub('2', 2022, authors: [
          Author(id: '1', name: 'John Smith', displayName: 'John Smith'),
        ]),
      ];

      final count = analyticsService.countUniqueAuthors(pubs);

      expect(count, 2);
    });

    test('fieldBreakdown groups by primary topic field', () {
      final pubs = [
        _makePub('1', 2022, topics: [
          Topic(id: 't1', name: 'AI', field: 'Computer Science', score: 0.9),
        ]),
        _makePub('2', 2022, topics: [
          Topic(id: 't1', name: 'AI', field: 'Computer Science', score: 0.5),
        ]),
        _makePub('3', 2022, topics: [
          Topic(id: 't2', name: 'Bio', field: 'Biology', score: 0.8),
        ]),
      ];

      final breakdown = analyticsService.fieldBreakdown(pubs);

      expect(breakdown['Computer Science'], 2);
      expect(breakdown['Biology'], 1);
    });
  });
}

Publication _makePub(String id, int year, {
  int citedByCount = 0,
  String journalName = 'Nature',
  List<Author> authors = const [],
  List<Topic> topics = const [],
}) {
  return Publication(
    id: id,
    title: 'Test Paper $id',
    year: year,
    citedByCount: citedByCount,
    journal: Journal(name: journalName),
    authors: authors,
    topics: topics,
    abstract_: '',
    doi: null,
    isOpenAccess: false,
    keywords: [],
  );
}
