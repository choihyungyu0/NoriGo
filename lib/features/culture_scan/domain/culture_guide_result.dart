import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

class CultureGuideResult {
  const CultureGuideResult({
    required this.question,
    required this.description,
    required this.meaning,
    required this.etiquette,
    required this.story,
    required this.koreanPhrase,
    required this.pronunciation,
    required this.phraseMeaning,
    required this.confidence,
    required this.sourceType,
    required this.sourceBadge,
    required this.ennoiaSucceeded,
    required this.persisted,
    required this.cultureScanRecordId,
    required this.scopeLimited,
    required this.locationName,
    required this.placeType,
    required this.detectedObject,
    required this.koreanKeyword,
    this.imagePath,
    this.detectedObjectSource = 'manual',
    this.visionConfidence,
    this.visionSourceType,
    this.visionSourceBadge,
  });

  final String question;
  final String description;
  final String meaning;
  final String etiquette;
  final String story;
  final String koreanPhrase;
  final String pronunciation;
  final String phraseMeaning;
  final double confidence;
  final String sourceType;
  final String sourceBadge;
  final bool ennoiaSucceeded;
  final bool persisted;
  final String cultureScanRecordId;
  final bool scopeLimited;
  final String locationName;
  final String placeType;
  final String detectedObject;
  final String koreanKeyword;
  final String? imagePath;
  final String detectedObjectSource;
  final double? visionConfidence;
  final String? visionSourceType;
  final String? visionSourceBadge;

  bool get isLocalFallback => sourceType == 'culture_local';

  factory CultureGuideResult.fromJson(Map<String, Object?> json) {
    final data = _nestedMap(json) ?? json;
    return CultureGuideResult(
      question: _string(data, const ['question'], 'What should I do here?'),
      description: _string(data, const [
        'description',
        'summary',
        'overview',
      ], 'NoriGo is showing a practical culture guide for this situation.'),
      meaning: _string(data, const ['meaning'], ''),
      etiquette: _string(data, const ['etiquette', 'manners'], ''),
      story: _string(data, const ['story', 'background'], ''),
      koreanPhrase: _string(data, const [
        'korean_phrase',
        'koreanPhrase',
        'koreanSource',
      ], ''),
      pronunciation: _string(data, const ['pronunciation'], ''),
      phraseMeaning: _string(data, const [
        'phrase_meaning',
        'phraseMeaning',
        'translation',
      ], ''),
      confidence: _double(data, const ['confidence'], 0),
      sourceType: _string(data, const [
        'source_type',
        'sourceType',
        'source',
      ], 'culture_fallback'),
      sourceBadge: _string(data, const [
        'source_badge',
        'sourceBadge',
      ], 'Culture Guide'),
      ennoiaSucceeded: _bool(data, const [
        'ennoia_succeeded',
        'ennoiaSucceeded',
      ]),
      persisted: _bool(data, const ['persisted']),
      cultureScanRecordId: _string(data, const [
        'cultureScanRecordId',
        'culture_scan_record_id',
        'id',
      ], ''),
      scopeLimited: _bool(data, const ['scope_limited', 'scopeLimited']),
      locationName: _string(data, const [
        'location_name',
        'locationName',
        'current_location',
      ], 'Bulguksa'),
      placeType: _string(data, const ['place_type', 'placeType'], 'temple'),
      detectedObject: _string(data, const [
        'detected_object',
        'detectedObject',
      ], 'temple_stone_stack'),
      koreanKeyword: _string(data, const [
        'korean_keyword',
        'koreanKeyword',
      ], ''),
      imagePath: _nullableString(data, const ['image_path', 'imagePath']),
      detectedObjectSource: _string(data, const [
        'detected_object_source',
        'detectedObjectSource',
      ], 'manual'),
      visionConfidence: _nullableDouble(data, const [
        'vision_confidence',
        'visionConfidence',
      ]),
      visionSourceType: _nullableString(data, const [
        'vision_source_type',
        'visionSourceType',
      ]),
      visionSourceBadge: _nullableString(data, const [
        'vision_source_badge',
        'visionSourceBadge',
      ]),
    );
  }

  factory CultureGuideResult.readyPreview(CultureScanRequest request) {
    return CultureGuideResult(
      question: request.userQuestion ?? 'What should I do here?',
      description:
          'Scan the current place or choose the visible situation. NoriGo will check Culture DB, ask ennoia when configured, and save the result.',
      meaning:
          'Culture Scan answers the immediate travel context in front of you.',
      etiquette:
          'Pick the closest place and visible object before scanning for a more useful guide.',
      story:
          'Saved scan records appear under My Page after Supabase stores the result.',
      koreanPhrase: request.koreanKeyword,
      pronunciation: '',
      phraseMeaning: 'Useful phrase appears after scan.',
      confidence: 0,
      sourceType: 'culture_ready',
      sourceBadge: 'Ready to scan',
      ennoiaSucceeded: false,
      persisted: false,
      cultureScanRecordId: '',
      scopeLimited: false,
      locationName: request.currentLocation,
      placeType: request.placeType,
      detectedObject: request.detectedObject,
      koreanKeyword: request.koreanKeyword,
      imagePath: request.imagePath,
      detectedObjectSource: request.detectedObjectSource,
      visionConfidence: request.visionConfidence,
      visionSourceType: request.visionSourceType,
      visionSourceBadge: request.visionSourceBadge,
    );
  }

  factory CultureGuideResult.localDemo(CultureScanRequest request) {
    return CultureGuideResult(
      question: request.userQuestion ?? 'Why do Koreans stack stones here?',
      description:
          'NoriGo is using an offline local guide for the selected travel situation.',
      meaning:
          'Stone stacks at temples often represent a quiet wish for peace, health, or good fortune.',
      etiquette:
          'Do not touch existing stacks. If signs allow it, add one small stone gently and keep the area tidy.',
      story:
          'At Korean temples, these stacks are usually treated as personal wishes rather than props.',
      koreanPhrase: request.koreanKeyword.trim().isEmpty
          ? '소원 성취하세요'
          : request.koreanKeyword,
      pronunciation: 'so-won seong-chwi-ha-se-yo',
      phraseMeaning: 'May your wish come true.',
      confidence: 0.35,
      sourceType: 'culture_local',
      sourceBadge: 'Local guide',
      ennoiaSucceeded: false,
      persisted: false,
      cultureScanRecordId: '',
      scopeLimited: false,
      locationName: request.currentLocation,
      placeType: request.placeType,
      detectedObject: request.detectedObject,
      koreanKeyword: request.koreanKeyword,
      imagePath: request.imagePath,
      detectedObjectSource: request.detectedObjectSource,
      visionConfidence: request.visionConfidence,
      visionSourceType: request.visionSourceType,
      visionSourceBadge: request.visionSourceBadge,
    );
  }

  CultureGuide toCultureGuide() {
    return CultureGuide(
      locationName: locationName,
      detectedObject: detectedObjectLabel,
      koreanSource: koreanPhrase.isNotEmpty ? koreanPhrase : koreanKeyword,
      translation: phraseMeaning,
      title: 'AI Culture Guide',
      question: question,
      description: description,
      meaning: meaning,
      etiquette: etiquette,
      story: story,
    );
  }

  String get detectedObjectLabel {
    return detectedObject
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get displaySourceBadge {
    final visionBadge = visionSourceBadge?.trim();
    if (visionBadge == null || visionBadge.isEmpty) return sourceBadge;
    return '$visionBadge · $sourceBadge';
  }

  Map<String, Object?> toJson() {
    return {
      'question': question,
      'description': description,
      'meaning': meaning,
      'etiquette': etiquette,
      'story': story,
      'korean_phrase': koreanPhrase,
      'pronunciation': pronunciation,
      'phrase_meaning': phraseMeaning,
      'confidence': confidence,
      'source_type': sourceType,
      'source_badge': sourceBadge,
      'ennoia_succeeded': ennoiaSucceeded,
      'persisted': persisted,
      'cultureScanRecordId': cultureScanRecordId,
      'scope_limited': scopeLimited,
      'location_name': locationName,
      'place_type': placeType,
      'detected_object': detectedObject,
      'korean_keyword': koreanKeyword,
      if (imagePath != null) 'image_path': imagePath,
      'detected_object_source': detectedObjectSource,
      if (visionConfidence != null) 'vision_confidence': visionConfidence,
      if (visionSourceType != null) 'vision_source_type': visionSourceType,
      if (visionSourceBadge != null) 'vision_source_badge': visionSourceBadge,
    };
  }

  static Map<String, Object?>? _nestedMap(Map<String, Object?> json) {
    for (final key in const [
      'cultureGuide',
      'culture_guide',
      'guide',
      'result',
      'data',
    ]) {
      final value = json[key];
      if (value is Map<String, Object?>) return value;
      if (value is Map) return Map<String, Object?>.from(value);
    }
    return null;
  }

  static String _string(
    Map<String, Object?> json,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) return value.toString();
    }
    return fallback;
  }

  static bool _bool(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
    }
    return false;
  }

  static String? _nullableString(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return null;
  }

  static double _double(
    Map<String, Object?> json,
    List<String> keys,
    double fallback,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double? _nullableDouble(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
