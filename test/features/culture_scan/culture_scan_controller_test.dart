import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

void main() {
  test(
    'CultureScanController handles camera fallback and scan result',
    () async {
      final controller = CultureScanController(
        cameraService: const _UnavailableCameraService(),
      );

      expect(controller.cameraStatus, CultureCameraStatus.initial);
      expect(controller.scanStatus, CultureScanStatus.idle);

      await controller.initializeCamera();

      expect(controller.cameraStatus, CultureCameraStatus.unavailable);
      expect(controller.scanStatus, CultureScanStatus.ready);
      expect(controller.hasCameraPreview, isFalse);
      expect(controller.friendlyMessage, contains('unavailable'));

      final scanFuture = controller.scanCulture();
      expect(controller.scanStatus, CultureScanStatus.scanning);
      await scanFuture;

      expect(controller.scanStatus, CultureScanStatus.localOnly);
      expect(controller.guide?.title, 'AI Culture Guide');
      expect(controller.guide?.meaning, contains('Stone stacks'));
      expect(controller.sourceBadge, 'Local guide');

      controller.dispose();
    },
  );

  test(
    'CultureScanController ignores camera completion after dispose',
    () async {
      final controller = CultureScanController(
        cameraService: const _DelayedUnavailableCameraService(),
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

  test(
    'CultureScanController accepts browser video preview fallback',
    () async {
      final controller = CultureScanController(
        cameraService: const _BrowserPreviewCameraService(),
      );

      await controller.initializeCamera();

      expect(controller.cameraStatus, CultureCameraStatus.ready);
      expect(controller.hasCameraPreview, isTrue);
      expect(controller.cameraPreview, isA<Widget>());
      expect(controller.friendlyMessage, isNull);

      controller.dispose();
    },
  );

  test('capture failure does not block culture guide call', () async {
    final repository = _RecordingCultureScanRepository();
    final controller = CultureScanController(
      cameraService: const _ThrowingCaptureCameraService(),
      repository: repository,
    );

    await controller.initializeCamera();
    await controller.scanCulture();

    expect(controller.scanStatus, CultureScanStatus.success);
    expect(repository.runCount, 1);
    expect(repository.lastRequest?.imagePath, isNull);

    controller.dispose();
  });

  test('capture upload path is sent with the culture guide request', () async {
    final repository = _RecordingCultureScanRepository(
      uploadResult: 'culture-scans/user-1/scan.jpg',
    );
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
    );

    await controller.initializeCamera();
    await controller.scanCulture();

    expect(repository.uploadCount, 1);
    expect(repository.lastRequest?.imagePath, 'culture-scans/user-1/scan.jpg');

    controller.dispose();
  });

  test('CultureScanController ignores scan completion after dispose', () async {
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
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

class _BrowserPreviewCameraService implements CultureCameraService {
  const _BrowserPreviewCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return const CultureCameraSession(preview: SizedBox.shrink());
  }
}

class _ThrowingCaptureCameraService implements CultureCameraService {
  const _ThrowingCaptureCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return CultureCameraSession(
      preview: const SizedBox.shrink(),
      capturePreview: () async => throw StateError('capture unavailable'),
    );
  }
}

class _CapturingCameraService implements CultureCameraService {
  const _CapturingCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return CultureCameraSession(
      preview: const SizedBox.shrink(),
      capturePreview: () async => CultureImageCapture(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        extension: 'jpg',
      ),
    );
  }
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

class _RecordingCultureScanRepository extends CultureScanRepository {
  _RecordingCultureScanRepository({this.uploadResult});

  final String? uploadResult;
  int runCount = 0;
  int uploadCount = 0;
  CultureScanRequest? lastRequest;

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    runCount++;
    lastRequest = request;
    return CultureGuideResult.fromJson({
      'question': 'What should I do here?',
      'description': 'A practical guide.',
      'meaning': 'Meaning.',
      'etiquette': 'Etiquette.',
      'story': 'Story.',
      'korean_phrase': '여기요',
      'source_type': 'culture_db_basic',
      'source_badge': 'Culture DB',
      'location_name': request.currentLocation,
      'place_type': request.placeType,
      'detected_object': request.detectedObject,
      'korean_keyword': request.koreanKeyword,
    });
  }

  @override
  Future<String?> uploadScanImage(CultureImageCapture capture) async {
    uploadCount++;
    return uploadResult;
  }
}
