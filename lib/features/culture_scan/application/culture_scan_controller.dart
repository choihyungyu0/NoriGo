import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
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
    CultureScanContext initialContext = CultureGuideMockData.defaultContext,
  }) : _cameraService = cameraService,
       _harness = harness,
       _baseContext = initialContext {
    _selectedLanguage = initialContext.userLanguage;
  }

  final CultureCameraService _cameraService;
  final CultureGuideHarness _harness;
  final CultureScanContext _baseContext;

  CultureCameraSession? _cameraSession;
  CultureGuide? _guide;
  CultureCameraStatus _cameraStatus = CultureCameraStatus.initial;
  CultureScanStatus _scanStatus = CultureScanStatus.initial;
  String _selectedLanguage = 'English';
  String? _friendlyMessage;
  bool _flashEnabled = false;

  CultureCameraStatus get cameraStatus => _cameraStatus;

  CultureScanStatus get scanStatus => _scanStatus;

  String get selectedLanguage => _selectedLanguage;

  String? get friendlyMessage => _friendlyMessage;

  bool get flashEnabled => _flashEnabled;

  CultureGuide? get guide => _guide;

  CameraController? get cameraController => _cameraSession?.controller;

  bool get hasCameraPreview => _cameraSession?.hasPreview ?? false;

  Future<void> initializeCamera() async {
    _cameraStatus = CultureCameraStatus.loading;
    _friendlyMessage = null;
    notifyListeners();

    final session = await _cameraService.initialize();
    _cameraSession = session;
    _cameraStatus = session.hasPreview
        ? CultureCameraStatus.ready
        : CultureCameraStatus.unavailable;
    _friendlyMessage = session.unavailableMessage;
    notifyListeners();
  }

  void updateLanguage(String language) {
    if (language.trim().isEmpty) return;
    _selectedLanguage = language.trim();
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    _flashEnabled = !_flashEnabled;
    notifyListeners();

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(
        _flashEnabled ? FlashMode.torch : FlashMode.off,
      );
    } catch (error) {
      developer.log(
        'Flash mode unavailable.',
        name: 'CultureScanController',
        error: error.runtimeType,
      );
      _flashEnabled = false;
      _friendlyMessage = 'Flash is unavailable on this device.';
      notifyListeners();
    }
  }

  Future<void> scanCulture() async {
    _scanStatus = CultureScanStatus.scanning;
    _friendlyMessage = null;
    notifyListeners();

    try {
      final context = CultureScanContext(
        userLanguage: _selectedLanguage,
        currentLocation: _baseContext.currentLocation,
        detectedObject: _baseContext.detectedObject,
        culturalKeyword: _baseContext.culturalKeyword,
        userIntent: _baseContext.userIntent,
        outputSections: _baseContext.outputSections,
      );
      _guide = await _harness.generateGuide(context);
      _scanStatus = CultureScanStatus.result;
    } catch (error) {
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

    notifyListeners();
  }

  @override
  void dispose() {
    _cameraSession?.dispose();
    super.dispose();
  }
}
