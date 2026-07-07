import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab2_jta/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JournalTrendApp());
    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
  });
}
