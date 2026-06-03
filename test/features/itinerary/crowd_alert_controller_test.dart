import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';
import 'package:norigo/features/itinerary/application/crowd_alert_controller.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/data/supabase_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';
import 'package:norigo/features/itinerary/domain/retrip_context.dart';

void main() {
  setUp(ItinerarySessionStore.resetForTesting);

  test('Re-Trip request uses actual itinerary item data', () async {
    final plan = _plan();
    final item = plan.items.first;
    final ennoia = _CapturingRetripRepository();
    final controller = CrowdAlertController(
      repository: _StaticCrowdAlertRepository(_alert(item)),
      ennoiaRepository: ennoia,
      retripContext: RetripContext(plan: plan, item: item),
    );

    await controller.generateRetripAlternatives();

    final request = ennoia.capturedRequest;
    expect(request, isNotNull);
    expect(request!.planId, plan.persistedPlanId);
    expect(request.originalItemId, item.id);
    expect(request.originalPlace, 'Deoksugung Daehanmun');
    expect(request.scheduledTime, '09:00');
    expect(request.currentLocation, contains('Jung-gu, Seoul'));
    expect(request.originalPlaceValue, contains('palace etiquette'));
  });

  test(
    'static Cafe Arte fallback is not used when an item is provided',
    () async {
      final plan = _plan();
      final item = plan.items.first;
      final controller = CrowdAlertController(
        repository: _StaticCrowdAlertRepository(_alert(item)),
        ennoiaRepository: const MockEnnoiaAgentRepository(),
        retripContext: RetripContext(plan: plan, item: item),
      );

      await controller.generateRetripAlternatives();

      expect(controller.alert?.originalPlace, 'Deoksugung Daehanmun');
      expect(controller.alert?.originalPlace, isNot('Cafe Arte'));
    },
  );

  test('Re-Trip parser keeps exactly three alternatives', () {
    final result = RetripAgentResult.fromJson({
      'source_type': 'kto_openapi_ennoia',
      'source_badge': 'KTO OpenAPI + ennoia',
      'alternatives': [
        {'place_name': 'A', 'kto_content_id': '1'},
        {'place_name': 'B', 'kto_content_id': '2'},
        {'place_name': 'C', 'kto_content_id': '3'},
        {'place_name': 'D', 'kto_content_id': '4'},
      ],
    });

    expect(result.alternatives, hasLength(3));
    expect(result.sourceType, 'kto_openapi_ennoia');
    expect(result.sourceBadge, 'KTO OpenAPI + ennoia');
  });

  test('Switch plan updates the in-memory itinerary', () async {
    final plan = _plan();
    final item = plan.items.first;
    ItinerarySessionStore.savePlan(plan);
    final controller = CrowdAlertController(
      repository: _StaticCrowdAlertRepository(_alert(item)),
      ennoiaRepository: _CapturingRetripRepository(),
      retripContext: RetripContext(plan: plan, item: item),
    );

    await controller.loadAlert();
    final switched = await controller.switchToAlternative(_alternative());

    expect(switched, isTrue);
    expect(
      ItinerarySessionStore.currentPlan?.items.first.placeName,
      'Seoul Museum of Art',
    );
  });

  test('DB failure does not crash while selecting a replacement', () async {
    final plan = _plan();
    final item = plan.items.first;
    final controller = CrowdAlertController(
      repository: _FailingSwitchRepository(_alert(item)),
      ennoiaRepository: _CapturingRetripRepository(),
      retripContext: RetripContext(plan: plan, item: item),
    );

    await controller.loadAlert();
    final switched = await controller.switchToAlternative(_alternative());

    expect(switched, isFalse);
    expect(
      controller.errorMessage,
      'Recommendation selected, but plan update could not be saved.',
    );
  });

  test('Supabase switch marks the original item as replaced', () async {
    final requests = <http.Request>[];
    final repository = SupabaseCrowdAlertRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {'sort_order': 1},
            ]),
            200,
          );
        }
        if (request.method == 'PATCH') return http.Response('', 204);
        if (request.method == 'POST') return http.Response('', 201);
        return http.Response('unexpected', 500);
      }),
    );

    await repository.switchToAlternative(
      const CrowdAlert(
        id: 'alert',
        planId: '00000000-0000-4000-8000-000000000001',
        originalItemId: 'deoksugung-daehanmun',
        retripEventId: '00000000-0000-4000-8000-000000000010',
        originalPlace: 'Deoksugung Daehanmun',
        scheduledTime: '09:00',
        crowdLevel: 'Very High',
        estimatedWait: '40-60 min',
        alertMessage: 'Busy soon.',
        foreignerQueueTip: 'Queue tip.',
        alternatives: [],
      ),
      _alternative(),
    );

    expect(requests, hasLength(4));
    expect(requests.first.method, 'GET');
    expect(requests.first.url.query, contains('select=sort_order'));
    expect(requests[1].method, 'PATCH');
    expect(
      requests[1].url.query,
      contains('local_item_id=eq.deoksugung-daehanmun'),
    );
    expect(jsonDecode(requests[1].body), {'status': 'replaced'});
    expect(requests[2].method, 'POST');
    expect(jsonDecode(requests[2].body)['place_name'], 'Seoul Museum of Art');
    expect(jsonDecode(requests[2].body)['sort_order'], 1);
    expect(requests[3].method, 'PATCH');
    expect(
      jsonDecode(requests[3].body)['selected_alternative_json']['place_name'],
      'Seoul Museum of Art',
    );
  });
}

ItineraryPlan _plan() {
  return const ItineraryPlan(
    id: 'local-plan',
    persistedPlanId: '00000000-0000-4000-8000-000000000001',
    dateLabel: 'May 18, Sun',
    title: 'Palace route',
    estimatedTimeSaved: '1h',
    items: [
      ItineraryItem(
        id: 'deoksugung-daehanmun',
        order: 1,
        time: '09:00',
        placeName: 'Deoksugung Daehanmun',
        crowdLevel: ItineraryCrowdLevel.low,
        stayTime: 'Stay 1h',
        aiTip: 'Check palace etiquette signs',
        contentId: '1605981',
        contentTypeId: '12',
        address: 'Jung-gu, Seoul',
        cultureTip: 'palace etiquette',
      ),
    ],
  );
}

CrowdAlert _alert(ItineraryItem item) {
  return CrowdAlert(
    id: 'alert',
    planId: '00000000-0000-4000-8000-000000000001',
    originalItemId: item.id,
    originalPlace: item.placeName,
    scheduledTime: item.time,
    crowdLevel: 'Very High',
    estimatedWait: '40-60 min',
    alertMessage: '${item.placeName} may become very busy within 30 minutes.',
    foreignerQueueTip:
        'Even if no visible line, app-based queues may already be full.',
    alternatives: [_alternative()],
  );
}

AlternativePlace _alternative() {
  return const AlternativePlace(
    id: 'seoul-museum-of-art',
    name: 'Seoul Museum of Art',
    description: 'KTO-listed nearby alternative.',
    walkingTime: '5 min walk',
    diversityScore: 90,
    crowdLevel: 'Low',
    contentId: '130856',
    contentTypeId: '14',
    address: 'Jung-gu, Seoul',
    recommendationCopy: 'Quiet indoor art stop near the palace route.',
  );
}

class _CapturingRetripRepository implements EnnoiaAgentRepository {
  RetripAgentRequest? capturedRequest;

  @override
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(ItineraryAgentRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ItineraryAgentResult> generateItinerary(
    ItineraryAgentRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    capturedRequest = request;
    return RetripAgentResult(
      id: 'alert',
      originalPlace: request.originalPlace,
      scheduledTime: request.scheduledTime,
      crowdLevel: request.crowdLevel,
      estimatedWait: request.estimatedWait,
      alertMessage:
          '${request.originalPlace} may become very busy within 30 minutes.',
      foreignerQueueTip:
          'Even if no visible line, app-based queues may already be full.',
      sourceType: 'kto_openapi_ennoia',
      sourceBadge: 'KTO OpenAPI + ennoia',
      planId: request.planId,
      originalItemId: request.originalItemId,
      alternatives: const [
        RetripAlternativeResult(
          id: 'seoul-museum-of-art',
          name: 'Seoul Museum of Art',
          description: 'KTO-listed nearby alternative.',
          walkingTime: '5 min walk',
          diversityScore: 90,
          crowdLevel: 'Low',
          contentId: '130856',
        ),
      ],
    );
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

class _StaticCrowdAlertRepository implements CrowdAlertRepository {
  const _StaticCrowdAlertRepository(this.alert);

  final CrowdAlert alert;

  @override
  Future<CrowdAlert> fetchCurrentCrowdAlert() async => alert;

  @override
  Future<void> keepOriginalPlan() async {}

  @override
  Future<void> switchToAlternative(
    CrowdAlert alert,
    AlternativePlace alternative,
  ) async {}
}

class _FailingSwitchRepository extends _StaticCrowdAlertRepository {
  const _FailingSwitchRepository(super.alert);

  @override
  Future<void> switchToAlternative(
    CrowdAlert alert,
    AlternativePlace alternative,
  ) async {
    throw StateError('db unavailable');
  }
}
