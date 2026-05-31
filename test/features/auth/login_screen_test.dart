import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/data/models/user_profile.dart';
import 'package:norigo/data/repositories/repository_interfaces.dart';
import 'package:norigo/data/repositories/supabase_auth_repository.dart';
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

  testWidgets('login submits to auth repository and opens onboarding', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await _pumpLoginScreen(tester, authRepository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('emailField')),
      'traveler@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'password123',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.signInCount, 1);
    expect(repository.signUpCount, 0);
    expect(find.byKey(const ValueKey('tripBasicsRoute')), findsOneWidget);
  });

  testWidgets('sign up submits to auth repository and opens onboarding', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await _pumpLoginScreen(tester, authRepository: repository);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('emailField')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'password123',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.signInCount, 0);
    expect(repository.signUpCount, 1);
    expect(find.byKey(const ValueKey('tripBasicsRoute')), findsOneWidget);
  });

  testWidgets('auth failure stays on login and shows error', (tester) async {
    await _pumpLoginScreen(
      tester,
      authRepository: _FakeAuthRepository(
        error: const AuthRepositoryException('Invalid login credentials'),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('emailField')),
      'traveler@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'password123',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.byKey(const ValueKey('tripBasicsRoute')), findsNothing);
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
  AuthRepository? authRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(
        logoAsset: logoAsset ?? 'assets/images/splash/norigo_logo_full.png',
        headerAsset: headerAsset ?? 'assets/images/auth/login_header_bg.png',
        authRepository: authRepository ?? _FakeAuthRepository(),
      ),
      routes: {
        AppRoutes.tripBasics: (_) =>
            const Scaffold(body: Placeholder(key: ValueKey('tripBasicsRoute'))),
      },
    ),
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('authSubmitButton'));
  await tester.ensureVisible(button);
  await tester.tap(button);
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error});

  final Object? error;
  var signInCount = 0;
  var signUpCount = 0;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCount += 1;
    final error = this.error;
    if (error != null) throw error;
    return _profile(email);
  }

  @override
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpCount += 1;
    final error = this.error;
    if (error != null) throw error;
    return _profile(email);
  }

  @override
  Future<void> signOut() async {}

  UserProfile _profile(String email) {
    return UserProfile(
      id: 'test-user',
      displayName: 'Test Traveler',
      email: email,
      badge: 'Local Explorer',
      currentCity: 'Seoul',
      language: 'English',
    );
  }
}
