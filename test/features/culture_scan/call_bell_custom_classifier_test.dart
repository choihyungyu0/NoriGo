import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/application/call_bell_custom_classifier.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

void main() {
  const request = CultureVisionRequest(
    currentLocation: 'Korean restaurant',
    userLanguage: 'English',
    hintPlaceType: 'restaurant',
  );

  test('missing custom call bell model does not crash', () async {
    final classifier = CallBellCustomClassifier(
      isSupportedPlatform: () => true,
      assetExists: (_) async => false,
    );

    final result = await classifier.classify(
      CultureImageCapture(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        extension: 'jpg',
        filePath: 'scan.jpg',
      ),
      request,
    );

    expect(result, isNull);
  });

  test('restaurant_call_bell confidence 0.85 triggers confirmation', () {
    final result = mapCallBellCustomLabels(const [
      CultureVisionObservedLabel(
        label: 'restaurant_call_bell',
        confidence: 0.85,
        index: 1,
      ),
    ], request);

    expect(result?.detectedObject, 'restaurant_call_bell');
    expect(result?.detectedObjectSource, 'mlkit_custom_call_bell');
    expect(result?.finalDecision, 'auto_confirm_possible');
    expect(result?.requiresManualSelection, isFalse);
  });

  test('restaurant_call_bell confidence 0.65 requires confirmation', () {
    final result = mapCallBellCustomLabels(const [
      CultureVisionObservedLabel(label: '', confidence: 0.65, index: 1),
    ], request);

    expect(result?.detectedObject, 'restaurant_call_bell');
    expect(result?.detectedObjectSource, 'mlkit_custom_call_bell');
    expect(result?.finalDecision, 'needs_confirmation');
    expect(result?.requiresManualSelection, isFalse);
  });

  test('restaurant_call_bell confidence 0.40 opens manual selection', () {
    final result = mapCallBellCustomLabels(const [
      CultureVisionObservedLabel(
        label: 'restaurant_call_bell',
        confidence: 0.40,
        index: 1,
      ),
    ], request);

    expect(result?.detectedObject, 'unsupported');
    expect(result?.detectedObjectSource, 'no_match');
    expect(result?.requiresManualSelection, isTrue);
  });

  test('not_restaurant_call_bell never maps to a culture object', () {
    final result = mapCallBellCustomLabels(const [
      CultureVisionObservedLabel(
        label: 'not_restaurant_call_bell',
        confidence: 0.96,
        index: 0,
      ),
    ], request);

    expect(result?.detectedObject, 'unsupported');
    expect(result?.detectedObject, isNot('restaurant_call_bell'));
    expect(result?.detectedObjectSource, 'no_match');
  });

  test('tissue and paper custom labels do not become temple_stone_stack', () {
    final result = mapCallBellCustomLabels(const [
      CultureVisionObservedLabel(label: 'Tissue', confidence: 0.91),
      CultureVisionObservedLabel(label: 'Paper', confidence: 0.87),
    ], request);

    expect(result, isNull);
  });
}
