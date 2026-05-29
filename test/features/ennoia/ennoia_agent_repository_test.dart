import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';

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

  test('itinerary parser accepts Edge Function persistence metadata', () {
    final result = ItineraryAgentResult.fromJson({
      'source': 'ennoia',
      'dateLabel': 'May 18, Sun',
      'title': 'AI Itinerary Planner',
      'estimatedTimeSaved': '1h',
      'persistence': {'saved': true, 'id': 'plan-1'},
      'items': List.generate(
        5,
        (index) => {
          'id': 'stop-$index',
          'order': index + 1,
          'time': '0$index:00',
          'placeName': 'KTO Stop $index',
          'crowdLevel': 'low',
          'stayTime': 'Stay 1h',
          'aiTip': 'KTO-backed stop',
          'kto_content_id': 1000 + index,
        },
      ),
    });

    expect(result.isRealEnnoia, isTrue);
    expect(result.persisted, isTrue);
    expect(result.persistedPlanId, 'plan-1');
    expect(result.items.first.contentId, '1000');
  });

  test('mock retrip returns three alternatives', () async {
    final result = await const MockEnnoiaAgentRepository().fetchRetrip(
      RetripAgentRequest.defaults(),
    );

    expect(result.alternatives, hasLength(3));
    expect(result.toCrowdAlert().alternatives, hasLength(3));
    expect(result.sourceType, 'mock');
  });

  test('supabase repository saves ennoia results to REST tables', () async {
    final rowsByTable = <String, Map<String, Object?>>{};
    final repository = SupabaseEnnoiaAgentRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        final table = request.url.pathSegments.last;
        rowsByTable[table] = Map<String, Object?>.from(
          jsonDecode(request.body) as Map,
        );

        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer anon-key');
        expect(request.headers['apikey'], 'anon-key');
        return http.Response('', 201);
      }),
    );

    await repository.saveCultureScanRecord(
      CultureGuideAgentRequest.defaults(),
      CultureGuideResult.mock(sourceType: 'ennoia'),
    );
    await repository.saveItineraryPlan(
      ItineraryAgentRequest.defaults(),
      ItineraryAgentResult.mock(sourceType: 'ennoia'),
    );
    await repository.saveReTripEvent(
      RetripAgentRequest.defaults(),
      RetripAgentResult.mock(sourceType: 'ennoia'),
    );

    expect(
      rowsByTable.keys,
      containsAll(['culture_scan_records', 'itinerary_plans', 'retrip_events']),
    );
    expect(
      rowsByTable['culture_scan_records']?['source_type'],
      'ennoia_kto_mcp',
    );
    expect(rowsByTable['itinerary_plans']?['raw_json'], isA<Map>());
    expect(rowsByTable['retrip_events']?['trigger_type'], 'crowd_spike');
  });
}
