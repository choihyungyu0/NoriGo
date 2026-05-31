import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/data/mock_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';
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

  testWidgets('KTO Re-Trip result renders three enriched alternatives', (
    tester,
  ) async {
    await _pumpCrowdAlert(
      tester,
      repository: const _StaticCrowdAlertRepository(_ktoAlert),
    );

    expect(find.text('KTO OpenAPI + ennoia'), findsOneWidget);
    expect(find.text('Deoksugung Daehanmun'), findsOneWidget);
    expect(
      find.text('Deoksugung Daehanmun may become very busy.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('alternativeSwitchButton')),
      findsNWidgets(3),
    );
    expect(find.text('Seoul Museum of Art'), findsOneWidget);
    expect(
      find.text('Quiet indoor art stop near the palace route.'),
      findsOneWidget,
    );
    expect(find.text('KTO-listed nearby alternative.'), findsOneWidget);
    expect(find.textContaining('Low'), findsWidgets);
    expect(find.textContaining('KTO 130856'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
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

Future<void> _pumpCrowdAlert(
  WidgetTester tester, {
  CrowdAlertRepository repository = const MockCrowdAlertRepository(),
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: CrowdAlertScreen(repository: repository, autoGenerateOnOpen: false),
    ),
  );
  await tester.pumpAndSettle();
}

const _ktoAlert = CrowdAlert(
  id: 'kto-retrip',
  planId: '00000000-0000-4000-8000-000000000001',
  originalItemId: 'deoksugung-daehanmun',
  retripEventId: '00000000-0000-4000-8000-000000000010',
  originalPlace: 'Deoksugung Daehanmun',
  scheduledTime: '09:00',
  crowdLevel: 'Very High',
  estimatedWait: '40-60 min',
  alertMessage: 'Deoksugung Daehanmun may become very busy.',
  foreignerQueueTip: 'Digital queues may already be full.',
  sourceType: 'kto_openapi_ennoia',
  sourceBadge: 'KTO OpenAPI + ennoia',
  alternatives: [
    AlternativePlace(
      id: 'seoul-museum-of-art',
      name: 'Seoul Museum of Art',
      description: 'KTO-listed nearby alternative.',
      walkingTime: '5 min walk',
      diversityScore: 90,
      crowdLevel: 'Low',
      contentId: '130856',
      recommendationCopy: 'Quiet indoor art stop near the palace route.',
    ),
    AlternativePlace(
      id: 'jeongdong-observatory',
      name: 'Jeongdong Observatory',
      description: 'Indoor view stop near City Hall.',
      walkingTime: '7 min walk',
      diversityScore: 88,
      crowdLevel: 'Low',
      contentId: '2660771',
      recommendationCopy: 'A compact low-crowd viewpoint.',
    ),
    AlternativePlace(
      id: 'seoul-history-museum',
      name: 'Seoul Museum of History',
      description: 'History stop with a calmer indoor flow.',
      walkingTime: '12 min walk',
      diversityScore: 86,
      crowdLevel: 'Moderate',
      contentId: '130711',
      recommendationCopy: 'Keeps the route cultural and weather-safe.',
    ),
  ],
);

class _StaticCrowdAlertRepository implements CrowdAlertRepository {
  const _StaticCrowdAlertRepository(this.alert);

  final CrowdAlert alert;

  @override
  Future<CrowdAlert> fetchCurrentCrowdAlert() async => alert;

  @override
  Future<void> keepOriginalPlan() async {}

  @override
  Future<void> switchToAlternative(
    CrowdAlert alert,
    AlternativePlace alternative,
  ) async {}
}
