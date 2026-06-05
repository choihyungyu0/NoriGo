import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

abstract class CultureVisionClassifier {
  const CultureVisionClassifier();

  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  );
}

class CultureVisionClassifierDebugResult {
  const CultureVisionClassifierDebugResult({
    required this.result,
    this.ran = false,
    this.expectedModelPath = '',
    this.modelLoaded = false,
    this.labelsFileLoaded = false,
    this.modelVersionOrHash,
    this.labels = const [],
    this.finalDecision,
    this.errorMessage,
  });

  final CultureVisionResult? result;
  final bool ran;
  final String expectedModelPath;
  final bool modelLoaded;
  final bool labelsFileLoaded;
  final String? modelVersionOrHash;
  final List<CultureVisionObservedLabel> labels;
  final String? finalDecision;
  final String? errorMessage;
}

abstract class CultureVisionDebugProbe {
  Future<CultureVisionClassifierDebugResult> classifyForDebug(
    CultureImageCapture capture,
    CultureVisionRequest request, {
    double? suggestThreshold,
  });
}
