import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

void main() {
  const templeRequest = CultureVisionRequest(
    currentLocation: 'Bulguksa',
    userLanguage: 'English',
    hintPlaceType: 'temple',
  );

  test(
    'unsupported tissue and paper labels do not map to temple stone stack',
    () {
      final result = mapCultureVisionLabels(const [
        CultureVisionObservedLabel(label: 'Tissue', confidence: 0.91),
        CultureVisionObservedLabel(label: 'Paper', confidence: 0.87),
        CultureVisionObservedLabel(label: 'White object', confidence: 0.76),
      ], templeRequest);

      expect(result.detectedObject, 'unsupported');
      expect(result.detectedObjectSource, 'no_match');
      expect(result.finalDecision, 'manual_required');
      expect(result.requiresManualSelection, isTrue);
      expect(result.rawLabels.map((item) => item.label), contains('Tissue'));
    },
  );

  test('stone labels only map to temple stone stack in temple context', () {
    final templeResult = mapCultureVisionLabels(const [
      CultureVisionObservedLabel(label: 'Rock', confidence: 0.82),
    ], templeRequest);
    final cafeResult = mapCultureVisionLabels(
      const [CultureVisionObservedLabel(label: 'Rock', confidence: 0.88)],
      const CultureVisionRequest(
        currentLocation: 'Seoul cafe',
        userLanguage: 'English',
        hintPlaceType: 'cafe',
      ),
    );

    expect(templeResult.detectedObject, 'temple_stone_stack');
    expect(templeResult.detectedObjectSource, 'mlkit_auto');
    expect(templeResult.finalDecision, 'auto_confirm_possible');
    expect(cafeResult.detectedObjectSource, 'no_match');
  });

  test('medium confidence allowed label requires confirmation', () {
    final result = mapCultureVisionLabels(
      const [
        CultureVisionObservedLabel(label: 'Kiosk terminal', confidence: 0.61),
      ],
      const CultureVisionRequest(
        currentLocation: 'Korean restaurant',
        userLanguage: 'English',
        hintPlaceType: 'restaurant',
      ),
    );

    expect(result.detectedObject, 'kiosk_ordering');
    expect(result.detectedObjectSource, 'mlkit_suggested');
    expect(result.finalDecision, 'needs_confirmation');
    expect(result.requiresManualSelection, isFalse);
  });

  test('low confidence allowed label is treated as manual required', () {
    final result = mapCultureVisionLabels(
      const [
        CultureVisionObservedLabel(label: 'Kiosk terminal', confidence: 0.42),
      ],
      const CultureVisionRequest(
        currentLocation: 'Korean restaurant',
        userLanguage: 'English',
        hintPlaceType: 'restaurant',
      ),
    );

    expect(result.detectedObjectSource, 'no_match');
    expect(result.finalDecision, 'manual_required');
    expect(result.requiresManualSelection, isTrue);
  });
}
