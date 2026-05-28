import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/router.dart';

void main() {
  testWidgets('Step 3 mobile mockups render the three phone states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.step3MobileMockups,
        routes: AppRouter.routes,
      ),
    );
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

    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('변경됨'), findsOneWidget);
    expect(find.text('변경된 경로로 안내 시작'), findsOneWidget);
  });

  testWidgets('home route opens the first Step 3 screen and routes forward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(initialRoute: AppRoutes.home, routes: AppRouter.routes),
    );
    await tester.pumpAndSettle();

    expect(find.text('혼잡도 알림'), findsOneWidget);
    expect(find.text('대안 장소 추천'), findsNothing);
    expect(find.text('일정이 변경되었어요!'), findsNothing);

    await tester.tap(find.text('대안 장소 보기'));
    await tester.pumpAndSettle();

    expect(find.text('대안 장소 추천'), findsOneWidget);
    expect(find.text('혼잡도 알림'), findsNothing);
    expect(find.text('일정이 변경되었어요!'), findsNothing);

    await tester.tap(find.text('이 장소로 변경').first);
    await tester.pumpAndSettle();

    expect(find.text('일정이 변경되었어요!'), findsOneWidget);
    expect(find.text('혼잡도 알림'), findsNothing);
    expect(find.text('대안 장소 추천'), findsNothing);
  });
}
