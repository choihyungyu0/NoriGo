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
