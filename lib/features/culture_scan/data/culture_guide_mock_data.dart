import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_context.dart';

class CultureGuideMockData {
  const CultureGuideMockData._();

  static const defaultContext = CultureScanContext(
    userLanguage: 'English',
    currentLocation: 'Bulguksa',
    detectedObject: 'Stone stack',
    culturalKeyword: '소원성취',
    userIntent: 'Understand local culture and etiquette',
    outputSections: ['Meaning', 'Etiquette', 'Story'],
  );

  static const fallbackGuide = CultureGuide(
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
  );
}
