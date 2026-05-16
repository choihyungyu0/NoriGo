import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/app.dart';

void main() {
  testWidgets('app opens the Culture Scan MVP first', (tester) async {
    await tester.pumpWidget(const NoriGoApp());
    await tester.pump();

    expect(find.text('Bulguksa'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('소원성취'), findsOneWidget);
    expect(find.text('Scan Culture'), findsOneWidget);
  });
}
