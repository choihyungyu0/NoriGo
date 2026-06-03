import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

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
      uploadResult: 'user-1/scan.jpg',
    );
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
    );

    await controller.initializeCamera();
    await controller.scanCulture();

    expect(repository.uploadCount, 1);
    expect(repository.lastRequest?.imagePath, 'user-1/scan.jpg');

    controller.dispose();
  });

  test('image upload failure does not block culture guide call', () async {
    final repository = _RecordingCultureScanRepository(uploadResult: null);
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
    );

    await controller.initializeCamera();
    await controller.scanCulture();

    expect(repository.uploadCount, 1);
    expect(repository.runCount, 1);
    expect(repository.lastRequest?.imagePath, isNull);

    controller.dispose();
  });

  test('vision-confirmed object is sent to culture guide request', () async {
    final repository = _RecordingCultureScanRepository(
      uploadResult: 'user-1/scan.jpg',
      visionResult: const CultureVisionResult(
        detectedObject: 'restaurant_call_bell',
        placeType: 'restaurant',
        confidence: 0.88,
        alternatives: [
          CultureVisionAlternative(
            detectedObject: 'restaurant_call_bell',
            placeType: 'restaurant',
            label: 'Restaurant call bell',
            confidence: 0.88,
          ),
        ],
        needsConfirmation: true,
        sourceType: 'vision_ai',
        sourceBadge: 'Vision AI',
      ),
    );
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
    );

    await controller.initializeCamera();
    final draft = await controller.prepareVisionScan(controller.defaultRequest);
    await controller.runCultureGuide(
      draft.visionResult.toCultureScanRequest(
        base: controller.defaultRequest,
        imagePath: draft.imagePath,
        detectedObjectSource: 'vision_confirmed',
      ),
    );

    expect(repository.detectCount, 1);
    expect(repository.lastRequest?.detectedObject, 'restaurant_call_bell');
    expect(repository.lastRequest?.detectedObjectSource, 'vision_confirmed');
    expect(repository.lastRequest?.visionConfidence, 0.88);
    expect(repository.lastRequest?.imagePath, 'user-1/scan.jpg');

    controller.dispose();
  });

  test(
    'local ML Kit classifier result is used before server vision detect',
    () async {
      final repository = _RecordingCultureScanRepository(
        uploadResult: 'user-1/scan.jpg',
      );
      final controller = CultureScanController(
        cameraService: const _CapturingCameraService(),
        repository: repository,
        visionClassifier: const _FakeLocalVisionClassifier(),
      );

      await controller.initializeCamera();
      final draft = await controller.prepareVisionScan(
        controller.defaultRequest,
      );

      expect(draft.visionResult.detectedObject, 'kiosk_ordering');
      expect(draft.visionResult.sourceType, 'vision_ai');
      expect(repository.detectCount, 0);

      controller.dispose();
    },
  );

  test(
    'unsupported local labels require manual selection and keep diagnostics',
    () async {
      final repository = _RecordingCultureScanRepository(
        uploadResult: 'user-1/tissue.jpg',
      );
      final controller = CultureScanController(
        cameraService: const _CapturingCameraService(),
        repository: repository,
        visionClassifier: const _NoMatchLocalVisionClassifier(),
      );

      await controller.initializeCamera();
      final draft = await controller.prepareVisionScan(
        controller.defaultRequest,
      );

      expect(draft.visionResult.detectedObject, 'unsupported');
      expect(draft.visionResult.detectedObjectSource, 'no_match');
      expect(draft.visionResult.finalDecision, 'manual_required');
      expect(draft.visionResult.requiresManualSelection, isTrue);
      expect(repository.detectCount, 0);
      expect(repository.runCount, 0);
      expect(
        controller.lastVisionDiagnostics?['detected_object_source'],
        'no_match',
      );
      expect(
        controller.lastVisionDiagnostics?['raw_labels'].toString(),
        contains('Tissue'),
      );

      controller.dispose();
    },
  );

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
  _RecordingCultureScanRepository({this.uploadResult, this.visionResult});

  final String? uploadResult;
  final CultureVisionResult? visionResult;
  int runCount = 0;
  int uploadCount = 0;
  int detectCount = 0;
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
      'detected_object_source': request.detectedObjectSource,
      'vision_confidence': request.visionConfidence,
      'vision_source_badge': request.visionSourceBadge,
      'image_path': request.imagePath,
    });
  }

  @override
  Future<String?> uploadScanImage(CultureImageCapture capture) async {
    uploadCount++;
    return uploadResult;
  }

  @override
  Future<CultureVisionResult> detectCultureObject(
    CultureVisionRequest request,
  ) async {
    detectCount++;
    return visionResult ?? await super.detectCultureObject(request);
  }
}

class _FakeLocalVisionClassifier extends CultureVisionClassifier {
  const _FakeLocalVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return const CultureVisionResult(
      detectedObject: 'kiosk_ordering',
      placeType: 'restaurant',
      confidence: 0.81,
      alternatives: [
        CultureVisionAlternative(
          detectedObject: 'kiosk_ordering',
          placeType: 'restaurant',
          label: 'Kiosk ordering',
          confidence: 0.81,
        ),
      ],
      needsConfirmation: false,
      sourceType: 'vision_ai',
      sourceBadge: 'Vision AI',
      detectedObjectSource: 'mlkit_auto',
      finalDecision: 'auto_confirm_possible',
    );
  }
}

class _NoMatchLocalVisionClassifier extends CultureVisionClassifier {
  const _NoMatchLocalVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return CultureVisionResult.noMatch(
      request,
      rawLabels: const [
        CultureVisionLabelDiagnostic(label: 'Tissue', confidence: 0.91),
        CultureVisionLabelDiagnostic(label: 'Paper', confidence: 0.87),
      ],
    );
  }
}
