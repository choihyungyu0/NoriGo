import 'dart:convert';
import 'dart:developer' as developer;
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

class CallBellCustomClassifier extends CultureVisionClassifier
    implements CultureVisionDebugProbe {
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
    return (await classifyForDebug(capture, request)).result;
  }

  @override
  Future<CultureVisionClassifierDebugResult> classifyForDebug(
    CultureImageCapture capture,
    CultureVisionRequest request, {
    double? suggestThreshold,
  }) async {
    final supportsPlatform =
        isSupportedPlatform?.call() ?? (Platform.isAndroid || Platform.isIOS);
    if (!supportsPlatform) {
      return CultureVisionClassifierDebugResult(
        result: null,
        expectedModelPath: modelAssetPath,
        finalDecision: 'model_missing',
        errorMessage: 'Platform is not supported by ML Kit local models.',
      );
    }

    final filePath = capture.filePath;
    if (filePath == null || filePath.trim().isEmpty) {
      return CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        expectedModelPath: modelAssetPath,
        finalDecision: 'capture_failed',
        errorMessage: 'Captured image has no file path.',
      );
    }

    final exists = assetExists ?? _assetExists;
    final modelLoaded = await exists(modelAssetPath);
    final labelsFileLoaded = await exists(callBellLabelsAssetPath);
    final modelVersionOrHash = modelLoaded
        ? await _assetFingerprint(modelAssetPath)
        : null;
    if (!modelLoaded) {
      _logVision(
        'custom_model_loaded=false labels_file_loaded=$labelsFileLoaded',
      );
      return CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        expectedModelPath: modelAssetPath,
        modelLoaded: false,
        labelsFileLoaded: labelsFileLoaded,
        modelVersionOrHash: modelVersionOrHash,
        finalDecision: 'model_missing',
        errorMessage: 'Custom call bell TFLite asset was not bundled.',
      );
    }

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
      final observedLabels = labels
          .map(
            (label) => CultureVisionObservedLabel(
              label: label.label,
              confidence: label.confidence,
              index: label.index,
            ),
          )
          .toList(growable: false);
      final mapping = mapCallBellCustomLabelsForDebug(
        observedLabels,
        request,
        suggestThreshold: suggestThreshold ?? callBellSuggestThreshold,
      );
      _logVision(
        'custom_model_loaded=true image=${_basename(filePath)} '
        'labels=${_labelsLog(observedLabels)} '
        'decision=${mapping.finalDecision}',
      );
      return CultureVisionClassifierDebugResult(
        result: mapping.result,
        ran: true,
        expectedModelPath: modelAssetPath,
        modelLoaded: true,
        labelsFileLoaded: labelsFileLoaded,
        modelVersionOrHash: modelVersionOrHash,
        labels: observedLabels,
        finalDecision: mapping.finalDecision,
      );
    } on PlatformException catch (error) {
      _logVision('custom_model_error=${error.code}');
      return CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        expectedModelPath: modelAssetPath,
        modelLoaded: modelLoaded,
        labelsFileLoaded: labelsFileLoaded,
        modelVersionOrHash: modelVersionOrHash,
        finalDecision: 'error',
        errorMessage: error.code,
      );
    } on FileSystemException catch (error) {
      _logVision('custom_model_file_error=${error.osError?.errorCode}');
      return CultureVisionClassifierDebugResult(
        result: null,
        ran: true,
        expectedModelPath: modelAssetPath,
        modelLoaded: modelLoaded,
        labelsFileLoaded: labelsFileLoaded,
        modelVersionOrHash: modelVersionOrHash,
        finalDecision: 'error',
        errorMessage: error.message,
      );
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

Future<String?> _assetFingerprint(String assetPath) async {
  try {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    var hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '${bytes.length}-${hash.toRadixString(16)}';
  } catch (_) {
    return null;
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

void _logVision(String message) {
  developer.log(message, name: 'NoriGoVision');
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
