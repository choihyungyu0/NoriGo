import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders the branded loading copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(enableAutoNavigation: false)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Preparing your local journey...'), findsOneWidget);
    expect(find.text('로컬 여정을 준비하고 있어요...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
