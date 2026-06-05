import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class MlKitCultureVisionClassifier extends CultureVisionClassifier
    implements CultureVisionDebugProbe {
  const MlKitCultureVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    return (await classifyForDebug(capture, request)).result;
  }

  @override
  Future<CultureVisionClassifierDebugResult> classifyForDebug(
    CultureImageCapture capture,
    CultureVisionRequest request, {
    double? suggestThreshold,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const CultureVisionClassifierDebugResult(
        result: null,
        finalDecision: 'model_missing',
        errorMessage: 'Platform is not supported by ML Kit.',
      );
    }
    final filePath = capture.filePath;
    if (filePath == null || filePath.trim().isEmpty) {
      return const CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        finalDecision: 'capture_failed',
        errorMessage: 'Captured image has no file path.',
      );
    }

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.35),
    );
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final labels = await labeler.processImage(inputImage);
      final observedLabels = labels
          .map(
            (label) => CultureVisionObservedLabel(
              label: label.label,
              confidence: label.confidence,
              index: label.index,
            ),
          )
          .toList(growable: false);
      final mapping = mapCultureVisionLabelsForDebug(observedLabels, request);
      developer.log(
        'base_mlkit image=${_basename(filePath)} '
        'labels=${_labelsLog(observedLabels)} '
        'decision=${mapping.finalDecision}',
        name: 'NoriGoVision',
      );
      return CultureVisionClassifierDebugResult(
        result: mapping.result,
        ran: true,
        labels: observedLabels,
        finalDecision: mapping.finalDecision,
      );
    } catch (error) {
      developer.log(
        'base_mlkit_error=${error.runtimeType}',
        name: 'NoriGoVision',
      );
      return CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        finalDecision: 'error',
        errorMessage: error.runtimeType.toString(),
      );
    } finally {
      await labeler.close();
    }
  }
}

String _basename(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}

String _labelsLog(List<CultureVisionObservedLabel> labels) {
  return labels
      .map(
        (label) =>
            '${label.label}:${label.confidence.toStringAsFixed(2)}'
            '${label.index == null ? '' : '#${label.index}'}',
      )
      .join(',');
}
