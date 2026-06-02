import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:norigo/features/culture_scan/application/browser_camera_preview.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';

class CultureCameraSession {
  const CultureCameraSession({
    this.controller,
    this.preview,
    this.disposePreview,
    this.capturePreview,
    this.unavailableMessage,
  });

  final CameraController? controller;
  final Widget? preview;
  final Future<void> Function()? disposePreview;
  final Future<CultureImageCapture?> Function()? capturePreview;
  final String? unavailableMessage;

  bool get hasPreview =>
      preview != null || (controller?.value.isInitialized ?? false);

  Future<void> dispose() async {
    await disposePreview?.call();
    await controller?.dispose();
  }

  Future<CultureImageCapture?> captureStill() async {
    final previewCapture = capturePreview;
    if (previewCapture != null) {
      final captured = await previewCapture();
      if (captured != null && !captured.isEmpty) return captured;
    }

    final cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return null;
    }

    final file = await cameraController.takePicture();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return CultureImageCapture(
      bytes: bytes,
      contentType: 'image/jpeg',
      extension: 'jpg',
      filePath: file.path,
    );
  }
}

abstract class CultureCameraService {
  Future<CultureCameraSession> initialize();
}

class DeviceCultureCameraService implements CultureCameraService {
  const DeviceCultureCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return _browserCameraFallback(
          unavailableMessage: 'No camera detected. Showing guide preview.',
        );
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      return CultureCameraSession(controller: controller);
    } on CameraException catch (error) {
      await controller?.dispose();
      return _browserCameraFallback(
        unavailableMessage: _friendlyCameraMessage(error.code),
      );
    } catch (_) {
      await controller?.dispose();
      return _browserCameraFallback(
        unavailableMessage: 'No camera detected. Showing guide preview.',
      );
    }
  }

  Future<CultureCameraSession> _browserCameraFallback({
    required String unavailableMessage,
  }) async {
    try {
      final browserPreview = await createBrowserCameraPreview();
      if (browserPreview != null) {
        return CultureCameraSession(
          preview: browserPreview.widget,
          disposePreview: browserPreview.dispose,
          capturePreview: browserPreview.captureStill,
        );
      }
    } catch (_) {
      // Keep the safe fallback background if browser camera access is blocked
      // or no camera exists.
    }
    return CultureCameraSession(unavailableMessage: unavailableMessage);
  }

  String _friendlyCameraMessage(String code) {
    final normalizedCode = code.toLowerCase();
    if (normalizedCode.contains('access') ||
        normalizedCode.contains('permission') ||
        normalizedCode.contains('denied')) {
      return 'Camera permission was not granted. Allow camera access in your browser to see the preview.';
    }
    return 'No camera detected. Showing guide preview.';
  }
}
