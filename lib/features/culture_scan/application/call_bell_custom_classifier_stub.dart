import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class CallBellCustomClassifier extends CultureVisionClassifier {
  const CallBellCustomClassifier({
    String modelAssetPath = '',
    Future<bool> Function(String assetPath)? assetExists,
    Future<String> Function(String assetPath)? resolveModelPath,
    bool Function()? isSupportedPlatform,
  });

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return null;
  }
}
