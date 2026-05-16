import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide.dart';

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
}
