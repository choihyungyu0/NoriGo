import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/clients/mock_ai_client.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';

void main() {
  testWidgets('CultureScanScreen renders the culture guide mock UI', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      harness: const CultureGuideHarness(client: MockAiClient()),
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
    expect(find.text('소원성취'), findsOneWidget);
    expect(find.text('Wishing for your hopes to come true.'), findsOneWidget);
    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(find.text('Why do Koreans stack stones here?'), findsOneWidget);
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
      harness: const CultureGuideHarness(client: MockAiClient()),
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
