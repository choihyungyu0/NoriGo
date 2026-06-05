import 'package:norigo/features/culture_scan/application/culture_vision_label_mapper.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

const callBellModelAssetPath = 'assets/ml/call_bell_labeler.tflite';
const callBellLabelsAssetPath = 'assets/ml/call_bell_labels.txt';
const callBellPositiveLabel = 'restaurant_call_bell';
const callBellNegativeLabel = 'not_restaurant_call_bell';
const callBellPositiveIndex = 1;
const callBellNegativeIndex = 0;
const callBellAutoThreshold = 0.80;
const callBellSuggestThreshold = 0.60;
const _prototypePositiveMargin = 0.08;

class CallBellCustomMappingResult {
  const CallBellCustomMappingResult({
    required this.result,
    required this.finalDecision,
  });

  final CultureVisionResult? result;
  final String finalDecision;
}

CultureVisionResult? mapCallBellCustomLabels(
  List<CultureVisionObservedLabel> labels,
  CultureVisionRequest request,
) {
  return mapCallBellCustomLabelsForDebug(labels, request).result;
}

CallBellCustomMappingResult mapCallBellCustomLabelsForDebug(
  List<CultureVisionObservedLabel> labels,
  CultureVisionRequest request, {
  double suggestThreshold = callBellSuggestThreshold,
  double marginThreshold = _prototypePositiveMargin,
}) {
  if (labels.isEmpty) {
    return const CallBellCustomMappingResult(
      result: null,
      finalDecision: 'no_labels',
    );
  }

  final diagnostics = labels
      .map((label) => label.toDiagnostic())
      .toList(growable: false);
  final positive = _bestLabel(labels, _isPositiveCallBellLabel);
  final negative = _bestLabel(labels, _isNegativeCallBellLabel);

  if (positive == null) {
    if (negative != null) {
      return CallBellCustomMappingResult(
        result: CultureVisionResult.noMatch(request, rawLabels: diagnostics),
        finalDecision: 'no_allowlist_match',
      );
    }
    return const CallBellCustomMappingResult(
      result: null,
      finalDecision: 'no_allowlist_match',
    );
  }

  final positiveConfidence = positive.confidence.clamp(0, 1).toDouble();
  final negativeConfidence = negative?.confidence.clamp(0, 1).toDouble() ?? 0;
  final positiveMargin = positiveConfidence - negativeConfidence;
  if (negativeConfidence >= positiveConfidence) {
    return CallBellCustomMappingResult(
      result: CultureVisionResult.noMatch(request, rawLabels: diagnostics),
      finalDecision: 'confidence_too_low',
    );
  }
  if (positiveConfidence < suggestThreshold ||
      positiveMargin < marginThreshold) {
    return CallBellCustomMappingResult(
      result: CultureVisionResult.noMatch(request, rawLabels: diagnostics),
      finalDecision: 'confidence_too_low',
    );
  }

  return CallBellCustomMappingResult(
    result: CultureVisionResult(
      detectedObject: 'restaurant_call_bell',
      placeType: 'restaurant',
      confidence: positiveConfidence,
      alternatives: [
        CultureVisionAlternative(
          detectedObject: 'restaurant_call_bell',
          placeType: 'restaurant',
          label: cultureObjectLabel('restaurant_call_bell'),
          confidence: positiveConfidence,
        ),
      ],
      needsConfirmation: true,
      sourceType: 'vision_ai',
      sourceBadge: 'Custom call bell',
      detectedObjectSource: 'mlkit_custom_call_bell',
      finalDecision: 'needs_confirmation',
      rawLabels: diagnostics,
    ),
    finalDecision: 'needs_confirmation',
  );
}

CultureVisionObservedLabel? _bestLabel(
  List<CultureVisionObservedLabel> labels,
  bool Function(CultureVisionObservedLabel label) test,
) {
  CultureVisionObservedLabel? best;
  for (final label in labels.where(test)) {
    if (best == null || label.confidence > best.confidence) {
      best = label;
    }
  }
  return best;
}

bool _isPositiveCallBellLabel(CultureVisionObservedLabel label) {
  return _normalizedLabel(label.label) == callBellPositiveLabel ||
      label.index == callBellPositiveIndex;
}

bool _isNegativeCallBellLabel(CultureVisionObservedLabel label) {
  return _normalizedLabel(label.label) == callBellNegativeLabel ||
      label.index == callBellNegativeIndex;
}

String _normalizedLabel(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
}
