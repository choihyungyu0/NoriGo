import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/app.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/home/home_shell.dart';

void main() {
  testWidgets('splash routes to login screen', (tester) async {
    await tester.pumpWidget(const NoriGoApp());

    expect(find.text('NoriGo'), findsOneWidget);
    expect(find.text('Travel smart, feel local.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(
      find.text('Avoid crowds + understand culture in one app.'),
      findsOneWidget,
    );
    expect(find.text('Log in or sign up'), findsOneWidget);
  });

  testWidgets('home shell shows consistent bottom tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: NoriGoTheme.light(), home: const HomeShell()),
    );

    expect(find.text('Hi, Emma!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Itinerary'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('My'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Culture scan'), findsOneWidget);
    expect(find.text('Bulguksa'), findsOneWidget);
  });
}
