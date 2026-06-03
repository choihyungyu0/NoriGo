import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';

void main() {
  testWidgets('CultureScanScreen keeps camera preview clear before scan', (
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
    expect(
      find.text('No camera detected. Showing guide preview.'),
      findsOneWidget,
    );
    expect(find.text('소원 성취'), findsNothing);
    expect(find.text('AI Culture Guide'), findsNothing);
    expect(find.text('Why do Koreans stack stones here?'), findsNothing);
    expect(find.text('Ready to scan'), findsNothing);
    expect(find.text('Meaning'), findsNothing);
    expect(find.text('Etiquette'), findsNothing);
    expect(find.text('Story'), findsNothing);
    expect(find.text('English'), findsOneWidget);
    expect(find.byKey(const ValueKey('flashToggleIconButton')), findsOneWidget);
    expect(find.text('AR View'), findsNothing);
    expect(find.text('Flash On'), findsNothing);
    expect(find.text('Flash Off'), findsNothing);
    expect(find.text('Scan Culture'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-nav-Scan')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('real camera preview does not show fallback camera message', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _PreviewCameraService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('camera-preview')), findsOneWidget);
    expect(
      find.text('No camera detected. Showing guide preview.'),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('CultureScanScreen shows flash unavailable message', (
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

    expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('flashToggleIconButton')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
    expect(find.text('Flash is not available on this device.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('guide pill requires manual context before running guide', (
    tester,
  ) async {
    _setScanSurface(tester);
    final repository = _NoMatchVisionRepository();
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      repository: repository,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('guidePill')));
    await tester.pumpAndSettle();

    expect(find.text('Scan context'), findsOneWidget);
    expect(repository.runCount, 0);
    expect(find.text('AI Culture Guide'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('runCultureGuideFromSheetButton')),
    );
    await tester.pumpAndSettle();

    expect(repository.runCount, 1);
    expect(repository.lastRequest?.detectedObjectSource, 'manual');
    expect(find.text('Local guide'), findsOneWidget);
    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('vision confirmation can change into context sheet and scan', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      repository: const _ConfirmationVisionRepository(),
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

    expect(find.text('I found this situation'), findsOneWidget);
    expect(find.text('Temple stone stack'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Scan context'), findsOneWidget);
    expect(find.text('Temple'), findsOneWidget);
    expect(find.text('Stone stack'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('runCultureGuideFromSheetButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local guide'), findsOneWidget);
    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Etiquette'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('low vision confidence opens manual context immediately', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      repository: const _LowConfidenceVisionRepository(),
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

    expect(find.text('I found this situation'), findsNothing);
    expect(find.text('Scan context'), findsOneWidget);
    expect(find.text('Stone stack'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'unsupported scan requires manual selection before culture guide runs',
    (tester) async {
      _setScanSurface(tester);
      final repository = _NoMatchVisionRepository();
      final controller = CultureScanController(
        cameraService: const _UnavailableCameraService(),
        repository: repository,
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

      expect(
        find.text(
          'I couldn’t identify a supported travel situation. Please choose the closest situation.',
        ),
        findsOneWidget,
      );
      expect(find.text('Scan context'), findsOneWidget);
      expect(repository.runCount, 0);
      expect(repository.lastRequest, isNull);

      await tester.tap(
        find.byKey(const ValueKey('runCultureGuideFromSheetButton')),
      );
      await tester.pumpAndSettle();

      expect(repository.runCount, 1);
      expect(repository.lastRequest?.detectedObjectSource, 'manual');
      expect(repository.lastRequest?.detectedObject, isNot('unsupported'));

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('custom call bell confidence 0.85 triggers confirmation', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: _NoMatchVisionRepository(),
      callBellClassifier: _FixedCustomCallBellClassifier(
        _customCallBellResult(0.85),
      ),
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

    expect(find.text('I found a restaurant call bell'), findsOneWidget);
    expect(find.text('Restaurant call bell'), findsOneWidget);
    expect(find.textContaining('confidence 85%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('custom call bell confidence 0.65 uses low-confidence copy', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: _NoMatchVisionRepository(),
      callBellClassifier: _FixedCustomCallBellClassifier(
        _customCallBellResult(0.65),
      ),
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

    expect(
      find.text('This may be a restaurant call bell. Is that right?'),
      findsOneWidget,
    );
    expect(find.textContaining('confidence 65%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('custom call bell confidence 0.40 opens manual selection', (
    tester,
  ) async {
    _setScanSurface(tester);
    final repository = _NoMatchVisionRepository();
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
      callBellClassifier: _FixedCustomCallBellClassifier(
        CultureVisionResult.noMatch(
          const CultureVisionRequest(
            currentLocation: 'Korean restaurant',
            userLanguage: 'English',
            hintPlaceType: 'restaurant',
          ),
        ),
      ),
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

    expect(find.text('I found a restaurant call bell'), findsNothing);
    expect(find.text('Scan context'), findsOneWidget);
    expect(repository.runCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('rejected custom call bell result opens manual selection', (
    tester,
  ) async {
    _setScanSurface(tester);
    final repository = _NoMatchVisionRepository();
    final controller = CultureScanController(
      cameraService: const _CapturingCameraService(),
      repository: repository,
      callBellClassifier: _FixedCustomCallBellClassifier(
        _customCallBellResult(0.86),
      ),
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
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Scan context'), findsOneWidget);
    expect(repository.runCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'confirmed custom call bell result sends call bell guide request',
    (tester) async {
      _setScanSurface(tester);
      final repository = _NoMatchVisionRepository();
      final controller = CultureScanController(
        cameraService: const _CapturingCameraService(),
        repository: repository,
        callBellClassifier: _FixedCustomCallBellClassifier(
          _customCallBellResult(0.85),
        ),
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
      await tester.tap(find.byKey(const ValueKey('useVisionCandidateButton')));
      await tester.pumpAndSettle();

      expect(repository.runCount, 1);
      expect(repository.lastRequest?.detectedObject, 'restaurant_call_bell');
      expect(
        repository.lastRequest?.detectedObjectSource,
        'mlkit_custom_call_bell_confirmed',
      );
      expect(repository.lastRequest?.visionConfidence, 0.85);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('result screen shows Vision AI badge with guide source', (
    tester,
  ) async {
    _setScanSurface(tester);
    final controller = CultureScanController(
      cameraService: const _UnavailableCameraService(),
      repository: const _VisionBadgeRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NoriGoTheme.light(),
        home: CultureScanScreen(controller: controller),
      ),
    );
    await tester.pump();

    await controller.runCultureGuide(
      CultureScanRequest.defaultTemple().copyWith(
        detectedObjectSource: 'vision_confirmed',
        visionConfidence: 0.84,
        visionSourceType: 'vision_ai',
        visionSourceBadge: 'Vision AI',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guidePill')));
    await tester.pumpAndSettle();

    expect(find.text('Vision AI · Culture DB + ennoia'), findsOneWidget);

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
      unavailableMessage: 'No camera detected. Showing guide preview.',
    );
  }
}

class _PreviewCameraService implements CultureCameraService {
  const _PreviewCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return const CultureCameraSession(
      preview: SizedBox(key: ValueKey('camera-preview')),
    );
  }
}

class _CapturingCameraService implements CultureCameraService {
  const _CapturingCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return CultureCameraSession(
      preview: const SizedBox(key: ValueKey('camera-preview')),
      capturePreview: () async => CultureImageCapture(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        extension: 'jpg',
        filePath: 'call-bell-scan.jpg',
      ),
    );
  }
}

class _VisionBadgeRepository extends CultureScanRepository {
  const _VisionBadgeRepository();

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    return CultureGuideResult.fromJson({
      'question': 'Why do people stack stones?',
      'description': 'A practical guide.',
      'meaning': 'Meaning.',
      'etiquette': 'Etiquette.',
      'story': 'Story.',
      'korean_phrase': '소원 성취하세요',
      'source_type': 'culture_db_ennoia',
      'source_badge': 'Culture DB + ennoia',
      'ennoia_succeeded': true,
      'location_name': request.currentLocation,
      'place_type': request.placeType,
      'detected_object': request.detectedObject,
      'korean_keyword': request.koreanKeyword,
      'detected_object_source': request.detectedObjectSource,
      'vision_confidence': request.visionConfidence,
      'vision_source_type': request.visionSourceType,
      'vision_source_badge': request.visionSourceBadge,
    });
  }
}

class _FixedCustomCallBellClassifier extends CultureVisionClassifier {
  const _FixedCustomCallBellClassifier(this.result);

  final CultureVisionResult result;

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return result;
  }
}

CultureVisionResult _customCallBellResult(double confidence) {
  return CultureVisionResult(
    detectedObject: 'restaurant_call_bell',
    placeType: 'restaurant',
    confidence: confidence,
    alternatives: [
      CultureVisionAlternative(
        detectedObject: 'restaurant_call_bell',
        placeType: 'restaurant',
        label: 'Restaurant call bell',
        confidence: confidence,
      ),
    ],
    needsConfirmation: true,
    sourceType: 'vision_ai',
    sourceBadge: 'Custom call bell',
    detectedObjectSource: 'mlkit_custom_call_bell',
    finalDecision: confidence >= 0.8
        ? 'auto_confirm_possible'
        : 'needs_confirmation',
  );
}

class _ConfirmationVisionRepository extends CultureScanRepository {
  const _ConfirmationVisionRepository();

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    return CultureGuideResult.localDemo(request);
  }

  @override
  Future<CultureVisionResult> detectCultureObject(
    CultureVisionRequest request,
  ) async {
    return const CultureVisionResult(
      detectedObject: 'temple_stone_stack',
      placeType: 'temple',
      confidence: 0.82,
      alternatives: [],
      needsConfirmation: true,
      sourceType: 'vision_ai',
      sourceBadge: 'Vision AI',
      detectedObjectSource: 'mlkit_auto',
      finalDecision: 'auto_confirm_possible',
    );
  }
}

class _LowConfidenceVisionRepository extends CultureScanRepository {
  const _LowConfidenceVisionRepository();

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    return CultureGuideResult.localDemo(request);
  }

  @override
  Future<CultureVisionResult> detectCultureObject(
    CultureVisionRequest request,
  ) async {
    return const CultureVisionResult(
      detectedObject: 'kiosk_ordering',
      placeType: 'restaurant',
      confidence: 0.42,
      alternatives: [],
      needsConfirmation: true,
      sourceType: 'vision_ai',
      sourceBadge: 'Vision AI',
      detectedObjectSource: 'mlkit_suggested',
      finalDecision: 'manual_required',
    );
  }
}

class _NoMatchVisionRepository extends CultureScanRepository {
  int runCount = 0;
  CultureScanRequest? lastRequest;

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    runCount++;
    lastRequest = request;
    return CultureGuideResult.localDemo(request);
  }

  @override
  Future<CultureVisionResult> detectCultureObject(
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
