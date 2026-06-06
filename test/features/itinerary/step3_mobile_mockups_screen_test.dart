import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';

void main() {
  setUp(ItinerarySessionStore.resetForTesting);

  testWidgets('Step 3 mobile mockups render the three phone states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpNamedRoute(tester, AppRoutes.step3MobileMockups);
    await tester.pumpAndSettle();

    expect(find.text('혼잡도 알림'), findsOneWidget);
    expect(find.text('북촌 한옥마을이 매우 혼잡해요!'), findsOneWidget);
    expect(find.text('대안 장소 보기'), findsOneWidget);
    expect(find.text('일정 그대로 유지'), findsOneWidget);

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(find.text('청운 한옥 카페'), findsOneWidget);
    expect(find.text('국립고궁박물관'), findsWidgets);
    expect(find.text('계동길 북카페거리'), findsOneWidget);
    expect(find.text('이 장소로 변경'), findsNWidgets(3));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/discover/spot_garden_cafe.png',
      ),
      findsWidgets,
    );

    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('변경됨'), findsOneWidget);
    expect(find.text('변경된 경로로 안내 시작'), findsOneWidget);
  });

  testWidgets('Step 3 route opens the first mockup screen and routes forward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpNamedRoute(tester, AppRoutes.step3CrowdAlert);
    await tester.pumpAndSettle();

    expect(find.text('혼잡도 알림'), findsOneWidget);
    expect(find.text('9:41'), findsNothing);
    expect(find.text('대안 장소 추천'), findsNothing);
    expect(find.text('일정이 변경되었어요!'), findsNothing);

    await tester.tap(find.text('대안 장소 보기'));
    await tester.pumpAndSettle();

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(find.text('혼잡도 알림'), findsNothing);
    expect(find.text('일정이 변경되었어요!'), findsNothing);

    await tester.tap(find.text('이 장소로 변경').first);
    await tester.pumpAndSettle();

    expect(ItinerarySessionStore.currentPlan, isNotNull);
    expect(ItinerarySessionStore.currentPlan?.items[1].placeName, '청운 한옥 카페');
    expect(
      ItinerarySessionStore.currentPlan?.items[1].imageAssetPath,
      'assets/images/discover/spot_garden_cafe.png',
    );
    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('청운 한옥 카페'), findsOneWidget);
    expect(find.text('혼잡도 알림'), findsNothing);
    expect(find.text('대안 장소 추천'), findsNothing);
  });

  testWidgets('Home route opens and completes the three-step crowd flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpNamedRoute(tester, AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.text('혼잡도 알림'), findsOneWidget);
    expect(find.text('북촌 한옥마을이 매우 혼잡해요!'), findsOneWidget);
    expect(find.text('대안 장소 보기'), findsOneWidget);

    await tester.tap(find.text('대안 장소 보기'));
    await tester.pumpAndSettle();

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(find.text('이 장소로 변경'), findsNWidgets(3));

    await tester.tap(find.text('이 장소로 변경').first);
    await tester.pumpAndSettle();

    expect(ItinerarySessionStore.currentPlan?.items[1].placeName, '청운 한옥 카페');
    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('변경된 경로로 안내 시작'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '변경된 경로로 안내 시작'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('savePlanButton')), findsOneWidget);
    expect(find.text('청운 한옥 카페'), findsOneWidget);
  });
}

Future<void> _pumpNamedRoute(WidgetTester tester, String routeName) {
  final builder = AppRouter.routes[routeName]!;
  return tester.pumpWidget(
    MaterialApp(
      routes: AppRouter.routes,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: builder,
        ),
      ],
    ),
  );
}
