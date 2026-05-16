class CultureScanContext {
  const CultureScanContext({
    required this.userLanguage,
    required this.currentLocation,
    required this.detectedObject,
    required this.culturalKeyword,
    required this.userIntent,
    required this.outputSections,
  });

  final String userLanguage;
  final String currentLocation;
  final String detectedObject;
  final String culturalKeyword;
  final String userIntent;
  final List<String> outputSections;

  CultureScanContext withFallbacks() {
    return CultureScanContext(
      userLanguage: _fallback(userLanguage, 'English'),
      currentLocation: _fallback(currentLocation, 'Bulguksa'),
      detectedObject: _fallback(detectedObject, 'Stone stack'),
      culturalKeyword: _fallback(culturalKeyword, '소원성취'),
      userIntent: _fallback(
        userIntent,
        'Understand local culture and etiquette',
      ),
      outputSections: outputSections.isEmpty
          ? const ['Meaning', 'Etiquette', 'Story']
          : outputSections,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userLanguage': userLanguage,
      'currentLocation': currentLocation,
      'detectedObject': detectedObject,
      'culturalKeyword': culturalKeyword,
      'userIntent': userIntent,
      'outputSections': outputSections,
    };
  }

  static String _fallback(String value, String fallback) {
    if (value.trim().isEmpty) return fallback;
    return value.trim();
  }
}
