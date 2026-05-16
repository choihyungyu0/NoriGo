abstract class AiClient {
  Future<Map<String, Object?>> complete({
    required String prompt,
    required Map<String, Object?> context,
  });
}

class MockAiClient implements AiClient {
  const MockAiClient();

  @override
  Future<Map<String, Object?>> complete({
    required String prompt,
    required Map<String, Object?> context,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (prompt.contains('app-based queues')) {
      return {
        'title': 'Switch before the waitlist closes',
        'message':
            'Cafe Arte is likely already filling through app queues. A nearby quiet cafe can save time without changing the mood of your day.',
        'risk': 'Very High',
        'suggestedAction':
            'Choose Cafe Owall or another low-crowd alternative.',
      };
    }

    return {
      'title': 'Local-friendly suggestion ready',
      'message':
          'NoriGo found a calmer option using your interests and crowd preference.',
    };
  }
}
