import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_mlkit_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/data/supabase_culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

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
    CultureVisionClassifier visionClassifier =
        const MlKitCultureVisionClassifier(),
    CultureGuideHarness? harness,
    CultureScanRequest? initialRequest,
  }) : _cameraService = cameraService,
       _repository = repository,
       _visionClassifier = visionClassifier,
       _baseRequest = initialRequest ?? CultureScanRequest.defaultTemple() {
    _selectedLanguage = _baseRequest.userLanguage;
  }

  final CultureCameraService _cameraService;
  final CultureScanRepository _repository;
  final CultureVisionClassifier _visionClassifier;
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

  CameraController? get cameraController => _cameraSession?.controller;

  Widget? get cameraPreview => _cameraSession?.preview;

  bool get hasCameraPreview => _cameraSession?.hasPreview ?? false;

  CultureScanRequest get defaultRequest {
    return _baseRequest.copyWith(userLanguage: _selectedLanguage);
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
    _safeNotifyListeners();

    String? imagePath;
    CultureImageCapture? capture;
    CultureVisionResult visionResult;
    try {
      capture = await _captureScanImage();
      imagePath = await _uploadScanImage(capture);
      final visionRequest = CultureVisionRequest(
        imagePath: imagePath,
        currentLocation: effectiveRequest.currentLocation,
        userLanguage: effectiveRequest.userLanguage,
        hintPlaceType: effectiveRequest.placeType,
      );
      visionResult = await _classifyCultureObject(capture, visionRequest);
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
    CultureImageCapture? capture,
    CultureVisionRequest request,
  ) async {
    if (capture != null && !capture.isEmpty) {
      try {
        final localResult = await _visionClassifier.classify(capture, request);
        if (localResult != null) return localResult;
      } catch (error) {
        developer.log(
          'Local ML Kit culture vision skipped.',
          name: 'CultureScanController',
          error: error.runtimeType,
        );
      }
    }
    final remoteResult = await _repository
        .detectCultureObject(request)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => CultureVisionResult.noMatch(request),
        );
    if (_isContextOnlyVisionResult(remoteResult)) {
      return CultureVisionResult.noMatch(request);
    }
    return remoteResult;
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
