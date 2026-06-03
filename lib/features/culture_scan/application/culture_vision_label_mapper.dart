import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class CultureVisionObservedLabel {
  const CultureVisionObservedLabel({
    required this.label,
    required this.confidence,
    this.index,
  });

  final String label;
  final double confidence;
  final int? index;

  CultureVisionLabelDiagnostic toDiagnostic() {
    return CultureVisionLabelDiagnostic(
      label: label,
      confidence: confidence.clamp(0, 1).toDouble(),
    );
  }
}

CultureVisionResult mapCultureVisionLabels(
  List<CultureVisionObservedLabel> labels,
  CultureVisionRequest request,
) {
  final diagnostics = labels
      .map((label) => label.toDiagnostic())
      .toList(growable: false);
  if (labels.isEmpty) {
    return CultureVisionResult.noMatch(request, rawLabels: diagnostics);
  }

  final contextText = [
    request.currentLocation,
    request.hintPlaceType,
  ].join(' ').toLowerCase();
  final scored =
      _allowedObjects
          .map((object) => _scoreObject(object, labels, contextText))
          .where((item) => item.visualConfidence >= 0.5)
          .toList(growable: false)
        ..sort((a, b) => b.score.compareTo(a.score));

  if (scored.isEmpty) {
    return CultureVisionResult.noMatch(request, rawLabels: diagnostics);
  }

  final best = scored.first;
  final confidence = best.score.clamp(0, 0.94).toDouble();
  if (confidence < 0.5) {
    return CultureVisionResult.noMatch(request, rawLabels: diagnostics);
  }

  final alternatives = scored
      .take(3)
      .map(
        (item) => CultureVisionAlternative(
          detectedObject: item.object.key,
          placeType: item.object.placeType,
          label: cultureObjectLabel(item.object.key),
          confidence: item.score.clamp(0.24, 0.94).toDouble(),
        ),
      )
      .toList(growable: false);

  final source = confidence >= 0.75 ? 'mlkit_auto' : 'mlkit_suggested';
  final decision = confidence >= 0.75
      ? 'auto_confirm_possible'
      : 'needs_confirmation';

  return CultureVisionResult(
    detectedObject: best.object.key,
    placeType: best.object.placeType,
    confidence: confidence,
    alternatives: alternatives,
    needsConfirmation: true,
    sourceType: 'vision_ai',
    sourceBadge: 'Vision AI',
    detectedObjectSource: source,
    finalDecision: decision,
    rawLabels: diagnostics,
  );
}

_ScoredObject _scoreObject(
  _AllowedObject object,
  List<CultureVisionObservedLabel> labels,
  String contextText,
) {
  if (object.requiresTempleContext && !_hasAny(contextText, _templeContext)) {
    return _ScoredObject(object, 0, 0);
  }
  if (object.requiresContext.isNotEmpty &&
      !_hasAny(contextText, object.requiresContext)) {
    return _ScoredObject(object, 0, 0);
  }

  final visualConfidence = _bestConfidenceForAny(labels, object.labelKeywords);
  if (visualConfidence == 0) return _ScoredObject(object, 0, 0);

  final contextBonus = object.contextKeywords.fold<double>(
    0,
    (score, keyword) => contextText.contains(keyword) ? score + 0.06 : score,
  );
  return _ScoredObject(
    object,
    visualConfidence + contextBonus.clamp(0, 0.15).toDouble(),
    visualConfidence,
  );
}

double _bestConfidenceForAny(
  List<CultureVisionObservedLabel> labels,
  List<String> keywords,
) {
  var best = 0.0;
  for (final label in labels) {
    final normalized = label.label.toLowerCase();
    if (_unsupportedLabels.any(normalized.contains)) continue;
    for (final keyword in keywords) {
      if (normalized.contains(keyword) && label.confidence > best) {
        best = label.confidence;
      }
    }
  }
  return best;
}

bool _hasAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

class _AllowedObject {
  const _AllowedObject({
    required this.key,
    required this.placeType,
    required this.labelKeywords,
    required this.contextKeywords,
    this.requiresContext = const [],
    this.requiresTempleContext = false,
  });

  final String key;
  final String placeType;
  final List<String> labelKeywords;
  final List<String> contextKeywords;
  final List<String> requiresContext;
  final bool requiresTempleContext;
}

class _ScoredObject {
  const _ScoredObject(this.object, this.score, this.visualConfidence);

  final _AllowedObject object;
  final double score;
  final double visualConfidence;
}

const _templeContext = ['temple', 'bulguksa'];

const _unsupportedLabels = [
  'paper',
  'tissue',
  'napkin',
  'toilet paper',
  'white object',
  'product',
  'household',
];

const _allowedObjects = [
  _AllowedObject(
    key: 'temple_stone_stack',
    placeType: 'temple',
    labelKeywords: ['stone', 'rock', 'monument'],
    contextKeywords: ['temple', 'bulguksa', 'stone', 'wish'],
    requiresTempleContext: true,
  ),
  _AllowedObject(
    key: 'restaurant_call_bell',
    placeType: 'restaurant',
    labelKeywords: ['bell', 'button'],
    contextKeywords: ['restaurant', 'bell', 'table'],
  ),
  _AllowedObject(
    key: 'subway_pregnant_seat',
    placeType: 'subway',
    labelKeywords: ['seat', 'train', 'subway', 'priority'],
    contextKeywords: ['subway', 'metro', 'pregnant', 'seat'],
  ),
  _AllowedObject(
    key: 'cafe_quiet_work',
    placeType: 'cafe',
    labelKeywords: ['coffee', 'cafe', 'laptop'],
    contextKeywords: ['cafe', 'coffee', 'quiet', 'work'],
  ),
  _AllowedObject(
    key: 'kiosk_ordering',
    placeType: 'restaurant',
    labelKeywords: ['screen', 'kiosk', 'machine', 'display', 'terminal'],
    contextKeywords: ['kiosk', 'order', 'restaurant', 'cafe'],
  ),
  _AllowedObject(
    key: 'market_cash_food',
    placeType: 'market',
    labelKeywords: ['food', 'market', 'cash', 'vendor'],
    contextKeywords: ['market', 'cash', 'food', 'gwangjang'],
  ),
  _AllowedObject(
    key: 'market_queue_ticket',
    placeType: 'market',
    labelKeywords: ['ticket', 'receipt', 'queue', 'number'],
    contextKeywords: ['market', 'queue', 'ticket', 'number', 'waiting'],
    requiresContext: ['market', 'queue', 'waiting'],
  ),
  _AllowedObject(
    key: 'palace_photo_etiquette',
    placeType: 'palace',
    labelKeywords: ['palace', 'camera', 'photo'],
    contextKeywords: ['palace', 'gyeongbokgung', 'photo', 'hanbok'],
  ),
  _AllowedObject(
    key: 'hanok_resident_etiquette',
    placeType: 'hanok_village',
    labelKeywords: ['hanok', 'village', 'roof'],
    contextKeywords: ['hanok', 'bukchon', 'resident', 'quiet', 'village'],
  ),
  _AllowedObject(
    key: 'waiting_number_ticket',
    placeType: 'restaurant',
    labelKeywords: ['ticket', 'receipt', 'number', 'queue'],
    contextKeywords: ['waiting', 'number', 'ticket', 'queue', 'restaurant'],
    requiresContext: ['waiting', 'queue', 'restaurant'],
  ),
];
