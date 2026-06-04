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

  testWidgets('CrowdAlertScreen renders the first alert step only', (
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
    expect(find.text('Cafe Owall'), findsNothing);
    expect(find.text('Seosullan Small Book Cafe'), findsNothing);
    expect(find.text('Yunsul Bakery'), findsNothing);
    expect(
      find.byKey(const ValueKey('keepOriginalPlanButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('viewAlternativePlacesButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('alternativeSwitchButton')), findsNothing);
  });

  testWidgets('alert button opens alternatives and selection shows update', (
    tester,
  ) async {
    await _pumpCrowdAlert(tester);

    await tester.tap(find.byKey(const ValueKey('viewAlternativePlacesButton')));
    await tester.pumpAndSettle();

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(find.text('Cafe Owall'), findsOneWidget);
    expect(find.text('Seosullan Small Book Cafe'), findsOneWidget);
    expect(find.text('Yunsul Bakery'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('alternativeSwitchButton')),
      findsNWidgets(3),
    );

    await tester.tap(
      find.byKey(const ValueKey('alternativeSwitchButton')).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan updated'), findsOneWidget);
    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('변경됨'), findsOneWidget);
    expect(find.text('변경된 경로로 안내 시작'), findsOneWidget);
  });

  testWidgets('KTO Re-Trip result renders three enriched alternatives', (
    tester,
  ) async {
    await _pumpCrowdAlert(
      tester,
      repository: const _StaticCrowdAlertRepository(_ktoAlert),
    );

    await tester.tap(find.byKey(const ValueKey('viewAlternativePlacesButton')));
    await tester.pumpAndSettle();

    expect(find.text('KTO OpenAPI + ennoia'), findsOneWidget);
    expect(find.textContaining('Deoksugung Daehanmun'), findsOneWidget);
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

  testWidgets('Seoul real-time alert renders congestion and risk score', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CrowdAlertScreen(
          autoGenerateOnOpen: false,
          initialAlert: CrowdAlert(
            id: 'seoul-alert',
            originalPlace: 'Bukchon Hanok Village',
            scheduledTime: '14:00',
            crowdLevel: '붐빔',
            estimatedWait: '40-60 min',
            alertMessage: 'Bukchon is very crowded.',
            foreignerQueueTip: 'No incident data was used.',
            sourceType: 'seoul_realtime_citydata',
            sourceBadge: 'Seoul Real-time',
            congestionLevel: '붐빔',
            riskScore: 85,
            alternatives: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seoul Real-time'), findsOneWidget);
    expect(find.text('붐빔'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Bukchon is very crowded.'), findsOneWidget);
    expect(find.text('대안 장소 보기'), findsOneWidget);
    expect(find.byKey(const ValueKey('alternativeSwitchButton')), findsNothing);
  });

  testWidgets('first-step alternatives button shows stored recommendations', (
    tester,
  ) async {
    await _pumpCrowdAlert(tester);

    await tester.tap(find.byKey(const ValueKey('viewAlternativePlacesButton')));
    await tester.pumpAndSettle();

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('alternativeSwitchButton')),
      findsNWidgets(3),
    );
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
    await _pumpCrowdAlert(
      tester,
      initialAlert: const CrowdAlert(
        id: 'seoul-alert',
        originalPlace: 'Bukchon Hanok Village',
        scheduledTime: '14:00',
        crowdLevel: 'Very High',
        estimatedWait: '40-60 min',
        alertMessage: 'Bukchon is very crowded.',
        foreignerQueueTip: 'No incident data was used.',
        sourceType: 'seoul_realtime_citydata',
        sourceBadge: 'Seoul Real-time',
        alternatives: [],
      ),
    );

    await tester.tap(find.byKey(const ValueKey('viewAlternativePlacesButton')));
    await tester.pumpAndSettle();

    expect(find.text('Seoul Real-time'), findsOneWidget);
    expect(find.text('Cafe Owall'), findsOneWidget);
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
  CrowdAlert? initialAlert,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: CrowdAlertScreen(
        repository: repository,
        autoGenerateOnOpen: false,
        initialAlert: initialAlert,
      ),
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
