import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';

void main() {
  testWidgets('CultureScanScreen renders source badge and guide sections', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Bulguksa'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('소원 성취'), findsOneWidget);
    expect(find.text('May your wish come true.'), findsOneWidget);
    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(find.text('Why do Koreans stack stones here?'), findsOneWidget);
    expect(find.text('Demo fallback'), findsOneWidget);
    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Etiquette'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Flash Off'), findsOneWidget);
    expect(find.text('Scan Culture'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-nav-Scan')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('CultureScanScreen toggles flash state locally', (tester) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Flash Off'), findsOneWidget);

    await tester.tapAt(const Offset(350, 790));
    await tester.pump();

    expect(find.text('Flash On'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('culture guide refresh falls back when Supabase is missing', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('runEnnoiaCultureGuideButton')));
    await tester.pumpAndSettle();

    expect(find.text('Demo fallback'), findsOneWidget);
    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('context sheet runs scan and keeps web fallback stable', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('scanCultureButton')));
    await tester.pumpAndSettle();

    expect(find.text('Scan context'), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);
    expect(find.text('Stone stack'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('runCultureGuideFromSheetButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo fallback'), findsOneWidget);
    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Etiquette'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

void _setScanSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _UnavailableCameraService implements CultureCameraService {
  const _UnavailableCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return const CultureCameraSession(
      unavailableMessage: 'Camera preview is unavailable in tests.',
    );
  }
}
