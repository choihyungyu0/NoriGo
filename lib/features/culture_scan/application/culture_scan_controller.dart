import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/features/culture_scan/application/call_bell_custom_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_capture_quality.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_mlkit_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/data/supabase_culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';
import 'package:norigo/features/culture_scan/domain/vision_debug_report.dart';

enum CultureCameraStatus { initial, loading, ready, unavailable }

enum CultureScanStatus {
  idle,
  cameraInitializing,
  ready,
  scanning,
  success,
  error,
  localOnly,
}

class CultureScanController extends ChangeNotifier {
  CultureScanController({
    required CultureCameraService cameraService,
    CultureScanRepository repository = const SupabaseCultureScanRepository(),
    CultureVisionClassifier callBellClassifier =
        const CallBellCustomClassifier(),
    CultureVisionClassifier visionClassifier =
        const MlKitCultureVisionClassifier(),
    CultureCaptureQualityAnalyzer captureQualityAnalyzer =
        const DefaultCultureCaptureQualityAnalyzer(),
    CultureGuideHarness? harness,
    CultureScanRequest? initialRequest,
  }) : _cameraService = cameraService,
       _repository = repository,
       _callBellClassifier = callBellClassifier,
       _visionClassifier = visionClassifier,
       _captureQualityAnalyzer = captureQualityAnalyzer,
       _baseRequest =
           initialRequest ??
           CultureScanRequest.defaultTemple(
             userLanguage: AppLocaleController.currentUserLanguage,
           ) {
    _selectedLanguage = _baseRequest.userLanguage;
  }

  final CultureCameraService _cameraService;
  final CultureScanRepository _repository;
  final CultureVisionClassifier _callBellClassifier;
  final CultureVisionClassifier _visionClassifier;
  final CultureCaptureQualityAnalyzer _captureQualityAnalyzer;
  final CultureScanRequest _baseRequest;

  CultureCameraSession? _cameraSession;
  CultureGuideResult? _result;
  CultureCameraStatus _cameraStatus = CultureCameraStatus.initial;
  CultureScanStatus _scanStatus = CultureScanStatus.idle;
  String _selectedLanguage = 'English';
  String? _friendlyMessage;
  bool _flashEnabled = false;
  bool _disposed = false;
  Map<String, Object?>? _lastVisionDiagnostics;
  VisionDebugReport? _lastVisionDebugReport;
  Uint8List? _lastVisionDebugThumbnailBytes;
  double _visionDebugSuggestThreshold = callBellSuggestThreshold;

  CultureCameraStatus get cameraStatus => _cameraStatus;

  CultureScanStatus get scanStatus => _scanStatus;

  String get selectedLanguage => _selectedLanguage;

  String? get friendlyMessage => _friendlyMessage;

  String get ennoiaSourceLabel => sourceBadge;

  String get sourceBadge => _result?.displaySourceBadge ?? 'Ready to scan';

  String get sourceType => _result?.sourceType ?? 'culture_ready';

  bool get isRunningEnnoia => _scanStatus == CultureScanStatus.scanning;

  bool get flashEnabled => _flashEnabled;

  CultureGuideResult? get result => _result;

  CultureGuide? get guide => _result?.toCultureGuide();

  Map<String, Object?>? get lastVisionDiagnostics => _lastVisionDiagnostics;

  VisionDebugReport? get lastVisionDebugReport => _lastVisionDebugReport;

  Uint8List? get lastVisionDebugThumbnailBytes =>
      _lastVisionDebugThumbnailBytes;

  double get visionDebugSuggestThreshold => _visionDebugSuggestThreshold;

  CameraController? get cameraController => _cameraSession?.controller;

  Widget? get cameraPreview => _cameraSession?.preview;

  bool get hasCameraPreview => _cameraSession?.hasPreview ?? false;

  CultureScanRequest get defaultRequest {
    return _baseRequest.copyWith(userLanguage: _selectedLanguage);
  }

  void updateVisionDebugSuggestThreshold(double threshold) {
    if (_disposed) return;
    _visionDebugSuggestThreshold = threshold.clamp(0.1, 0.95).toDouble();
    _safeNotifyListeners();
  }

  Future<void> initializeCamera() async {
    if (_disposed) return;

    _cameraStatus = CultureCameraStatus.loading;
    _scanStatus = CultureScanStatus.cameraInitializing;
    _friendlyMessage = null;
    _safeNotifyListeners();

    try {
      final session = await _cameraService.initialize();
      if (_disposed) {
        await session.dispose();
        return;
      }

      _cameraSession = session;
      _cameraStatus = session.hasPreview
          ? CultureCameraStatus.ready
          : CultureCameraStatus.unavailable;
      _scanStatus = CultureScanStatus.ready;
      _friendlyMessage = session.unavailableMessage;
      _safeNotifyListeners();
    } catch (error) {
      if (_disposed) return;
      developer.log(
        'Camera initialization failed.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _cameraStatus = CultureCameraStatus.unavailable;
      _scanStatus = CultureScanStatus.ready;
      _friendlyMessage =
          'Camera preview is unavailable here. NoriGo is showing a safe preview background.';
      _safeNotifyListeners();
    }
  }

  void updateLanguage(String language) {
    if (_disposed) return;
    if (language.trim().isEmpty) return;
    _selectedLanguage = language.trim();
    _safeNotifyListeners();
  }

  Future<bool> toggleFlash() async {
    if (_disposed) return false;

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _flashEnabled = false;
      _safeNotifyListeners();
      return false;
    }

    try {
      final nextFlashState = !_flashEnabled;
      await controller.setFlashMode(
        nextFlashState ? FlashMode.torch : FlashMode.off,
      );
      _flashEnabled = nextFlashState;
      _safeNotifyListeners();
      return true;
    } catch (error) {
      if (_disposed) return false;
      developer.log(
        'Flash mode unavailable.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _flashEnabled = false;
      _friendlyMessage = 'Flash is unavailable on this device.';
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> scanCulture() {
    return runCultureGuide(defaultRequest);
  }

  Future<void> runEnnoiaCultureGuide() {
    return runCultureGuide(defaultRequest);
  }

  Future<void> runCultureGuide(CultureScanRequest request) async {
    if (_disposed) return;

    var effectiveRequest = request.copyWith(userLanguage: _selectedLanguage);
    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    _safeNotifyListeners();

    try {
      final imagePath = effectiveRequest.imagePath?.trim().isNotEmpty == true
          ? effectiveRequest.imagePath
          : await _captureAndUploadScanImage();
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        effectiveRequest = effectiveRequest.copyWith(imagePath: imagePath);
      }
      final result = await _repository.runCultureGuide(effectiveRequest);
      if (_disposed) return;
      _result = result;
      _scanStatus = result.isLocalFallback
          ? CultureScanStatus.localOnly
          : CultureScanStatus.success;
      if (result.isLocalFallback) {
        _friendlyMessage =
            'Culture Guide is not connected yet, so NoriGo is showing a local guide.';
      }
    } catch (error) {
      if (_disposed) return;
      developer.log(
        'Culture guide request failed.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _result = CultureGuideResult.localDemo(effectiveRequest);
      _scanStatus = CultureScanStatus.error;
      _friendlyMessage =
          'NoriGo could not reach Culture Guide, so it is showing a local guide.';
    }

    _safeNotifyListeners();
  }

  Future<CultureVisionScanDraft> prepareVisionScan(
    CultureScanRequest request,
  ) async {
    final effectiveRequest = request.copyWith(userLanguage: _selectedLanguage);
    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    _result = null;
    _lastVisionDiagnostics = null;
    _lastVisionDebugReport = null;
    _lastVisionDebugThumbnailBytes = null;
    _safeNotifyListeners();

    String? imagePath;
    CultureImageCapture? capture;
    CultureVisionResult visionResult;
    try {
      capture = await _captureScanImage();
      final baseVisionRequest = CultureVisionRequest(
        imagePath: null,
        currentLocation: effectiveRequest.currentLocation,
        userLanguage: effectiveRequest.userLanguage,
        hintPlaceType: effectiveRequest.placeType,
      );
      if (capture == null || capture.isEmpty) {
        visionResult = CultureVisionResult.noMatch(baseVisionRequest);
        _lastVisionDebugReport = await _buildVisionDebugReport(
          capture: null,
          request: baseVisionRequest,
          result: visionResult,
          finalDecision: 'capture_failed',
          errorMessage: 'Camera capture returned no image bytes.',
        );
      } else {
        _lastVisionDebugThumbnailBytes = capture.bytes;
        final captureQuality = await _captureQualityAnalyzer.analyze(capture);
        if (!captureQuality.isUsable) {
          developer.log(
            'Culture vision skipped because the capture was too dark or blank. '
            '${_qualityDetails(captureQuality)}',
            name: 'CultureScanController',
          );
          visionResult = CultureVisionResult.noMatch(baseVisionRequest);
          _lastVisionDebugReport = await _buildVisionDebugReport(
            capture: capture,
            request: baseVisionRequest,
            result: visionResult,
            captureQuality: captureQuality,
            finalDecision: 'capture_too_dark_or_blank',
            errorMessage:
                'Capture was too dark or blank: '
                '${_qualityDetails(captureQuality)}',
          );
        } else {
          imagePath = await _uploadScanImage(capture);
          final visionRequest = CultureVisionRequest(
            imagePath: imagePath,
            currentLocation: effectiveRequest.currentLocation,
            userLanguage: effectiveRequest.userLanguage,
            hintPlaceType: effectiveRequest.placeType,
          );
          visionResult = await _classifyCultureObject(
            capture,
            visionRequest,
            captureQuality,
          );
        }
      }
      _recordVisionDiagnostics(visionResult);
    } catch (error) {
      developer.log(
        'Culture vision detection skipped.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      final fallbackRequest = CultureVisionRequest(
        imagePath: imagePath,
        currentLocation: effectiveRequest.currentLocation,
        userLanguage: effectiveRequest.userLanguage,
        hintPlaceType: effectiveRequest.placeType,
      );
      visionResult = CultureVisionResult.noMatch(fallbackRequest);
      _lastVisionDebugReport = await _buildVisionDebugReport(
        capture: capture,
        request: fallbackRequest,
        result: visionResult,
        finalDecision: 'error',
        errorMessage: error.runtimeType.toString(),
      );
      _recordVisionDiagnostics(visionResult);
    }

    if (!_disposed) {
      _scanStatus = CultureScanStatus.ready;
      _safeNotifyListeners();
    }
    return CultureVisionScanDraft(
      imagePath: imagePath,
      visionResult: visionResult,
    );
  }

  Future<String?> _captureAndUploadScanImage() async {
    try {
      return await _uploadScanImage(await _captureScanImage());
    } catch (error) {
      developer.log(
        'Culture scan image capture/upload skipped.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      return null;
    }
  }

  Future<CultureImageCapture?> _captureScanImage() async {
    final capture = await _cameraSession?.captureStill();
    if (capture == null || capture.isEmpty) return null;
    return capture;
  }

  Future<String?> _uploadScanImage(CultureImageCapture? capture) async {
    if (capture == null || capture.isEmpty) return null;
    return _repository
        .uploadScanImage(capture)
        .timeout(const Duration(seconds: 12), onTimeout: () => null);
  }

  Future<CultureVisionResult> _classifyCultureObject(
    CultureImageCapture capture,
    CultureVisionRequest request,
    CultureCaptureQuality captureQuality,
  ) async {
    CultureVisionResult? localNoMatch;
    CultureVisionClassifierDebugResult? customDebug;
    CultureVisionClassifierDebugResult? baseDebug;
    try {
      final callBellResult = await _classifyWithOptionalDebug(
        classifier: _callBellClassifier,
        capture: capture,
        request: request,
        suggestThreshold: _visionDebugSuggestThreshold,
        onDebug: (debug) => customDebug = debug,
      );
      if (callBellResult != null) {
        if (!_isNoMatchVisionResult(callBellResult)) {
          _lastVisionDebugReport = await _buildVisionDebugReport(
            capture: capture,
            request: request,
            result: callBellResult,
            customDebug: customDebug,
            captureQuality: captureQuality,
            finalDecision: _finalDecisionForResult(
              callBellResult,
              customDebug?.finalDecision,
            ),
          );
          return callBellResult;
        }
        localNoMatch = callBellResult;
      }
    } catch (error) {
      developer.log(
        'Custom call bell classifier skipped.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
    }
    try {
      final localResult = await _classifyWithOptionalDebug(
        classifier: _visionClassifier,
        capture: capture,
        request: request,
        onDebug: (debug) => baseDebug = debug,
      );
      if (localResult != null) {
        if (!_isNoMatchVisionResult(localResult)) {
          _lastVisionDebugReport = await _buildVisionDebugReport(
            capture: capture,
            request: request,
            result: localResult,
            customDebug: customDebug,
            baseDebug: baseDebug,
            captureQuality: captureQuality,
            finalDecision: _finalDecisionForResult(
              localResult,
              baseDebug?.finalDecision,
            ),
          );
          return localResult;
        }
        localNoMatch ??= localResult;
      }
    } catch (error) {
      developer.log(
        'Local ML Kit culture vision skipped.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
    }
    final remoteResult = await _repository
        .detectCultureObject(request)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => localNoMatch ?? CultureVisionResult.noMatch(request),
        );
    if (_isNoMatchVisionResult(remoteResult)) {
      final result = localNoMatch ?? remoteResult;
      _lastVisionDebugReport = await _buildVisionDebugReport(
        capture: capture,
        request: request,
        result: result,
        customDebug: customDebug,
        baseDebug: baseDebug,
        serverResult: remoteResult,
        captureQuality: captureQuality,
        finalDecision: _finalDecisionForNoMatch(
          customDebug: customDebug,
          baseDebug: baseDebug,
        ),
      );
      return result;
    }
    if (_isContextOnlyVisionResult(remoteResult)) {
      final result = localNoMatch ?? CultureVisionResult.noMatch(request);
      _lastVisionDebugReport = await _buildVisionDebugReport(
        capture: capture,
        request: request,
        result: result,
        customDebug: customDebug,
        baseDebug: baseDebug,
        serverResult: remoteResult,
        captureQuality: captureQuality,
        finalDecision: _finalDecisionForNoMatch(
          customDebug: customDebug,
          baseDebug: baseDebug,
        ),
      );
      return result;
    }
    _lastVisionDebugReport = await _buildVisionDebugReport(
      capture: capture,
      request: request,
      result: remoteResult,
      customDebug: customDebug,
      baseDebug: baseDebug,
      serverResult: remoteResult,
      captureQuality: captureQuality,
      finalDecision: _finalDecisionForResult(remoteResult, null),
    );
    return remoteResult;
  }

  Future<CultureVisionResult?> _classifyWithOptionalDebug({
    required CultureVisionClassifier classifier,
    required CultureImageCapture capture,
    required CultureVisionRequest request,
    double? suggestThreshold,
    required ValueChanged<CultureVisionClassifierDebugResult> onDebug,
  }) async {
    final debugProbe = classifier;
    if (debugProbe is CultureVisionDebugProbe) {
      final debug = await (debugProbe as CultureVisionDebugProbe)
          .classifyForDebug(
            capture,
            request,
            suggestThreshold: suggestThreshold,
          );
      onDebug(debug);
      return debug.result;
    }
    return classifier.classify(capture, request);
  }

  bool _isNoMatchVisionResult(CultureVisionResult result) {
    return result.detectedObjectSource == 'no_match' ||
        result.sourceType == 'vision_no_match' ||
        result.detectedObject == 'unsupported';
  }

  Future<VisionDebugReport> _buildVisionDebugReport({
    required CultureImageCapture? capture,
    required CultureVisionRequest request,
    required CultureVisionResult result,
    CultureVisionClassifierDebugResult? customDebug,
    CultureVisionClassifierDebugResult? baseDebug,
    CultureVisionResult? serverResult,
    CultureCaptureQuality? captureQuality,
    required String finalDecision,
    String? errorMessage,
  }) async {
    final imageSize = await _decodeImageSize(capture);
    final report = VisionDebugReport(
      createdAt: DateTime.now().toUtc(),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      cameraMode: _cameraModeFor(capture),
      customModelExpectedPath:
          customDebug?.expectedModelPath ?? callBellModelAssetPath,
      customModelLoaded: customDebug?.modelLoaded ?? false,
      labelsFileLoaded: customDebug?.labelsFileLoaded ?? false,
      modelVersionOrHash: customDebug?.modelVersionOrHash,
      captureSucceeded: capture != null && !capture.isEmpty,
      capturedImagePath: _safeBasename(capture?.filePath),
      capturedImageWidth: imageSize?.width,
      capturedImageHeight: imageSize?.height,
      capturedImageFileSizeBytes: capture?.bytes.length,
      capturedImageRotation: 0,
      capturedImageSource: capture?.filePath?.trim().isNotEmpty == true
          ? 'raw_camera_xfile'
          : capture == null
          ? null
          : 'browser_canvas_or_memory',
      captureMeanLuma: captureQuality?.meanLuma,
      captureLumaStdDev: captureQuality?.lumaStdDev,
      captureLumaRange: captureQuality?.lumaRange,
      captureLumaP50: captureQuality?.lumaP50,
      captureLumaP90: captureQuality?.lumaP90,
      captureNearBlackRatio: captureQuality?.nearBlackRatio,
      captureDimRatio: captureQuality?.dimRatio,
      captureBrightRatio: captureQuality?.brightRatio,
      customLabels: _debugLabels(customDebug?.labels ?? const []),
      baseLabels: _debugLabels(baseDebug?.labels ?? const []),
      serverVisionResult: serverResult?.toJson(),
      mappedDetectedObject: result.detectedObject,
      mappedPlaceType: result.placeType,
      detectedObjectSource: result.detectedObjectSource,
      visionConfidence: result.confidence,
      thresholdAuto: callBellAutoThreshold,
      thresholdSuggest: _visionDebugSuggestThreshold,
      finalDecision: finalDecision,
      errorMessage: errorMessage ?? customDebug?.errorMessage,
    );
    _logVisionReport(report);
    return report;
  }

  String _finalDecisionForResult(
    CultureVisionResult result,
    String? debugDecision,
  ) {
    if (_isNoMatchVisionResult(result)) {
      return debugDecision ?? 'manual_required';
    }
    if (result.finalDecision == 'needs_confirmation' ||
        debugDecision == 'needs_confirmation') {
      return 'needs_confirmation';
    }
    return 'confirmed';
  }

  String _finalDecisionForNoMatch({
    CultureVisionClassifierDebugResult? customDebug,
    CultureVisionClassifierDebugResult? baseDebug,
  }) {
    final decisions = [
      customDebug?.finalDecision,
      baseDebug?.finalDecision,
    ].whereType<String>().toList(growable: false);
    if (decisions.contains('model_missing')) return 'model_missing';
    if (decisions.contains('confidence_too_low')) {
      return 'confidence_too_low';
    }
    if (decisions.contains('no_allowlist_match')) {
      return 'no_allowlist_match';
    }
    if (decisions.contains('no_labels')) return 'no_labels';
    if (decisions.contains('error')) return 'error';
    return 'manual_required';
  }

  Future<({int width, int height})?> _decodeImageSize(
    CultureImageCapture? capture,
  ) async {
    if (capture == null || capture.isEmpty) return null;
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(capture.bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      return (width: image.width, height: image.height);
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  List<VisionDebugLabel> _debugLabels(List<CultureVisionObservedLabel> labels) {
    return labels
        .map(
          (label) => VisionDebugLabel(
            text: label.label,
            index: label.index,
            confidence: label.confidence.clamp(0, 1).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  String _cameraModeFor(CultureImageCapture? capture) {
    if (capture == null || capture.isEmpty) return 'none';
    return capture.filePath?.trim().isNotEmpty == true
        ? 'camera_plugin_xfile'
        : 'memory_capture';
  }

  String? _safeBasename(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.replaceAll('\\', '/').split('/').last;
  }

  void _logVisionReport(VisionDebugReport report) {
    developer.log(
      'model_loaded=${report.customModelLoaded} '
      'image=${report.capturedImagePath ?? 'none'} '
      'size=${report.capturedImageWidth}x${report.capturedImageHeight} '
      'quality=mean:${report.captureMeanLuma?.toStringAsFixed(1) ?? '-'} '
      'p90:${report.captureLumaP90?.toStringAsFixed(1) ?? '-'} '
      'bright:${report.captureBrightRatio?.toStringAsFixed(2) ?? '-'} '
      'custom=${report.customLabels.map((e) => '${e.text}:${e.confidence.toStringAsFixed(2)}').join(',')} '
      'base=${report.baseLabels.map((e) => '${e.text}:${e.confidence.toStringAsFixed(2)}').join(',')} '
      'mapped=${report.mappedDetectedObject} '
      'decision=${report.finalDecision}',
      name: 'NoriGoVision',
    );
  }

  String _qualityDetails(CultureCaptureQuality quality) {
    return 'mean=${quality.meanLuma?.toStringAsFixed(1)} '
        'std=${quality.lumaStdDev?.toStringAsFixed(1)} '
        'range=${quality.lumaRange?.toStringAsFixed(1)} '
        'p50=${quality.lumaP50?.toStringAsFixed(1)} '
        'p90=${quality.lumaP90?.toStringAsFixed(1)} '
        'nearBlack=${quality.nearBlackRatio?.toStringAsFixed(2)} '
        'dim=${quality.dimRatio?.toStringAsFixed(2)} '
        'bright=${quality.brightRatio?.toStringAsFixed(2)}';
  }

  bool _isContextOnlyVisionResult(CultureVisionResult result) {
    return result.sourceType == 'vision_heuristic' ||
        result.detectedObjectSource == 'context_hint' ||
        result.sourceBadge == 'Context hint';
  }

  void _recordVisionDiagnostics(CultureVisionResult result) {
    if (!kDebugMode) return;
    final diagnostics = {
      'raw_labels': result.rawLabels.map((item) => item.toJson()).toList(),
      'detected_object': result.detectedObject,
      'place_type': result.placeType,
      'detected_object_source': result.detectedObjectSource,
      'confidence': result.confidence,
      'final_decision': result.finalDecision,
    };
    _lastVisionDiagnostics = diagnostics;
    developer.log(
      'Culture vision diagnostics ${diagnostics.toString()}',
      name: 'CultureScanController',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    final session = _cameraSession;
    _cameraSession = null;
    session?.dispose();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

class CultureVisionScanDraft {
  const CultureVisionScanDraft({
    required this.imagePath,
    required this.visionResult,
  });

  final String? imagePath;
  final CultureVisionResult visionResult;
}
