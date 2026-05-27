import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders the branded auth content', (tester) async {
    await _pumpLoginScreen(tester);

    expect(find.text('Welcome to\nNoriGo'), findsOneWidget);
    expect(
      find.text('Crowd-free routes and\ncultural help in Korea.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await _pumpLoginScreen(tester);

    final loginButton = find.widgetWithText(FilledButton, 'Log in');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('sign up tab can be selected', (tester) async {
    await _pumpLoginScreen(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    expect(find.text('Log in instead'), findsOneWidget);
  });

  testWidgets('missing image assets use fallbacks without crashing', (
    tester,
  ) async {
    await _pumpLoginScreen(
      tester,
      logoAsset: 'assets/images/auth/missing_logo.png',
      headerAsset: 'assets/images/auth/missing_header.png',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to\nNoriGo'), findsOneWidget);
  });
}

Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  String? logoAsset,
  String? headerAsset,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(
        logoAsset: logoAsset ?? 'assets/images/splash/norigo_logo_full.png',
        headerAsset: headerAsset ?? 'assets/images/auth/login_header_bg.png',
      ),
    ),
  );
}
