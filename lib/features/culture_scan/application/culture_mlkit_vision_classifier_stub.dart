import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class MlKitCultureVisionClassifier extends CultureVisionClassifier {
  const MlKitCultureVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return null;
  }
}
