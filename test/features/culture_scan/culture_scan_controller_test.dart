import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/clients/mock_ai_client.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';

void main() {
  test(
    'CultureScanController handles camera fallback and scan result',
    () async {
      final controller = CultureScanController(
        cameraService: const _UnavailableCameraService(),
        harness: const CultureGuideHarness(client: MockAiClient()),
      );

      expect(controller.cameraStatus, CultureCameraStatus.initial);
      expect(controller.scanStatus, CultureScanStatus.initial);

      await controller.initializeCamera();

      expect(controller.cameraStatus, CultureCameraStatus.unavailable);
      expect(controller.hasCameraPreview, isFalse);
      expect(controller.friendlyMessage, contains('unavailable'));

      final scanFuture = controller.scanCulture();
      expect(controller.scanStatus, CultureScanStatus.scanning);
      await scanFuture;

      expect(controller.scanStatus, CultureScanStatus.result);
      expect(controller.guide?.title, 'AI Culture Guide');
      expect(controller.guide?.meaning, 'Each stone carries a wish.');

      controller.dispose();
    },
  );

  test(
    'CultureScanController ignores camera completion after dispose',
    () async {
      final controller = CultureScanController(
        cameraService: const _DelayedUnavailableCameraService(),
        harness: const CultureGuideHarness(client: MockAiClient()),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      final initializeFuture = controller.initializeCamera();
      expect(controller.cameraStatus, CultureCameraStatus.loading);
      expect(notifications, 1);

      controller.dispose();
      await initializeFuture;

      expect(notifications, 1);
    },
  );

  test('CultureScanController ignores scan completion after dispose', () async {
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      harness: const CultureGuideHarness(client: MockAiClient()),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    final scanFuture = controller.scanCulture();
    expect(controller.scanStatus, CultureScanStatus.scanning);
    expect(notifications, 1);

    controller.dispose();
    await scanFuture;

    expect(notifications, 1);
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

class _DelayedUnavailableCameraService implements CultureCameraService {
  const _DelayedUnavailableCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const CultureCameraSession(
      unavailableMessage: 'Camera preview is unavailable in tests.',
    );
  }
}
