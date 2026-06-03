import 'dart:async';

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
      expect(controller.sourceLabel, 'Demo fallback');

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
    expect(controller.errorMessage, 'Unable to reach KTO OpenAPI + ennoia.');

    controller.dispose();
  });

  test('saving failure does not crash and keeps itinerary visible', () async {
    final controller = AiItineraryController(
      ennoiaRepository: const _StaticRepository(
        sourceType: 'kto_openapi_ennoia',
        failSave: true,
      ),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
      demoAuthService: const _StaticDemoAuthService(true),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());
    final saved = await controller.saveCurrentPlan();

    expect(saved, isFalse);
    expect(controller.plan?.items, hasLength(5));
    expect(
      controller.persistenceLabel,
      'Generated, but not saved to Supabase.',
    );
    expect(
      controller.takeSnackBarMessage(),
      'Generated, but not saved to Supabase.',
    );

    controller.dispose();
  });

  test(
    'server-persisted itinerary shows saved state without client insert',
    () async {
      final controller = AiItineraryController(
        ennoiaRepository: const _StaticRepository(
          sourceType: 'ennoia_kto_mcp',
          persisted: true,
        ),
        fallbackRepository: const _StaticRepository(sourceType: 'mock'),
      );

      await controller.generateItinerary(ItineraryAgentRequest.defaults());

      expect(controller.plan?.items, hasLength(5));
      expect(controller.sourceLabel, 'ennoia + KTO MCP');
      expect(controller.persistenceLabel, 'Saved to Supabase');
      expect(controller.persistedPlanId, 'plan-1');
      expect(controller.status, AiItineraryStatus.loaded);

      final saved = await controller.saveCurrentPlan();

      expect(saved, isTrue);
      expect(controller.persistenceLabel, 'Saved to Supabase');

      controller.dispose();
    },
  );

  test('KTO OpenAPI itinerary shows the new source badge', () async {
    final controller = AiItineraryController(
      ennoiaRepository: const _StaticRepository(
        sourceType: 'kto_openapi_ennoia',
        persisted: true,
      ),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());

    expect(controller.plan?.items, hasLength(5));
    expect(controller.sourceLabel, 'KTO OpenAPI + ennoia');
    expect(controller.persistenceLabel, 'Saved to Supabase');
    expect(controller.persistedPlanId, 'plan-1');

    controller.dispose();
  });

  test('controller prevents duplicate concurrent generation', () async {
    final repository = _PendingRepository(sourceType: 'kto_openapi_ennoia');
    final controller = AiItineraryController(
      ennoiaRepository: repository,
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
    );

    final first = controller.generateItinerary(
      ItineraryAgentRequest.defaults(),
    );
    final second = controller.generateItinerary(
      ItineraryAgentRequest.defaults(),
    );

    expect(repository.generateCount, 1);

    repository.complete();
    await Future.wait([first, second]);

    expect(controller.status, AiItineraryStatus.loaded);
    expect(controller.plan?.items, hasLength(5));

    controller.dispose();
  });

  test('fallback source type displays Demo fallback', () async {
    final controller = AiItineraryController(
      ennoiaRepository: const _StaticRepository(
        sourceType: 'kto_openapi_fallback',
        persisted: true,
      ),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());

    expect(controller.sourceLabel, 'Demo fallback');
    expect(controller.persistenceLabel, 'Saved to Supabase');

    controller.dispose();
  });

  test('unsaved edge result remains visible with evidence label', () async {
    final controller = AiItineraryController(
      ennoiaRepository: const _StaticRepository(
        sourceType: 'kto_openapi_ennoia',
      ),
      fallbackRepository: const _StaticRepository(sourceType: 'mock'),
    );

    await controller.generateItinerary(ItineraryAgentRequest.defaults());

    expect(controller.plan?.items, hasLength(5));
    expect(controller.sourceLabel, 'KTO OpenAPI + ennoia');
    expect(
      controller.persistenceLabel,
      'Generated, but not saved to Supabase.',
    );

    controller.dispose();
  });
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

class _PendingRepository implements EnnoiaAgentRepository {
  _PendingRepository({required this.sourceType});

  final String sourceType;
  final _completer = Completer<ItineraryAgentResult>();
  int generateCount = 0;

  void complete() {
    _completer.complete(
      ItineraryAgentResult.mock(sourceType: sourceType, persisted: true),
    );
  }

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
    generateCount += 1;
    return _completer.future;
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
  ) async {}

  @override
  Future<void> saveReTripEvent(
    RetripAgentRequest request,
    RetripAgentResult result,
  ) async {}
}
