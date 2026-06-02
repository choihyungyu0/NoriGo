import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';
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
    expect(find.text('Useful phrase appears after scan.'), findsOneWidget);
    expect(find.text('AI Culture Guide'), findsOneWidget);
    expect(find.text('Why do Koreans stack stones here?'), findsOneWidget);
    expect(find.text('Ready to scan'), findsOneWidget);
    expect(
      find.text('No camera detected. Showing guide preview.'),
      findsOneWidget,
    );
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
      detectedObject: 'temple_stone_stack',
      placeType: 'temple',
      confidence: 0.42,
      alternatives: [],
      needsConfirmation: true,
      sourceType: 'vision_heuristic',
      sourceBadge: 'Context hint',
    );
  }
}
