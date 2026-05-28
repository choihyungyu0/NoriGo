import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_context.dart';

enum CultureCameraStatus { initial, loading, ready, unavailable }

enum CultureScanStatus { initial, scanning, result, error }

class CultureScanController extends ChangeNotifier {
  CultureScanController({
    required CultureCameraService cameraService,
    required CultureGuideHarness harness,
    EnnoiaAgentRepository ennoiaRepository =
        const SupabaseEnnoiaAgentRepository(),
    EnnoiaAgentRepository fallbackEnnoiaRepository =
        const MockEnnoiaAgentRepository(),
    CultureScanContext initialContext = CultureGuideMockData.defaultContext,
  }) : _cameraService = cameraService,
       _harness = harness,
       _ennoiaRepository = ennoiaRepository,
       _fallbackEnnoiaRepository = fallbackEnnoiaRepository,
       _baseContext = initialContext {
    _selectedLanguage = initialContext.userLanguage;
  }

  final CultureCameraService _cameraService;
  final CultureGuideHarness _harness;
  final EnnoiaAgentRepository _ennoiaRepository;
  final EnnoiaAgentRepository _fallbackEnnoiaRepository;
  final CultureScanContext _baseContext;

  CultureCameraSession? _cameraSession;
  CultureGuide? _guide;
  CultureCameraStatus _cameraStatus = CultureCameraStatus.initial;
  CultureScanStatus _scanStatus = CultureScanStatus.initial;
  String _selectedLanguage = 'English';
  String? _friendlyMessage;
  String _ennoiaSourceLabel = 'Mock ennoia';
  bool _flashEnabled = false;
  bool _isRunningEnnoia = false;
  bool _disposed = false;

  CultureCameraStatus get cameraStatus => _cameraStatus;

  CultureScanStatus get scanStatus => _scanStatus;

  String get selectedLanguage => _selectedLanguage;

  String? get friendlyMessage => _friendlyMessage;

  String get ennoiaSourceLabel => _ennoiaSourceLabel;

  bool get isRunningEnnoia => _isRunningEnnoia;

  bool get flashEnabled => _flashEnabled;

  CultureGuide? get guide => _guide;

  CameraController? get cameraController => _cameraSession?.controller;

  bool get hasCameraPreview => _cameraSession?.hasPreview ?? false;

  Future<void> initializeCamera() async {
    if (_disposed) return;

    _cameraStatus = CultureCameraStatus.loading;
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

  Future<void> scanCulture() async {
    if (_disposed) return;

    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    _safeNotifyListeners();

    try {
      final context = CultureScanContext(
        userLanguage: _selectedLanguage,
        currentLocation: _baseContext.currentLocation,
        detectedObject: _baseContext.detectedObject,
        culturalKeyword: _baseContext.culturalKeyword,
        userIntent: _baseContext.userIntent,
        outputSections: _baseContext.outputSections,
      );
      final guide = await _harness.generateGuide(context);
      if (_disposed) return;

      _guide = guide;
      _ennoiaSourceLabel = 'Mock ennoia';
      _scanStatus = CultureScanStatus.result;
    } catch (error) {
      if (_disposed) return;
      developer.log(
        'Culture scan failed.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _guide = CultureGuideMockData.fallbackGuide;
      _scanStatus = CultureScanStatus.error;
      _friendlyMessage =
          'NoriGo could not complete the scan, so it is showing a safe guide.';
    }

    _safeNotifyListeners();
  }

  Future<void> runEnnoiaCultureGuide() async {
    if (_disposed || _isRunningEnnoia) return;

    _isRunningEnnoia = true;
    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    _safeNotifyListeners();

    final request = CultureGuideAgentRequest(
      userLanguage: _selectedLanguage,
      currentLocation: _baseContext.currentLocation,
      detectedObject: _baseContext.detectedObject,
      koreanKeyword: _baseContext.culturalKeyword,
      userIntent: _baseContext.userIntent,
    );

    try {
      final result = await _ennoiaRepository.fetchCultureGuide(request);
      if (_disposed) return;
      _guide = result.toCultureGuide();
      _ennoiaSourceLabel = result.isRealEnnoia
          ? 'ennoia + KTO MCP'
          : 'Mock ennoia';
      _scanStatus = CultureScanStatus.result;
    } catch (error) {
      developer.log(
        'ennoia culture guide fallback used.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      if (_disposed) return;
      final fallback = await _fallbackEnnoiaRepository.fetchCultureGuide(
        request,
      );
      if (_disposed) return;
      _guide = fallback.toCultureGuide();
      _ennoiaSourceLabel = 'Mock ennoia';
      _scanStatus = CultureScanStatus.result;
      _friendlyMessage =
          'NoriGo could not reach ennoia, so it is showing a mock guide.';
    } finally {
      _isRunningEnnoia = false;
      _safeNotifyListeners();
    }
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
