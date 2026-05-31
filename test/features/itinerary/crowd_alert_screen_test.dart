import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/mock_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/presentation/crowd_alert_screen.dart';

void main() {
  setUp(ItinerarySessionStore.resetForTesting);

  testWidgets('CrowdAlertScreen renders alert and alternatives', (
    tester,
  ) async {
    await _pumpCrowdAlert(tester);

    expect(find.text('Crowd Alert'), findsOneWidget);
    expect(
      find.text('Cafe Arte may become very busy within 30 minutes.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Even if no visible line, app-based queues may already be full.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cafe Arte'), findsWidgets);
    expect(find.text('Cafe Owall'), findsOneWidget);
    expect(find.text('Seosullan Small Book Cafe'), findsOneWidget);
    expect(find.text('Yunsul Bakery'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('keepOriginalPlanButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('switchPlanButton')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('alternativeSwitchButton')),
      findsNWidgets(3),
    );
  });

  testWidgets('alternative Switch button selects a new plan', (tester) async {
    await _pumpCrowdAlert(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('alternativeSwitchButton')).first,
    );
    await tester.pump();

    expect(find.text('Cafe Owall selected as your new plan.'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets('bottom Switch plan button shows update message', (tester) async {
    await _pumpCrowdAlert(tester);

    await tester.tap(find.byKey(const ValueKey('switchPlanButton')));
    await tester.pump();

    expect(find.text('Plan updated.'), findsOneWidget);
  });

  testWidgets('Itinerary tab is active in bottom navigation', (tester) async {
    await _pumpCrowdAlert(tester);

    expect(
      find.byKey(const ValueKey('crowdAlertBottomNavigation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('active-nav-Itinerary')), findsOneWidget);
  });

  testWidgets('generate retrip alternatives falls back when env is missing', (
    tester,
  ) async {
    await _pumpCrowdAlert(tester);

    final button = find.byKey(
      const ValueKey('generateRetripAlternativesButton'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Mock ennoia'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('alternativeSwitchButton')),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  test('MockCrowdAlertRepository returns three alternatives', () async {
    final alert = await const MockCrowdAlertRepository()
        .fetchCurrentCrowdAlert();

    expect(alert.originalPlace, 'Cafe Arte');
    expect(alert.alternatives, hasLength(3));
    expect(alert.alternatives.map((place) => place.name), [
      'Cafe Owall',
      'Seosullan Small Book Cafe',
      'Yunsul Bakery',
    ]);
  });
}

Future<void> _pumpCrowdAlert(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    const MaterialApp(home: CrowdAlertScreen(autoGenerateOnOpen: false)),
  );
  await tester.pumpAndSettle();
}
