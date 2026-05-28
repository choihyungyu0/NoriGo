import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';

class MockEnnoiaAgentRepository implements EnnoiaAgentRepository {
  const MockEnnoiaAgentRepository();

  @override
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) async {
    return CultureGuideResult.mock();
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(
    ItineraryAgentRequest request,
  ) async {
    return ItineraryAgentResult.mock();
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    return RetripAgentResult.mock();
  }
}
