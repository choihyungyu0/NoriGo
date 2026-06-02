import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';

void main() {
  test('CultureGuide parses fields and fills missing values from fallback', () {
    final guide = CultureGuide.fromJson({
      'locationName': 'Bulguksa',
      'detectedObject': 'Stone stack',
      'koreanSource': '소원성취',
      'translation': 'Wishing for your hopes to come true.',
      'title': 'AI Culture Guide',
      'question': '',
      'meaning': 'Each stone carries a wish.',
    }, fallback: CultureGuideMockData.fallbackGuide);

    expect(guide.locationName, 'Bulguksa');
    expect(guide.meaning, 'Each stone carries a wish.');
    expect(guide.question, CultureGuideMockData.fallbackGuide.question);
    expect(guide.etiquette, CultureGuideMockData.fallbackGuide.etiquette);
  });

  test('CultureGuideResult parses vision metadata', () {
    final result = CultureGuideResult.fromJson({
      'question': 'What should I do?',
      'description': 'Guide.',
      'meaning': 'Meaning.',
      'etiquette': 'Etiquette.',
      'story': 'Story.',
      'source_type': 'culture_db_ennoia',
      'source_badge': 'Culture DB + ennoia',
      'detected_object_source': 'vision_confirmed',
      'vision_confidence': 0.84,
      'vision_source_type': 'vision_ai',
      'vision_source_badge': 'Vision AI',
      'image_path': 'user-1/scan.jpg',
    });

    expect(result.detectedObjectSource, 'vision_confirmed');
    expect(result.visionConfidence, 0.84);
    expect(result.visionSourceBadge, 'Vision AI');
    expect(result.imagePath, 'user-1/scan.jpg');
    expect(result.displaySourceBadge, 'Vision AI · Culture DB + ennoia');
  });
}
