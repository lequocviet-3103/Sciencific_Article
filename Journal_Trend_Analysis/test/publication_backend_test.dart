import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab2_jta/models/publication.dart';

void main() {
  group('Publication.fromBackendJson', () {
    test('parses the full backend detail payload', () {
      final publication = Publication.fromBackendJson({
        'paperId': 'paper-1',
        'title': '  A   paper  ',
        'doi': 'https://doi.org/10.1000/example',
        'publicationYear': 2026,
        'citationCount': 12,
        'docType': 'journal-article',
        'journal': {
          'journalId': 'journal-1',
          'name': 'Research Journal',
          'publisher': 'Publisher',
          'issn': '1234-5678',
        },
        'authors': [
          {'authorId': 'author-1', 'name': 'A. Researcher'},
        ],
        'topics': [
          {'topicId': 'topic-1', 'name': 'Artificial Intelligence'},
        ],
        'keywords': [
          {'keywordId': 'keyword-1', 'name': 'Unused fallback'},
        ],
      });

      expect(publication.id, 'paper-1');
      expect(publication.title, 'A paper');
      expect(publication.doi, '10.1000/example');
      expect(publication.citedByCount, 12);
      expect(publication.authors.single.name, 'A. Researcher');
      expect(publication.topics.single.displayName, 'Artificial Intelligence');
      expect(publication.journal.publisher, 'Publisher');
      expect(publication.journal.issn, '1234-5678');
    });

    test('uses persisted keywords when a legacy paper has no topics', () {
      final publication = Publication.fromBackendJson({
        'paperId': 'legacy-paper',
        'title': 'Legacy paper',
        'citationCount': 0,
        'journal': null,
        'topics': <dynamic>[],
        'keywords': [
          {'keywordId': 'keyword-1', 'name': 'Machine Learning'},
          {'keywordId': 'keyword-2', 'name': 'Computer Vision'},
        ],
      });

      expect(
        publication.topics.map((topic) => topic.displayName),
        ['Machine Learning', 'Computer Vision'],
      );
    });
  });
}
