import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';

void main() {
  test('mock repository returns a valid CultureGuideResult', () async {
    final result = await const MockEnnoiaAgentRepository().fetchCultureGuide(
      CultureGuideAgentRequest.defaults(),
    );

    expect(result.title, 'AI Culture Guide');
    expect(result.koreanSource, isNotEmpty);
    expect(result.toCultureGuide().question, isNotEmpty);
    expect(result.sourceType, 'mock');
  });

  test('mock itinerary returns five items', () async {
    final result = await const MockEnnoiaAgentRepository().fetchItinerary(
      ItineraryAgentRequest.defaults(),
    );

    expect(result.items, hasLength(5));
    expect(result.toItineraryPlan().items, hasLength(5));
    expect(result.sourceType, 'mock');
  });

  test('mock retrip returns three alternatives', () async {
    final result = await const MockEnnoiaAgentRepository().fetchRetrip(
      RetripAgentRequest.defaults(),
    );

    expect(result.alternatives, hasLength(3));
    expect(result.toCrowdAlert().alternatives, hasLength(3));
    expect(result.sourceType, 'mock');
  });
}
