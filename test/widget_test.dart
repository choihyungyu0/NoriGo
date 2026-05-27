import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/app.dart';

void main() {
  testWidgets('app opens the branded splash screen first', (tester) async {
    await tester.pumpWidget(const NoriGoApp());
    await tester.pump();

    expect(find.text('Preparing your local journey...'), findsOneWidget);
    expect(find.text('로컬 여정을 준비하고 있어요...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
