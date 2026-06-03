import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/discover/application/discover_controller.dart';
import 'package:norigo/features/discover/data/discover_repository.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';
import 'package:norigo/features/discover/domain/discover_recommendation_result.dart';
import 'package:norigo/features/discover/presentation/discover_screen.dart';

void main() {
  testWidgets('Discover screen renders header and local fallback map', (
    tester,
  ) async {
    final controller = DiscoverController(
      repository: _FakeDiscoverRepository(),
    );

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    expect(find.text('Discover hidden spots'), findsOneWidget);
    expect(find.text('Skip the wait, go local.'), findsOneWidget);
    expect(
      find.text('Search destinations, food, cafes, culture questions'),
      findsOneWidget,
    );
    expect(find.text('Quiet cafe\nactive'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Yeonnam Small Garden'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Yeonnam Small Garden'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
  });

  testWidgets('category chip reloads recommendations', (tester) async {
    final repository = _FakeDiscoverRepository();
    final controller = DiscoverController(repository: repository);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Dessert'));
    await tester.pump();
    await tester.pump();

    expect(repository.categories, contains(DiscoverCategory.dessert));
    await tester.scrollUntilVisible(
      find.text('Dear Dessert'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dear Dessert'), findsOneWidget);
  });

  testWidgets('search triggers repository call', (tester) async {
    final repository = _FakeDiscoverRepository();
    final controller = DiscoverController(repository: repository);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('discoverSearchField')),
      'garden',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(repository.queries, contains('garden'));
  });

  test(
    'save place handles missing table by keeping local saved state',
    () async {
      final repository = _FakeDiscoverRepository(localSave: true);
      final controller = DiscoverController(repository: repository);

      await controller.load();
      final place = controller.places.first;
      final result = await controller.savePlace(place);

      expect(result.saved, isTrue);
      expect(result.localOnly, isTrue);
      expect(controller.places.first.isSaved, isTrue);
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DiscoverScreen(controller: controller, enableLiveMap: false),
      ),
    );
  }
}

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository({this.localSave = false});

  final bool localSave;
  final categories = <DiscoverCategory>[];
  final queries = <String>[];

  @override
  Future<DiscoverRecommendationResult> fetchRecommendations({
    required DiscoverCategory category,
    String query = '',
    int limit = 10,
  }) async {
    categories.add(category);
    queries.add(query);
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
  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async {
    return DiscoverSaveResult(
      saved: true,
      localOnly: localSave,
      message: localSave ? 'Saved locally.' : null,
    );
  }
}

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
];
