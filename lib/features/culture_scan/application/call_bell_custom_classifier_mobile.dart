import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:norigo/features/culture_scan/application/call_bell_custom_classifier_shared.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';
import 'package:path_provider/path_provider.dart';

typedef CallBellAssetExists = Future<bool> Function(String assetPath);
typedef CallBellModelPathResolver = Future<String> Function(String assetPath);
typedef CallBellPlatformCheck = bool Function();

class CallBellCustomClassifier extends CultureVisionClassifier {
  const CallBellCustomClassifier({
    this.modelAssetPath = callBellModelAssetPath,
    this.assetExists,
    this.resolveModelPath,
    this.isSupportedPlatform,
  });

  final String modelAssetPath;
  final CallBellAssetExists? assetExists;
  final CallBellModelPathResolver? resolveModelPath;
  final CallBellPlatformCheck? isSupportedPlatform;

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    final supportsPlatform =
        isSupportedPlatform?.call() ?? (Platform.isAndroid || Platform.isIOS);
    if (!supportsPlatform) return null;

    final filePath = capture.filePath;
    if (filePath == null || filePath.trim().isEmpty) return null;
    if (!await (assetExists ?? _assetExists)(modelAssetPath)) return null;

    ImageLabeler? labeler;
    try {
      final modelPath = await (resolveModelPath ?? _resolveModelPath)(
        modelAssetPath,
      );
      labeler = ImageLabeler(
        options: LocalLabelerOptions(
          confidenceThreshold: 0,
          modelPath: modelPath,
          maxCount: 2,
        ),
      );
      final labels = await labeler.processImage(
        InputImage.fromFilePath(filePath),
      );
      return mapCallBellCustomLabels(
        labels
            .map(
              (label) => CultureVisionObservedLabel(
                label: label.label,
                confidence: label.confidence,
                index: label.index,
              ),
            )
            .toList(growable: false),
        request,
      );
    } on PlatformException {
      return null;
    } on FileSystemException {
      return null;
    } finally {
      await labeler?.close();
    }
  }
}

Future<bool> _assetExists(String assetPath) async {
  try {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final decoded = jsonDecode(manifest);
    if (decoded is Map && decoded.containsKey(assetPath)) return true;
  } catch (_) {
    // Fall through to direct asset load. Some test shells do not expose the
    // generated AssetManifest in the same way as a packaged Flutter app.
  }

  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (_) {
    return false;
  }
}

Future<String> _resolveModelPath(String assetPath) async {
  final supportDir = await getApplicationSupportDirectory();
  final file = File('${supportDir.path}/$assetPath');
  await file.parent.create(recursive: true);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      flush: true,
    );
  }
  return file.path;
}
