import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/ai/context/ai_context.dart';
import 'package:norigo/ai/prompts/norigo_prompt_templates.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';

void main() {
  test('crowd alert prompt includes hidden app queue risk', () {
    final prompt = NoriGoPromptTemplates.crowdAlertExplanation();

    expect(prompt, contains('app-based queues'));
    expect(prompt, contains('Return JSON'));
  });

  test('AI context builder keeps compact traveler context', () {
    final context = AiContextBuilder.fromPreference(
      preference: MockNoriGoData.preference,
      currentLocation: 'Anguk',
      itinerary: MockNoriGoData.itinerary,
      nearbyAlternatives: MockNoriGoData.alertAlternatives,
      crowdForecast: MockNoriGoData.crowdForecast,
    ).toCompactMap();

    expect(context['language'], 'English');
    expect(context['currentLocation'], 'Anguk');
    expect(context['nearbyAlternatives'], isA<List<Object?>>());
  });
}
