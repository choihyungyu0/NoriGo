import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/onboarding/presentation/interests_alerts_screen.dart';

void main() {
  testWidgets('InterestsAlertsScreen renders title and default selections', (
    tester,
  ) async {
    await _pumpInterestsAlerts(tester);

    expect(find.text('Interests & Alerts'), findsOneWidget);
    expect(find.text('Personalize your experience.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selected-interest-Food')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-interest-Dessert')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-interest-Traditional market')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-interest-Night view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-interest-Photo spot')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('finishSetupButton')), findsOneWidget);
  });

  testWidgets('user can toggle an interest chip', (tester) async {
    await _pumpInterestsAlerts(tester);

    await tester.tap(find.byKey(const ValueKey('selected-interest-Food')));
    await tester.pump();

    expect(find.byKey(const ValueKey('interest-Food')), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-interest-Food')), findsNothing);
  });

  testWidgets('user cannot unselect the last remaining interest', (
    tester,
  ) async {
    await _pumpInterestsAlerts(tester);

    for (final interest in [
      'Dessert',
      'Traditional market',
      'Night view',
      'Photo spot',
    ]) {
      await tester.tap(find.byKey(ValueKey('selected-interest-$interest')));
      await tester.pump();
    }

    await tester.tap(find.byKey(const ValueKey('selected-interest-Food')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('selected-interest-Food')),
      findsOneWidget,
    );
    expect(find.text('Select at least one interest.'), findsOneWidget);
  });

  testWidgets('crowd preference slider can change', (tester) async {
    await _pumpInterestsAlerts(tester);

    final slider = find.byKey(const ValueKey('crowdPreferenceSlider'));
    tester.widget<Slider>(slider).onChanged?.call(0.8);
    await tester.pump();

    expect(tester.widget<Slider>(slider).value, closeTo(0.8, 0.01));
  });

  testWidgets('real-time crowd alerts switch can toggle', (tester) async {
    await _pumpInterestsAlerts(tester);

    final crowdSwitch = find.byKey(
      const ValueKey('toggle-Real-time crowd alerts'),
    );

    expect(tester.widget<Switch>(crowdSwitch).value, isTrue);

    tester.widget<Switch>(crowdSwitch).onChanged?.call(false);
    await tester.pump();

    expect(tester.widget<Switch>(crowdSwitch).value, isFalse);
  });

  testWidgets('enable access button shows placeholder snackbar', (
    tester,
  ) async {
    await _pumpInterestsAlerts(tester);

    final accessButton = find.byKey(const ValueKey('enableAccessButton'));
    await tester.ensureVisible(accessButton);
    await tester.tap(accessButton);
    await tester.pump();

    expect(
      find.text('Permission flow will be connected later.'),
      findsOneWidget,
    );
  });

  testWidgets('missing ready image asset falls back without crashing', (
    tester,
  ) async {
    await _pumpInterestsAlerts(
      tester,
      readyPenguinAsset: 'assets/images/onboarding/missing_ready_penguin.png',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Interests & Alerts'), findsOneWidget);
  });

  testWidgets('Finish setup navigates to itinerary route', (tester) async {
    Object? routeArguments;
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: const InterestsAlertsScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.itinerary) {
            routeArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: Placeholder(key: ValueKey('itineraryRoute')),
              ),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('finishSetupButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('itineraryRoute')), findsOneWidget);
    expect(routeArguments, isA<ItineraryAgentRequest>());
  });
}

Future<void> _pumpInterestsAlerts(
  WidgetTester tester, {
  String? readyPenguinAsset,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: InterestsAlertsScreen(
        readyPenguinAsset:
            readyPenguinAsset ??
            'assets/images/onboarding/onboarding_ready_penguin.png',
      ),
    ),
  );
}
