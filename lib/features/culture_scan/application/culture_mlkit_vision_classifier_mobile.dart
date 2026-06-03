import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class MlKitCultureVisionClassifier extends CultureVisionClassifier {
  const MlKitCultureVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    final filePath = capture.filePath;
    if (filePath == null || filePath.trim().isEmpty) return null;

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.35),
    );
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final labels = await labeler.processImage(inputImage);
      return mapCultureVisionLabels(
        labels
            .map(
              (label) => CultureVisionObservedLabel(
                label: label.label,
                confidence: label.confidence,
              ),
            )
            .toList(growable: false),
        request,
      );
    } finally {
      await labeler.close();
    }
  }
}
