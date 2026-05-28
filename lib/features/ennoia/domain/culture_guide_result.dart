import 'package:norigo/features/culture_scan/domain/culture_guide.dart';

class CultureGuideResult {
  const CultureGuideResult({
    required this.locationName,
    required this.detectedObject,
    required this.koreanSource,
    required this.translation,
    required this.title,
    required this.question,
    required this.description,
    required this.meaning,
    required this.etiquette,
    required this.story,
    required this.sourceType,
  });

  final String locationName;
  final String detectedObject;
  final String koreanSource;
  final String translation;
  final String title;
  final String question;
  final String description;
  final String meaning;
  final String etiquette;
  final String story;
  final String sourceType;

  bool get isRealEnnoia => sourceType == 'ennoia';

  factory CultureGuideResult.fromJson(Map<String, Object?> json) {
    final data = _nestedMap(json) ?? json;
    final fallback = CultureGuideResult.mock(sourceType: _sourceType(json));

    return CultureGuideResult(
      locationName: _string(data, const [
        'locationName',
        'location_name',
        'location',
        'current_location',
      ], fallback.locationName),
      detectedObject: _string(data, const [
        'detectedObject',
        'detected_object',
        'object',
      ], fallback.detectedObject),
      koreanSource: _string(data, const [
        'koreanSource',
        'korean_source',
        'koreanKeyword',
        'korean_keyword',
        'keyword',
      ], fallback.koreanSource),
      translation: _string(data, const [
        'translation',
        'translated_text',
        'englishTranslation',
      ], fallback.translation),
      title: _string(data, const ['title'], fallback.title),
      question: _string(data, const [
        'question',
        'headline',
      ], fallback.question),
      description: _string(data, const [
        'description',
        'summary',
        'overview',
      ], fallback.description),
      meaning: _string(data, const ['meaning'], fallback.meaning),
      etiquette: _string(data, const [
        'etiquette',
        'manners',
      ], fallback.etiquette),
      story: _string(data, const ['story', 'background'], fallback.story),
      sourceType: fallback.sourceType,
    );
  }

  factory CultureGuideResult.mock({String sourceType = 'mock'}) {
    return CultureGuideResult(
      locationName: 'Bulguksa',
      detectedObject: 'Stone stack',
      koreanSource: '소원성취',
      translation: 'Wishing for your hopes to come true.',
      title: 'AI Culture Guide',
      question: 'Why do Koreans stack stones here?',
      description:
          'Stone stacking at Bulguksa expresses wishes for happiness, health, and success, and is a tradition passed down for centuries.',
      meaning: 'Each stone carries a wish.',
      etiquette:
          'Do not knock down existing stones. Add your stone with respect.',
      story:
          'This tradition comes from ancient Buddhist beliefs and the hope for peace and well-being.',
      sourceType: sourceType,
    );
  }

  CultureGuide toCultureGuide() {
    return CultureGuide(
      locationName: locationName,
      detectedObject: detectedObject,
      koreanSource: koreanSource,
      translation: translation,
      title: title,
      question: question,
      description: description,
      meaning: meaning,
      etiquette: etiquette,
      story: story,
    );
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

  static String _sourceType(Map<String, Object?> json) {
    final source = json['source'] ?? json['sourceType'] ?? json['source_type'];
    if (source is String && source.trim().toLowerCase() == 'mock') {
      return 'mock';
    }
    return 'ennoia';
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
    }
    return fallback;
  }
}
