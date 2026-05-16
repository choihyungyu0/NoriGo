import 'package:norigo/ai/clients/ai_client.dart';

class MockAiClient implements AiClient {
  const MockAiClient();

  @override
  Future<Map<String, Object?>> completeJson({
    required String prompt,
    required Map<String, Object?> context,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));

    return {
      'locationName': context['currentLocation'] as String? ?? 'Bulguksa',
      'detectedObject': context['detectedObject'] as String? ?? 'Stone stack',
      'koreanSource': context['culturalKeyword'] as String? ?? '소원성취',
      'translation': 'Wishing for your hopes to come true.',
      'title': 'AI Culture Guide',
      'question': 'Why do Koreans stack stones here?',
      'description':
          'Stone stacking at Bulguksa expresses wishes for happiness, health, and success, and is a tradition passed down for centuries.',
      'meaning': 'Each stone carries a wish.',
      'etiquette':
          'Do not knock down existing stones. Add your stone with respect.',
      'story':
          'This tradition comes from ancient Buddhist beliefs and the hope for peace and well-being.',
    };
  }
}
