import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/my/data/my_page_repository.dart';
import 'package:norigo/features/my/domain/my_page_summary.dart';
import 'package:norigo/features/my/presentation/my_page_screen.dart';

void main() {
  testWidgets('My Page renders profile header, stats, menu rows, and assets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MyPageScreen(repository: _FakeMyPageRepository(_summary)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mina Park'), findsOneWidget);
    expect(find.text('Local Explorer'), findsWidgets);
    expect(find.text('Exploring Hongdae'), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);

    expect(find.text('Saved plans'), findsOneWidget);
    expect(find.text('Saved places'), findsWidgets);
    expect(find.text('Culture scans'), findsOneWidget);
    expect(find.text('Time saved'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('7h'), findsOneWidget);

    expect(find.text('My itineraries'), findsOneWidget);
    expect(find.text('Translation history'), findsOneWidget);
    expect(find.text('Saved culture guides'), findsOneWidget);
    expect(find.text('Wait-time help history'), findsOneWidget);
    expect(find.text('Language & notifications'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);

    expect(find.byKey(const ValueKey('my-header-bg')), findsOneWidget);
    expect(find.byKey(const ValueKey('local-explorer-badge')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('local-explorer-backpack')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('active-nav-My')), findsOneWidget);

    expect(MyPageAssets.headerBackground, 'assets/images/my/my_header_bg.png');
    expect(
      MyPageAssets.explorerBadge,
      'assets/images/my/local_explorer_badge.png',
    );
    expect(
      MyPageAssets.explorerBackpack,
      'assets/images/my/local_explorer_backpack.png',
    );
  });

  testWidgets('My Page falls back to local mode when repository throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPageScreen(
          repository: _ThrowingMyPageRepository(),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Emma Kim'), findsOneWidget);
    expect(find.text('Local mode'), findsOneWidget);
    expect(find.text('Saved plans'), findsOneWidget);
  });

  testWidgets('My itineraries bottom sheet displays plans and plan items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPageScreen(
          repository: _FakeMyPageRepository(_summary),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('My itineraries'));
    await tester.pumpAndSettle();

    expect(find.text('Spring Seoul route'), findsOneWidget);
    expect(find.textContaining('KTO OpenAPI'), findsOneWidget);

    await tester.tap(find.text('Spring Seoul route'));
    await tester.pumpAndSettle();

    expect(find.text('Gyeongbokgung Palace'), findsOneWidget);
    expect(find.text('Mangwon Market'), findsOneWidget);
  });

  testWidgets('Wait-time help history displays Re-Trip events', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPageScreen(
          repository: _FakeMyPageRepository(_summary),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Wait-time help history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wait-time help history'));
    await tester.pumpAndSettle();

    expect(find.text('Cafe Myeong'), findsOneWidget);
    expect(find.textContaining('crowd_spike'), findsOneWidget);
    expect(find.textContaining('kto_openapi_ennoia'), findsOneWidget);
  });

  testWidgets('Saved culture guides list renders recent scan records', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPageScreen(
          repository: _FakeMyPageRepository(_summary),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Saved culture guides'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved culture guides'));
    await tester.pumpAndSettle();

    expect(find.text('Bulguksa'), findsOneWidget);
    expect(find.textContaining('temple stone stack'), findsOneWidget);
    expect(find.textContaining('Culture DB'), findsOneWidget);
    expect(find.textContaining('소원 성취하세요'), findsOneWidget);
  });
}

const _summary = MyPageSummary(
  displayName: 'Mina Park',
  email: 'mina@example.com',
  avatarUrl: null,
  levelLabel: 'Local Explorer',
  level: 4,
  xp: 4250,
  xpTarget: 6000,
  locationLabel: 'Exploring Hongdae',
  languageLabel: 'Korean',
  savedPlansCount: 12,
  savedPlacesCount: 41,
  cultureScansCount: 9,
  timeSavedLabel: '7h',
  interests: ['Markets', 'Dessert', 'Night view'],
  foodNeeds: 'Vegetarian',
  latestPlanId: 'plan-1',
  localOnly: false,
  errorMessage: null,
  itineraries: [
    MyItineraryPlanPreview(
      id: 'plan-1',
      title: 'Spring Seoul route',
      createdAtLabel: '2026-06-02',
      sourceBadge: 'KTO OpenAPI',
      summary: 'Low-crowd route with markets and palace stops.',
      placeNames: ['Gyeongbokgung Palace', 'Mangwon Market'],
    ),
  ],
  savedPlaces: [
    MySavedPlacePreview(name: 'Page Turn', subtitle: 'Culture in Seochon'),
  ],
  cultureGuides: [
    MyCultureGuidePreview(
      title: 'Bulguksa',
      subtitle: 'temple stone stack\nCulture DB\n소원 성취하세요',
      createdAtLabel: '2026-06-01',
      locationName: 'Bulguksa',
      detectedObject: 'temple_stone_stack',
      sourceBadge: 'Culture DB',
      koreanPhrase: '소원 성취하세요',
    ),
  ],
  retripEvents: [
    MyRetripEventPreview(
      originalPlaceName: 'Cafe Myeong',
      triggerType: 'crowd_spike',
      sourceBadge: 'kto_openapi_ennoia',
      createdAtLabel: '2026-06-02',
    ),
  ],
);

class _FakeMyPageRepository extends MyPageRepository {
  const _FakeMyPageRepository(this.summary);

  final MyPageSummary summary;

  @override
  Future<MyPageSummary> fetchSummary() async => summary;
}

class _ThrowingMyPageRepository extends MyPageRepository {
  const _ThrowingMyPageRepository();

  @override
  Future<MyPageSummary> fetchSummary() {
    throw StateError('boom');
  }
}
