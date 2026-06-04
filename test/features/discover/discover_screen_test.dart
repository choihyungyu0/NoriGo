import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/location/current_location_service.dart';
import 'package:norigo/features/discover/application/discover_controller.dart';
import 'package:norigo/features/discover/data/discover_repository.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';
import 'package:norigo/features/discover/domain/discover_recommendation_result.dart';
import 'package:norigo/features/discover/presentation/discover_screen.dart';
import 'package:norigo/features/home/home_shell.dart';
import 'package:norigo/features/onboarding/application/onboarding_preferences_store.dart';
import 'package:norigo/features/onboarding/application/user_consent_store.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';
import 'package:norigo/features/onboarding/domain/user_consent.dart';
import 'package:norigo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OnboardingPreferencesStore.resetForTesting();
    UserConsentStore.resetForTesting();
  });

  testWidgets('Discover screen uses full available mobile width', (
    tester,
  ) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('discoverScreen')),
    );
    expect(box.size.width, closeTo(430, 0.1));
    expect(find.text('Discover hidden spots'), findsOneWidget);
    expect(find.text('Skip the wait, go local.'), findsOneWidget);
  });

  testWidgets('category chips are horizontally scrollable', (tester) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    final scroller = tester.widget<ListView>(
      find.byKey(const ValueKey('discoverCategoryScroller')),
    );
    expect(scroller.scrollDirection, Axis.horizontal);
    expect(find.text('Quiet cafe'), findsOneWidget);
    expect(find.text('Quiet cafe\nactive'), findsNothing);
  });

  testWidgets('flutter_map renders when live map is enabled', (tester) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(
      _TestApp(controller: controller, enableLiveMap: true),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const ValueKey('discoverFlutterMap')), findsOneWidget);
    expect(find.byKey(const ValueKey('discoverFallbackMap')), findsNothing);
  });

  testWidgets('fallback map appears only when live map is disabled', (
    tester,
  ) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FlutterMap), findsNothing);
    expect(find.byKey(const ValueKey('discoverFallbackMap')), findsOneWidget);
  });

  testWidgets('recommendation list renders at least three fallback places', (
    tester,
  ) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    for (final name in ['Yeonnam Small Garden', 'Dear Dessert', 'Page Turn']) {
      await tester.scrollUntilVisible(
        find.text(name),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(name), findsOneWidget);
    }
  });

  test('local fallback returns distinct card image assets', () async {
    final result = await const LocalDiscoverRepository().fetchRecommendations(
      category: DiscoverCategory.quietCafe,
    );

    final firstThreeAssets = result.places
        .take(3)
        .map((place) => place.localImageAsset)
        .toSet();
    expect(result.places.length, greaterThanOrEqualTo(3));
    expect(firstThreeAssets.length, 3);
  });

  test(
    'current location is passed when consent and permission are granted',
    () async {
      OnboardingPreferencesStore.saveTripBasics(
        const TripBasics(
          preferredLanguage: 'Korean',
          baseLocation: 'Hongdae, Seoul',
        ),
      );
      UserConsentStore.resetForTesting(
        const UserConsent(locationConsent: true),
      );
      final repository = _FakeDiscoverRepository();
      final controller = DiscoverController(
        repository: repository,
        locationService: _FakeLocationService(
          result: CurrentLocationResult(
            location: CurrentLocation(
              latitude: 37.5563,
              longitude: 126.9236,
              updatedAt: DateTime.utc(2026, 6, 4),
            ),
            permissionStatus: 'granted',
          ),
        ),
      );

      await controller.load();

      expect(repository.userLanguages.last, 'Korean');
      expect(repository.baseLocations.last, 'Hongdae, Seoul');
      expect(repository.currentLats.last, 37.5563);
      expect(repository.currentLngs.last, 126.9236);
      expect(controller.usedCurrentLocation, isTrue);
    },
  );

  test('current location is not passed when permission is denied', () async {
    UserConsentStore.resetForTesting(const UserConsent(locationConsent: true));
    final repository = _FakeDiscoverRepository();
    final controller = DiscoverController(
      repository: repository,
      locationService: _FakeLocationService(
        result: const CurrentLocationResult(
          error: CurrentLocationError.permissionDenied,
          permissionStatus: 'denied',
        ),
      ),
    );

    await controller.load();

    expect(repository.currentLats.last, isNull);
    expect(repository.currentLngs.last, isNull);
    expect(controller.usedCurrentLocation, isFalse);
  });

  test('save failure does not crash or mark the card saved', () async {
    final repository = _FakeDiscoverRepository(saveResult: _saveFailure);
    final controller = DiscoverController(repository: repository);

    await controller.load();
    final result = await controller.savePlace(controller.places.first);

    expect(result.saved, isFalse);
    expect(controller.places.first.isSaved, isFalse);
  });

  testWidgets('saved place success updates controller UI state', (
    tester,
  ) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await controller.savePlace(controller.places.first);
    await tester.pump();

    expect(controller.places.first.isSaved, isTrue);
  });

  testWidgets('bottom nav Discover item is selected', (tester) async {
    await tester.pumpWidget(
      _LocalizedApp(child: const HomeShell(initialIndex: 3)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('bottomNav-discover-selected')),
      findsOneWidget,
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller, this.enableLiveMap = false});

  final DiscoverController controller;
  final bool enableLiveMap;

  @override
  Widget build(BuildContext context) {
    return _LocalizedApp(
      child: Scaffold(
        body: DiscoverScreen(
          controller: controller,
          enableLiveMap: enableLiveMap,
        ),
      ),
    );
  }
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _FakeLocationService extends CurrentLocationService {
  _FakeLocationService({required this.result});

  final CurrentLocationResult result;

  @override
  Future<CurrentLocationResult> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    return result;
  }

  @override
  Future<CurrentLocation?> latestKnownLocation() async => result.location;
}

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository({DiscoverSaveResult? saveResult})
    : saveResult =
          saveResult ??
          const DiscoverSaveResult(
            saved: true,
            localOnly: false,
            message: 'Place saved.',
          );

  final DiscoverSaveResult saveResult;
  final categories = <DiscoverCategory>[];
  final queries = <String>[];
  final userLanguages = <String>[];
  final baseLocations = <String>[];
  final currentLats = <double?>[];
  final currentLngs = <double?>[];

  @override
  Future<DiscoverRecommendationResult> fetchRecommendations({
    required DiscoverCategory category,
    String query = '',
    int limit = 10,
    String userLanguage = 'English',
    String baseLocation = 'Myeongdong, Seoul',
    double? currentLat,
    double? currentLng,
  }) async {
    categories.add(category);
    queries.add(query);
    userLanguages.add(userLanguage);
    baseLocations.add(baseLocation);
    currentLats.add(currentLat);
    currentLngs.add(currentLng);
    final places = _places
        .where((place) {
          final categoryMatch =
              category == DiscoverCategory.quietCafe ||
              place.category == category;
          final queryMatch =
              query.isEmpty ||
              place.name.toLowerCase().contains(query.toLowerCase());
          return categoryMatch && queryMatch;
        })
        .take(limit)
        .toList(growable: false);
    return DiscoverRecommendationResult.localFallback(
      category: category,
      places: places,
    );
  }

  @override
  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async => saveResult;
}

const _saveFailure = DiscoverSaveResult(
  saved: false,
  localOnly: false,
  message: 'Unable to save this place right now.',
);

const _places = [
  DiscoverPlace(
    id: 'yeonnam-small-garden',
    name: 'Yeonnam Small Garden',
    subtitle: 'quiet garden cafe',
    description: 'A calm garden cafe tucked behind Yeonnam streets.',
    category: DiscoverCategory.quietCafe,
    tags: ['Quiet', 'Local pick', 'Photo-friendly'],
    localImageAsset: 'assets/images/discover/spot_garden_cafe.png',
    latitude: 37.5629,
    longitude: 126.9247,
    walkingMinutes: 5,
    diversityScore: 92,
    localVisitRatio: 68,
    crowdLevel: 'Low crowd',
    riskScore: 18,
    rating: 4.7,
    reviewCount: 128,
    sourceType: 'local_fallback',
    sourceBadge: 'Demo fallback',
  ),
  DiscoverPlace(
    id: 'dear-dessert',
    name: 'Dear Dessert',
    subtitle: 'handmade seasonal desserts',
    description: 'A small dessert room with seasonal fruit.',
    category: DiscoverCategory.dessert,
    tags: ['Local pick', 'Sweet spot', 'Quiet'],
    localImageAsset: 'assets/images/discover/spot_dessert.png',
    latitude: 37.5563,
    longitude: 126.9062,
    walkingMinutes: 7,
    diversityScore: 88,
    localVisitRatio: 76,
    crowdLevel: 'Low crowd',
    riskScore: 16,
    rating: 4.8,
    reviewCount: 96,
    sourceType: 'local_fallback',
    sourceBadge: 'Demo fallback',
  ),
  DiscoverPlace(
    id: 'page-turn',
    name: 'Page Turn',
    subtitle: 'independent bookstore',
    description: 'A quiet bookstore cafe near galleries.',
    category: DiscoverCategory.culture,
    tags: ['Cultural space', 'Quiet', 'Local pick'],
    localImageAsset: 'assets/images/discover/spot_bookstore.png',
    latitude: 37.5798,
    longitude: 126.9694,
    walkingMinutes: 9,
    diversityScore: 90,
    localVisitRatio: 61,
    crowdLevel: 'Low crowd',
    riskScore: 22,
    rating: 4.6,
    reviewCount: 74,
    sourceType: 'local_fallback',
    sourceBadge: 'Demo fallback',
  ),
];
