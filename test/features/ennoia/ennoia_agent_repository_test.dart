import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';

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

  test(
    'supabase itinerary uses signed-in access token for function auth',
    () async {
      SupabaseAuthSession.updateAccessToken('user-session-token');
      addTearDown(SupabaseAuthSession.clear);
      Map<String, String>? capturedHeaders;

      final repository = SupabaseEnnoiaAgentRepository(
        config: const SupabaseConfig(
          url: 'https://project.supabase.co',
          anonKey: 'anon-key',
        ),
        client: MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response(
            jsonEncode({
              'source_type': 'kto_openapi_ennoia',
              'items': [
                {
                  'place_name': 'Gyeongbokgung Palace',
                  'kto_content_id': '264337',
                },
              ],
            }),
            200,
          );
        }),
      );

      await repository.fetchItinerary(ItineraryAgentRequest.defaults());

      expect(capturedHeaders?['apikey'], 'anon-key');
      expect(capturedHeaders?['Authorization'], 'Bearer user-session-token');
    },
  );

  test('itinerary parser keeps KTO OpenAPI enrichment fields', () {
    final result = ItineraryAgentResult.fromJson({
      'source_type': 'kto_openapi_ennoia',
      'source_badge': 'KTO OpenAPI + ennoia',
      'source_note': 'Real KTO candidates were used.',
      'title': 'Palace + market route',
      'summary': 'A dynamic route from KTO data.',
      'items': [
        {
          'order': 1,
          'time': '09:00',
          'place_name': 'Gyeongbokgung Palace',
          'kto_content_id': '264337',
          'reason': 'Strong palace match.',
          'culture_tip': 'Keep voices low near ceremonial areas.',
          'stay_time': 'Stay 1h 30m',
          'crowd_level': 'low',
          'firstimage': 'https://example.com/palace.jpg',
          'addr1': 'Seoul Jongno-gu',
          'mapx': '126.977',
          'mapy': '37.579',
        },
      ],
    });
    final plan = result.toItineraryPlan();

    expect(result.sourceType, 'kto_openapi_ennoia');
    expect(result.isRealEnnoia, isTrue);
    expect(plan.sourceBadge, 'KTO OpenAPI + ennoia');
    expect(plan.summary, 'A dynamic route from KTO data.');
    expect(plan.items.first.contentId, '264337');
    expect(plan.items.first.aiTip, 'Strong palace match.');
    expect(
      plan.items.first.cultureTip,
      'Keep voices low near ceremonial areas.',
    );
    expect(plan.items.first.imageUrl, 'https://example.com/palace.jpg');
    expect(plan.items.first.address, 'Seoul Jongno-gu');
  });

  test('mock retrip returns three alternatives', () async {
    final result = await const MockEnnoiaAgentRepository().fetchRetrip(
      RetripAgentRequest.defaults(),
    );

    expect(result.alternatives, hasLength(3));
    expect(result.toCrowdAlert().alternatives, hasLength(3));
    expect(result.sourceType, 'mock_ennoia');
  });
}
