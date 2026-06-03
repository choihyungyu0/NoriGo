import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

class CultureVisionRequest {
  const CultureVisionRequest({
    this.imagePath,
    required this.currentLocation,
    required this.userLanguage,
    required this.hintPlaceType,
  });

  final String? imagePath;
  final String currentLocation;
  final String userLanguage;
  final String hintPlaceType;

  Map<String, Object?> toJson() {
    return {
      if (imagePath != null && imagePath!.trim().isNotEmpty)
        'image_path': imagePath!.trim(),
      'current_location': currentLocation.trim().isEmpty
          ? 'Bulguksa'
          : currentLocation.trim(),
      'user_language': userLanguage.trim().isEmpty
          ? 'English'
          : userLanguage.trim(),
      'hint_place_type': hintPlaceType.trim().isEmpty
          ? 'temple'
          : hintPlaceType.trim(),
    };
  }
}

class CultureVisionResult {
  const CultureVisionResult({
    required this.detectedObject,
    required this.placeType,
    required this.confidence,
    required this.alternatives,
    required this.needsConfirmation,
    required this.sourceType,
    required this.sourceBadge,
    this.detectedObjectSource = 'context_hint',
    this.finalDecision = 'needs_confirmation',
    this.rawLabels = const [],
  });

  final String detectedObject;
  final String placeType;
  final double confidence;
  final List<CultureVisionAlternative> alternatives;
  final bool needsConfirmation;
  final String sourceType;
  final String sourceBadge;
  final String detectedObjectSource;
  final String finalDecision;
  final List<CultureVisionLabelDiagnostic> rawLabels;

  bool get isLowConfidence => confidence < 0.5;

  bool get requiresManualSelection =>
      finalDecision == 'manual_required' ||
      detectedObjectSource == 'no_match' ||
      detectedObject == 'unsupported' ||
      confidence < 0.5;

  bool get isMlKitSuggestion =>
      detectedObjectSource == 'mlkit_suggested' ||
      detectedObjectSource == 'mlkit_auto' ||
      detectedObjectSource == 'mlkit_custom_call_bell';

  String get confirmedObjectSource {
    if (detectedObjectSource == 'mlkit_custom_call_bell') {
      return 'mlkit_custom_call_bell_confirmed';
    }
    if (detectedObjectSource == 'mlkit_suggested' ||
        detectedObjectSource == 'mlkit_auto') {
      return 'mlkit_confirmed';
    }
    return 'vision_confirmed';
  }

  String get label => cultureObjectLabel(detectedObject);

  factory CultureVisionResult.fromJson(Map<String, Object?> json) {
    final detectedObject = _allowedObject(
      _string(json, const ['detected_object', 'detectedObject']),
    );
    final confidence = _double(json, const ['confidence'], 0);
    final sourceType = _string(json, const [
      'source_type',
      'sourceType',
    ], 'vision_heuristic');
    final detectedObjectSource = _visionObjectSource(
      explicit: _string(json, const [
        'detected_object_source',
        'detectedObjectSource',
      ]),
      sourceType: sourceType,
      detectedObject: detectedObject,
    );
    final finalDecision = _visionFinalDecision(
      explicit: _string(json, const ['final_decision', 'finalDecision']),
      sourceType: sourceType,
      detectedObject: detectedObject,
      confidence: confidence,
    );
    return CultureVisionResult(
      detectedObject: detectedObject,
      placeType: _placeTypeFor(
        detectedObject,
        _string(json, const ['place_type', 'placeType']),
      ),
      confidence: confidence,
      alternatives: _alternatives(json['alternatives']),
      needsConfirmation: _bool(json, const [
        'needs_confirmation',
        'needsConfirmation',
      ], true),
      sourceType: sourceType,
      sourceBadge: _string(json, const [
        'source_badge',
        'sourceBadge',
      ], 'Context hint'),
      detectedObjectSource: detectedObjectSource,
      finalDecision: finalDecision,
      rawLabels: _rawLabels(json['raw_labels'] ?? json['rawLabels']),
    );
  }

  factory CultureVisionResult.heuristic(CultureVisionRequest request) {
    final detectedObject = _heuristicObject(request);
    final placeType = _placeTypeFor(detectedObject, request.hintPlaceType);
    return CultureVisionResult(
      detectedObject: detectedObject,
      placeType: placeType,
      confidence: 0.42,
      alternatives: [
        CultureVisionAlternative(
          detectedObject: detectedObject,
          placeType: placeType,
          label: cultureObjectLabel(detectedObject),
          confidence: 0.42,
        ),
      ],
      needsConfirmation: true,
      sourceType: 'vision_heuristic',
      sourceBadge: 'Context hint',
      detectedObjectSource: 'context_hint',
      finalDecision: 'manual_required',
    );
  }

  factory CultureVisionResult.noMatch(
    CultureVisionRequest request, {
    List<CultureVisionLabelDiagnostic> rawLabels = const [],
  }) {
    return CultureVisionResult(
      detectedObject: 'unsupported',
      placeType: request.hintPlaceType.trim().isEmpty
          ? 'unknown'
          : request.hintPlaceType.trim(),
      confidence: 0,
      alternatives: const [],
      needsConfirmation: true,
      sourceType: 'vision_no_match',
      sourceBadge: 'Manual selection',
      detectedObjectSource: 'no_match',
      finalDecision: 'manual_required',
      rawLabels: rawLabels,
    );
  }

  CultureScanRequest toCultureScanRequest({
    required CultureScanRequest base,
    required String detectedObjectSource,
    String? imagePath,
  }) {
    return base.copyWith(
      currentLocation: _locationFor(placeType, base.currentLocation),
      placeType: placeType,
      detectedObject: detectedObject,
      koreanKeyword: cultureObjectKoreanKeyword(detectedObject),
      userQuestion: cultureObjectDefaultQuestion(detectedObject),
      imagePath: imagePath,
      detectedObjectSource: detectedObjectSource,
      visionConfidence: confidence,
      visionAlternatives: alternatives.map((item) => item.toJson()).toList(),
      visionSourceType: sourceType,
      visionSourceBadge: sourceBadge,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'detected_object': detectedObject,
      'place_type': placeType,
      'confidence': confidence,
      'alternatives': alternatives.map((item) => item.toJson()).toList(),
      'needs_confirmation': needsConfirmation,
      'source_type': sourceType,
      'source_badge': sourceBadge,
      'detected_object_source': detectedObjectSource,
      'final_decision': finalDecision,
      if (rawLabels.isNotEmpty)
        'raw_labels': rawLabels.map((item) => item.toJson()).toList(),
    };
  }
}

class CultureVisionLabelDiagnostic {
  const CultureVisionLabelDiagnostic({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  Map<String, Object?> toJson() {
    return {'label': label, 'confidence': confidence};
  }
}

class CultureVisionAlternative {
  const CultureVisionAlternative({
    required this.detectedObject,
    required this.placeType,
    required this.label,
    required this.confidence,
  });

  final String detectedObject;
  final String placeType;
  final String label;
  final double confidence;

  factory CultureVisionAlternative.fromJson(Map<String, Object?> json) {
    final detectedObject = _allowedObject(
      _string(json, const ['detected_object', 'detectedObject', 'object_key']),
    );
    return CultureVisionAlternative(
      detectedObject: detectedObject,
      placeType: _placeTypeFor(
        detectedObject,
        _string(json, const ['place_type', 'placeType']),
      ),
      label: _string(json, const ['label'], cultureObjectLabel(detectedObject)),
      confidence: _double(json, const ['confidence'], 0),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'detected_object': detectedObject,
      'place_type': placeType,
      'label': label,
      'confidence': confidence,
    };
  }
}

const _objectPlaceTypes = {
  'temple_stone_stack': 'temple',
  'restaurant_call_bell': 'restaurant',
  'subway_pregnant_seat': 'subway',
  'cafe_quiet_work': 'cafe',
  'kiosk_ordering': 'restaurant',
  'market_cash_food': 'market',
  'market_queue_ticket': 'market',
  'palace_photo_etiquette': 'palace',
  'hanok_resident_etiquette': 'hanok_village',
  'waiting_number_ticket': 'restaurant',
};

const _objectLabels = {
  'temple_stone_stack': 'Temple stone stack',
  'restaurant_call_bell': 'Restaurant call bell',
  'subway_pregnant_seat': 'Pregnant priority seat',
  'cafe_quiet_work': 'Quiet cafe work',
  'kiosk_ordering': 'Kiosk ordering',
  'market_cash_food': 'Market cash and food',
  'market_queue_ticket': 'Market queue ticket',
  'palace_photo_etiquette': 'Photo etiquette',
  'hanok_resident_etiquette': 'Hanok resident etiquette',
  'waiting_number_ticket': 'Waiting number ticket',
};

const _objectKeywords = {
  'temple_stone_stack': '소원 성취',
  'restaurant_call_bell': '여기요',
  'subway_pregnant_seat': '임산부 배려석',
  'cafe_quiet_work': '조용히 할게요',
  'kiosk_ordering': '도와주실 수 있나요?',
  'market_cash_food': '카드 돼요?',
  'market_queue_ticket': '대기표',
  'palace_photo_etiquette': '사진 찍어도 되나요?',
  'hanok_resident_etiquette': '조용히 지나갈게요',
  'waiting_number_ticket': '대기번호',
};

const _objectQuestions = {
  'temple_stone_stack': 'Why do Koreans stack stones here?',
  'restaurant_call_bell': 'Is it polite to press the call bell?',
  'subway_pregnant_seat': 'Can I sit in the pink subway seat?',
  'cafe_quiet_work': 'Why is everyone so quiet in this cafe?',
  'kiosk_ordering': 'Should I order at the kiosk?',
  'market_cash_food': 'Can I pay by card and eat while walking?',
  'market_queue_ticket': 'Why are people taking number tickets?',
  'palace_photo_etiquette': 'Can I take photos here?',
  'hanok_resident_etiquette': 'Why are there quiet signs in the village?',
  'waiting_number_ticket': 'How do waiting numbers work?',
};

String cultureObjectLabel(String objectKey) {
  return _objectLabels[objectKey.trim()] ?? 'Unsupported travel situation';
}

String cultureObjectKoreanKeyword(String objectKey) {
  return _objectKeywords[objectKey.trim()] ?? '문화 상황';
}

String cultureObjectDefaultQuestion(String objectKey) {
  return _objectQuestions[objectKey.trim()] ?? 'What should I do here?';
}

String _allowedObject(String? value) {
  final normalized = value?.trim();
  return _objectPlaceTypes.containsKey(normalized)
      ? normalized!
      : 'unsupported';
}

String _placeTypeFor(String objectKey, String? value) {
  final normalized = value?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return _objectPlaceTypes[_allowedObject(objectKey)] ?? 'unknown';
}

String _visionObjectSource({
  required String explicit,
  required String sourceType,
  required String detectedObject,
}) {
  if (explicit.trim().isNotEmpty) return explicit.trim();
  if (sourceType == 'vision_ai' && detectedObject != 'unsupported') {
    return 'vision_provider';
  }
  if (sourceType == 'vision_no_match' || detectedObject == 'unsupported') {
    return 'no_match';
  }
  return 'context_hint';
}

String _visionFinalDecision({
  required String explicit,
  required String sourceType,
  required String detectedObject,
  required double confidence,
}) {
  if (explicit.trim().isNotEmpty) return explicit.trim();
  if (sourceType == 'vision_no_match' ||
      detectedObject == 'unsupported' ||
      confidence < 0.5) {
    return 'manual_required';
  }
  if (sourceType == 'vision_ai' && confidence >= 0.75) {
    return 'auto_confirm_possible';
  }
  return 'needs_confirmation';
}

String _locationFor(String placeType, String fallback) {
  if (fallback.trim().isNotEmpty && fallback != 'Bulguksa') {
    return fallback.trim();
  }
  return switch (placeType) {
    'palace' => 'Gyeongbokgung Palace',
    'restaurant' => 'Korean restaurant',
    'cafe' => 'Seoul cafe',
    'subway' => 'Seoul subway',
    'market' => 'Gwangjang Market',
    'hanok_village' => 'Bukchon Hanok Village',
    _ => 'Bulguksa',
  };
}

String _heuristicObject(CultureVisionRequest request) {
  final text = [
    request.hintPlaceType,
    request.currentLocation,
  ].join(' ').toLowerCase();
  if (text.contains('subway') || text.contains('metro')) {
    return 'subway_pregnant_seat';
  }
  if (text.contains('market') && text.contains('queue')) {
    return 'market_queue_ticket';
  }
  if (text.contains('market')) return 'market_cash_food';
  if (text.contains('hanok')) return 'hanok_resident_etiquette';
  if (text.contains('palace')) return 'palace_photo_etiquette';
  if (text.contains('cafe')) return 'cafe_quiet_work';
  if (text.contains('restaurant')) return 'restaurant_call_bell';
  return 'temple_stone_stack';
}

List<CultureVisionAlternative> _alternatives(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            CultureVisionAlternative.fromJson(Map<String, Object?>.from(item)),
      )
      .toList(growable: false);
}

List<CultureVisionLabelDiagnostic> _rawLabels(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) {
        final json = Map<String, Object?>.from(item);
        final label = _string(json, const ['label']);
        if (label.isEmpty) return null;
        return CultureVisionLabelDiagnostic(
          label: label,
          confidence: _double(json, const ['confidence'], 0),
        );
      })
      .whereType<CultureVisionLabelDiagnostic>()
      .toList(growable: false);
}

String _string(
  Map<String, Object?> json,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
  }
  return fallback;
}

bool _bool(Map<String, Object?> json, List<String> keys, bool fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
  }
  return fallback;
}

double _double(Map<String, Object?> json, List<String> keys, double fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble().clamp(0, 1).toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed.clamp(0, 1).toDouble();
    }
  }
  return fallback;
}
