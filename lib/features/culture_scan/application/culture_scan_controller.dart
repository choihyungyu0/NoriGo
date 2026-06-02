import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/data/supabase_culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

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
    CultureGuideHarness? harness,
    CultureScanRequest? initialRequest,
  }) : _cameraService = cameraService,
       _repository = repository,
       _baseRequest = initialRequest ?? CultureScanRequest.defaultTemple() {
    _selectedLanguage = _baseRequest.userLanguage;
  }

  final CultureCameraService _cameraService;
  final CultureScanRepository _repository;
  final CultureScanRequest _baseRequest;

  CultureCameraSession? _cameraSession;
  CultureGuideResult? _result;
  CultureCameraStatus _cameraStatus = CultureCameraStatus.initial;
  CultureScanStatus _scanStatus = CultureScanStatus.idle;
  String _selectedLanguage = 'English';
  String? _friendlyMessage;
  bool _flashEnabled = false;
  bool _disposed = false;

  CultureCameraStatus get cameraStatus => _cameraStatus;

  CultureScanStatus get scanStatus => _scanStatus;

  String get selectedLanguage => _selectedLanguage;

  String? get friendlyMessage => _friendlyMessage;

  String get ennoiaSourceLabel => sourceBadge;

  String get sourceBadge => _result?.sourceBadge ?? 'Demo fallback';

  String get sourceType => _result?.sourceType ?? 'culture_fallback';

  bool get isRunningEnnoia => _scanStatus == CultureScanStatus.scanning;

  bool get flashEnabled => _flashEnabled;

  CultureGuideResult? get result => _result;

  CultureGuide? get guide => _result?.toCultureGuide();

  CameraController? get cameraController => _cameraSession?.controller;

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

  Future<void> toggleFlash() async {
    if (_disposed) return;

    _flashEnabled = !_flashEnabled;
    _safeNotifyListeners();

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(
        _flashEnabled ? FlashMode.torch : FlashMode.off,
      );
    } catch (error) {
      if (_disposed) return;
      developer.log(
        'Flash mode unavailable.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _flashEnabled = false;
      _friendlyMessage = 'Flash is unavailable on this device.';
      _safeNotifyListeners();
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

    final effectiveRequest = request.copyWith(userLanguage: _selectedLanguage);
    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    _safeNotifyListeners();

    try {
      final result = await _repository.runCultureGuide(effectiveRequest);
      if (_disposed) return;
      _result = result;
      _scanStatus = result.isLocalFallback
          ? CultureScanStatus.localOnly
          : CultureScanStatus.success;
      if (result.isLocalFallback) {
        _friendlyMessage =
            'Supabase is not configured, so NoriGo is showing a local demo guide.';
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
          'NoriGo could not reach Culture Guide, so it is showing a safe demo guide.';
    }

    _safeNotifyListeners();
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
