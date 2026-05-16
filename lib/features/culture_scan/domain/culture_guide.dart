class CultureGuide {
  const CultureGuide({
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

  factory CultureGuide.fromJson(
    Map<String, Object?> json, {
    required CultureGuide fallback,
  }) {
    return CultureGuide(
      locationName: _stringOrFallback(
        json['locationName'],
        fallback.locationName,
      ),
      detectedObject: _stringOrFallback(
        json['detectedObject'],
        fallback.detectedObject,
      ),
      koreanSource: _stringOrFallback(
        json['koreanSource'],
        fallback.koreanSource,
      ),
      translation: _stringOrFallback(json['translation'], fallback.translation),
      title: _stringOrFallback(json['title'], fallback.title),
      question: _stringOrFallback(json['question'], fallback.question),
      description: _stringOrFallback(json['description'], fallback.description),
      meaning: _stringOrFallback(json['meaning'], fallback.meaning),
      etiquette: _stringOrFallback(json['etiquette'], fallback.etiquette),
      story: _stringOrFallback(json['story'], fallback.story),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'locationName': locationName,
      'detectedObject': detectedObject,
      'koreanSource': koreanSource,
      'translation': translation,
      'title': title,
      'question': question,
      'description': description,
      'meaning': meaning,
      'etiquette': etiquette,
      'story': story,
    };
  }

  static String _stringOrFallback(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
