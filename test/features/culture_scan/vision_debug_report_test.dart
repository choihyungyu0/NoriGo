import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/domain/vision_debug_report.dart';

void main() {
  test('VisionDebugReport serializes to JSON and back', () {
    final report = VisionDebugReport(
      createdAt: DateTime.utc(2026, 6, 5, 9),
      platform: 'android',
      cameraMode: 'rear',
      customModelExpectedPath: 'assets/ml/call_bell_labeler.tflite',
      customModelLoaded: true,
      labelsFileLoaded: true,
      modelVersionOrHash: '12-abcd',
      captureSucceeded: true,
      capturedImagePath: 'scan.jpg',
      capturedImageWidth: 640,
      capturedImageHeight: 480,
      capturedImageFileSizeBytes: 12345,
      capturedImageRotation: 90,
      capturedImageSource: 'raw_camera_xfile',
      captureMeanLuma: 48.2,
      captureLumaStdDev: 12.4,
      captureLumaRange: 73.0,
      captureLumaP50: 44.0,
      captureLumaP90: 81.0,
      captureNearBlackRatio: 0.12,
      captureDimRatio: 0.48,
      captureBrightRatio: 0.09,
      customLabels: const [
        VisionDebugLabel(
          text: 'restaurant_call_bell',
          index: 1,
          confidence: 0.72,
        ),
      ],
      baseLabels: const [VisionDebugLabel(text: 'Bell', confidence: 0.66)],
      serverVisionResult: const {'detectedObject': 'restaurant_call_bell'},
      mappedDetectedObject: 'restaurant_call_bell',
      mappedPlaceType: 'restaurant',
      detectedObjectSource: 'mlkit_custom_call_bell',
      visionConfidence: 0.72,
      thresholdAuto: 0.80,
      thresholdSuggest: 0.60,
      finalDecision: 'needs_confirmation',
    );

    final json = report.toJson();
    final parsed = VisionDebugReport.fromJson(json);

    expect(json['finalDecision'], 'needs_confirmation');
    expect(parsed.finalDecision, 'needs_confirmation');
    expect(parsed.customLabels.single.text, 'restaurant_call_bell');
    expect(parsed.baseLabels.single.confidence, 0.66);
    expect(parsed.capturedImageSource, 'raw_camera_xfile');
    expect(parsed.captureLumaP90, 81.0);
    expect(parsed.captureBrightRatio, 0.09);
  });
}
