import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/clients/mock_ai_client.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';

void main() {
  testWidgets('CultureScanScreen shows mock result after scanning', (
    tester,
  ) async {
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

    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(
      find.text('Tap Scan Culture to learn the meaning behind this place.'),
      findsOneWidget,
    );
    expect(find.text('Scan Culture'), findsOneWidget);

    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();

    expect(
      find.text('Reading the scene and preparing a local explanation...'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Each stone carries a wish.'), findsOneWidget);
    expect(find.text('Etiquette'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
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
