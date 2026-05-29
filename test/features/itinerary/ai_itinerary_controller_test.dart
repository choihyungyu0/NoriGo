import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/auth/demo_auth_service.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';
import 'package:norigo/features/itinerary/application/ai_itinerary_controller.dart';

void main() {
  test(
    'AI itinerary controller falls back to mock if repository fails',
    () async {
      final controller = AiItineraryController(
        ennoiaRepository: _FailingRepository(),
        fallbackRepository: const _StaticRepository(sourceType: 'mock'),
        fallbackOnGenerateFailure: true,
      );

      await controller.generateItinerary(ItineraryAgentRequest.defaults());

      expect(controller.status, AiItineraryStatus.loaded);
      expect(controller.plan?.items, hasLength(5));
      expect(controller.sourceLabel, 'Mock ennoia');

      controller.dispose();
    },
  );

  test('AI itinerary controller surfaces real integration failures', () async {
    final controller = AiItineraryController(
      ennoiaRepository: _FailingRepository(),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());

    expect(controller.status, AiItineraryStatus.error);
    expect(controller.plan, isNull);
    expect(controller.errorMessage, 'Unable to reach ennoia + KTO MCP.');

    controller.dispose();
  });

  test('saving failure does not crash and keeps itinerary visible', () async {
    final controller = AiItineraryController(
      ennoiaRepository: const _StaticRepository(
        sourceType: 'ennoia',
        failSave: true,
      ),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
      demoAuthService: const _StaticDemoAuthService(true),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());

    expect(controller.plan?.items, hasLength(5));
    expect(controller.persistenceLabel, 'Local mock only');
    expect(
      controller.takeSnackBarMessage(),
      'Itinerary generated, but saving requires a Supabase session.',
    );

    controller.dispose();
  });

  test(
    'server-persisted itinerary shows saved state without client insert',
    () async {
      final controller = AiItineraryController(
        ennoiaRepository: const _StaticRepository(
          sourceType: 'ennoia',
          persisted: true,
        ),
        fallbackRepository: const _StaticRepository(sourceType: 'mock'),
      );

      await controller.generateItinerary(ItineraryAgentRequest.defaults());

      expect(controller.plan?.items, hasLength(5));
      expect(controller.sourceLabel, 'ennoia + KTO MCP');
      expect(controller.persistenceLabel, 'Saved to Supabase');
      expect(controller.status, AiItineraryStatus.loaded);

      final saved = await controller.saveCurrentPlan();

      expect(saved, isTrue);
      expect(controller.persistenceLabel, 'Saved to Supabase');

      controller.dispose();
    },
  );
}

class _StaticDemoAuthService extends DemoAuthService {
  const _StaticDemoAuthService(this.result);

  final bool result;

  @override
  Future<bool> ensureDemoSession() async => result;
}

class _FailingRepository implements EnnoiaAgentRepository {
  @override
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) async {
    throw Exception('fail');
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(
    ItineraryAgentRequest request,
  ) async {
    throw Exception('fail');
  }

  @override
  Future<ItineraryAgentResult> generateItinerary(
    ItineraryAgentRequest request,
  ) {
    return fetchItinerary(request);
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    throw Exception('fail');
  }

  @override
  Future<void> saveCultureScanRecord(
    CultureGuideAgentRequest request,
    CultureGuideResult result,
  ) async {}

  @override
  Future<void> saveItineraryPlan(
    ItineraryAgentRequest request,
    ItineraryAgentResult result,
  ) async {}

  @override
  Future<void> saveReTripEvent(
    RetripAgentRequest request,
    RetripAgentResult result,
  ) async {}
}

class _StaticRepository implements EnnoiaAgentRepository {
  const _StaticRepository({
    required this.sourceType,
    this.failSave = false,
    this.persisted = false,
  });

  final String sourceType;
  final bool failSave;
  final bool persisted;

  @override
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) async {
    return CultureGuideResult.mock(sourceType: sourceType);
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(
    ItineraryAgentRequest request,
  ) async {
    return ItineraryAgentResult.mock(
      sourceType: sourceType,
      persisted: persisted,
      persistedPlanId: persisted ? 'plan-1' : null,
    );
  }

  @override
  Future<ItineraryAgentResult> generateItinerary(
    ItineraryAgentRequest request,
  ) {
    return fetchItinerary(request);
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    return RetripAgentResult.mock(sourceType: sourceType);
  }

  @override
  Future<void> saveCultureScanRecord(
    CultureGuideAgentRequest request,
    CultureGuideResult result,
  ) async {}

  @override
  Future<void> saveItineraryPlan(
    ItineraryAgentRequest request,
    ItineraryAgentResult result,
  ) async {
    if (failSave) throw Exception('save failed');
  }

  @override
  Future<void> saveReTripEvent(
    RetripAgentRequest request,
    RetripAgentResult result,
  ) async {}
}
