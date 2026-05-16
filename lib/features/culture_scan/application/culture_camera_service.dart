import 'package:camera/camera.dart';

class CultureCameraSession {
  const CultureCameraSession({this.controller, this.unavailableMessage});

  final CameraController? controller;
  final String? unavailableMessage;

  bool get hasPreview => controller?.value.isInitialized ?? false;

  Future<void> dispose() async {
    await controller?.dispose();
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
        return const CultureCameraSession(
          unavailableMessage:
              'Camera preview is unavailable on this device. You can still test the guide.',
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
      return CultureCameraSession(
        unavailableMessage: _friendlyCameraMessage(error.code),
      );
    } catch (_) {
      await controller?.dispose();
      return const CultureCameraSession(
        unavailableMessage:
            'Camera preview is unavailable here. NoriGo is showing a safe preview background.',
      );
    }
  }

  String _friendlyCameraMessage(String code) {
    if (code.toLowerCase().contains('access')) {
      return 'Camera permission was not granted. You can still try the mock culture scan.';
    }
    return 'Camera preview is unavailable here. NoriGo is showing a safe preview background.';
  }
}
