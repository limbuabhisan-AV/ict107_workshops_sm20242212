import 'package:flutter_test/flutter_test.dart';
import 'package:ict107_workshops_sm20242212/main.dart';

void main() {
  testWidgets('ICT107 app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentDatabaseApp());
    expect(find.text('ICT107 Student Database'), findsOneWidget);
    expect(find.text('Abhisan Limbu | sm20242212'), findsOneWidget);
  });
}
