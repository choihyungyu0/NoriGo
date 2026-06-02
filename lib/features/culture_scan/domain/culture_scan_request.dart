class CultureScanRequest {
  const CultureScanRequest({
    required this.userLanguage,
    required this.currentLocation,
    required this.placeType,
    required this.detectedObject,
    required this.koreanKeyword,
    required this.userIntent,
    this.userQuestion,
    this.imagePath,
    this.detectedObjectSource = 'manual',
    this.visionConfidence,
    this.visionAlternatives,
    this.visionSourceType,
    this.visionSourceBadge,
  });

  final String userLanguage;
  final String currentLocation;
  final String placeType;
  final String detectedObject;
  final String koreanKeyword;
  final String userIntent;
  final String? userQuestion;
  final String? imagePath;
  final String detectedObjectSource;
  final double? visionConfidence;
  final List<Map<String, Object?>>? visionAlternatives;
  final String? visionSourceType;
  final String? visionSourceBadge;

  factory CultureScanRequest.defaultTemple({String userLanguage = 'English'}) {
    return CultureScanRequest(
      userLanguage: userLanguage,
      currentLocation: 'Bulguksa',
      placeType: 'temple',
      detectedObject: 'temple_stone_stack',
      koreanKeyword: '소원 성취',
      userIntent: 'Understand local culture and etiquette',
      userQuestion: 'Why do Koreans stack stones here?',
    );
  }

  CultureScanRequest copyWith({
    String? userLanguage,
    String? currentLocation,
    String? placeType,
    String? detectedObject,
    String? koreanKeyword,
    String? userIntent,
    String? userQuestion,
    String? imagePath,
    String? detectedObjectSource,
    double? visionConfidence,
    List<Map<String, Object?>>? visionAlternatives,
    String? visionSourceType,
    String? visionSourceBadge,
  }) {
    return CultureScanRequest(
      userLanguage: userLanguage ?? this.userLanguage,
      currentLocation: currentLocation ?? this.currentLocation,
      placeType: placeType ?? this.placeType,
      detectedObject: detectedObject ?? this.detectedObject,
      koreanKeyword: koreanKeyword ?? this.koreanKeyword,
      userIntent: userIntent ?? this.userIntent,
      userQuestion: userQuestion ?? this.userQuestion,
      imagePath: imagePath ?? this.imagePath,
      detectedObjectSource: detectedObjectSource ?? this.detectedObjectSource,
      visionConfidence: visionConfidence ?? this.visionConfidence,
      visionAlternatives: visionAlternatives ?? this.visionAlternatives,
      visionSourceType: visionSourceType ?? this.visionSourceType,
      visionSourceBadge: visionSourceBadge ?? this.visionSourceBadge,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user_language': _fallback(userLanguage, 'English'),
      'current_location': _fallback(currentLocation, 'Bulguksa'),
      'place_type': _fallback(placeType, 'temple'),
      'detected_object': _fallback(detectedObject, 'temple_stone_stack'),
      'korean_keyword': _fallback(koreanKeyword, '소원 성취'),
      'user_intent': _fallback(
        userIntent,
        'Understand local culture and etiquette',
      ),
      if (_hasText(userQuestion)) 'user_question': userQuestion!.trim(),
      if (_hasText(imagePath)) 'image_path': imagePath!.trim(),
      'detected_object_source': _fallback(detectedObjectSource, 'manual'),
      if (visionConfidence != null) 'vision_confidence': visionConfidence,
      if (visionAlternatives != null) 'vision_alternatives': visionAlternatives,
      if (_hasText(visionSourceType)) 'vision_source_type': visionSourceType,
      if (_hasText(visionSourceBadge)) 'vision_source_badge': visionSourceBadge,
    };
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
