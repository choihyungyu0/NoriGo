import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

abstract class CultureVisionClassifier {
  const CultureVisionClassifier();

  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  );
}
