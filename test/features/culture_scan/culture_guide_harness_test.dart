import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/clients/ai_client.dart';
import 'package:norigo/ai/clients/mock_ai_client.dart';
import 'package:norigo/ai/harness/culture_guide_harness.dart';
import 'package:norigo/features/culture_scan/data/culture_guide_mock_data.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_context.dart';

void main() {
  test('MockAiClient returns the culture guide response', () async {
    final response = await const MockAiClient().completeJson(
      prompt: 'prompt',
      context: CultureGuideMockData.defaultContext.toJson(),
    );

    expect(response['title'], 'AI Culture Guide');
    expect(response['koreanSource'], '소원성취');
  });

  test(
    'CultureGuideHarness applies fallback values for empty context',
    () async {
      final guide = await const CultureGuideHarness(client: MockAiClient())
          .generateGuide(
            const CultureScanContext(
              userLanguage: '',
              currentLocation: '',
              detectedObject: '',
              culturalKeyword: '',
              userIntent: '',
              outputSections: [],
            ),
          );

      expect(guide.locationName, 'Bulguksa');
      expect(guide.detectedObject, 'Stone stack');
      expect(guide.meaning, isNotEmpty);
    },
  );

  test(
    'CultureGuideHarness hides AI errors and returns safe fallback',
    () async {
      final guide = await const CultureGuideHarness(
        client: _ThrowingAiClient(),
      ).generateGuide(CultureGuideMockData.defaultContext);

      expect(guide.title, CultureGuideMockData.fallbackGuide.title);
      expect(guide.etiquette, CultureGuideMockData.fallbackGuide.etiquette);
    },
  );
}

class _ThrowingAiClient implements AiClient {
  const _ThrowingAiClient();

  @override
  Future<Map<String, Object?>> completeJson({
    required String prompt,
    required Map<String, Object?> context,
  }) {
    throw StateError('mock failure');
  }
}
