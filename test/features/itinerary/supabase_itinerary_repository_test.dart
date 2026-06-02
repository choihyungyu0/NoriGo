import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/itinerary/data/supabase_itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

void main() {
  tearDown(SupabaseAuthSession.clear);

  test('fetchPlan loads latest persisted replacement item', () async {
    final requests = <http.Request>[];
    final repository = SupabaseItineraryRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/itinerary_plans')) {
          return http.Response(
            jsonEncode([
              {
                'id': '00000000-0000-4000-8000-000000000001',
                'title': 'Updated route',
                'date_label': 'May 18, Sun',
                'source_type': 'kto_openapi_ennoia',
                'source_badge': 'KTO OpenAPI + ennoia',
                'raw_json': {
                  'id': 'local-plan',
                  'estimated_time_saved': '1h',
                  'source_note': 'Real KTO candidates were used.',
                  'summary': 'Updated after Re-Trip.',
                },
              },
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/itinerary_items')) {
          return http.Response(
            jsonEncode([
              {
                'local_item_id': 'seoul-museum-of-art',
                'sort_order': 1,
                'time_label': '09:00',
                'place_name': 'Seoul Museum of Art',
                'kto_content_id': '130856',
                'content_type_id': '14',
                'address': 'Jung-gu, Seoul',
                'image_url': 'https://example.com/museum.jpg',
                'reason': 'Quiet indoor art stop near the palace route.',
                'crowd_level': 'Low',
                'stay_time': 'Stay 1h',
                'culture_tip': 'Check temporary exhibitions.',
                'longitude': 126.973,
                'latitude': 37.566,
                'status': 'planned',
                'replaced_from_local_item_id': 'deoksugung-daehanmun',
              },
            ]),
            200,
          );
        }
        return http.Response('unexpected', 500);
      }),
    );

    final plan = await repository.fetchPlan();

    expect(plan.persistedPlanId, '00000000-0000-4000-8000-000000000001');
    expect(plan.sourceType, 'kto_openapi_ennoia');
    expect(plan.sourceBadge, 'KTO OpenAPI + ennoia');
    expect(plan.sourceNote, 'Real KTO candidates were used.');
    expect(plan.summary, 'Updated after Re-Trip.');
    expect(plan.items, hasLength(1));
    expect(plan.items.first.id, 'seoul-museum-of-art');
    expect(plan.items.first.order, 1);
    expect(plan.items.first.placeName, 'Seoul Museum of Art');
    expect(plan.items.first.contentId, '130856');
    expect(plan.items.first.imageUrl, 'https://example.com/museum.jpg');
    expect(plan.items.first.status, 'planned');
    expect(requests[1].url.query, contains('status=eq.planned'));
    expect(requests[1].url.query, contains('order=sort_order.asc'));
  });

  test('fetchPlan filters persisted plans and items by auth user id', () async {
    const userId = '11111111-1111-4111-8111-111111111111';
    SupabaseAuthSession.updateAccessToken(_jwtForSub(userId));
    final requests = <http.Request>[];
    final repository = SupabaseItineraryRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/itinerary_plans')) {
          return http.Response(
            jsonEncode([
              {
                'id': '00000000-0000-4000-8000-000000000001',
                'title': 'User route',
                'date_label': 'May 18, Sun',
                'source_type': 'kto_openapi_ennoia',
                'source_badge': 'KTO OpenAPI + ennoia',
                'raw_json': {'id': 'local-plan'},
              },
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/itinerary_items')) {
          return http.Response(
            jsonEncode([
              {
                'local_item_id': 'user-stop',
                'sort_order': 1,
                'time_label': '09:00',
                'place_name': 'User Stop',
                'crowd_level': 'Low',
                'stay_time': 'Stay 1h',
                'reason': 'Owned by current user.',
                'status': 'planned',
              },
            ]),
            200,
          );
        }
        return http.Response('unexpected', 500);
      }),
    );

    final plan = await repository.fetchPlan();

    expect(plan.title, 'User route');
    expect(requests.first.url.query, contains('user_id=eq.$userId'));
    expect(requests[1].url.query, contains('user_id=eq.$userId'));
  });

  test('savePlan includes user_id when auth user exists', () async {
    const userId = '22222222-2222-4222-8222-222222222222';
    SupabaseAuthSession.updateAccessToken(_jwtForSub(userId));
    Map<String, Object?>? planRow;
    List<Object?>? itemRows;
    final repository = SupabaseItineraryRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/itinerary_plans')) {
          planRow = Map<String, Object?>.from(jsonDecode(request.body) as Map);
          return http.Response(
            jsonEncode([
              {'id': '00000000-0000-4000-8000-000000000002'},
            ]),
            201,
          );
        }
        if (request.url.path.endsWith('/itinerary_items')) {
          itemRows = List<Object?>.from(jsonDecode(request.body) as List);
          return http.Response('', 201);
        }
        return http.Response('unexpected', 500);
      }),
    );

    final saved = await repository.savePlan(_plan());

    expect(saved.persistedPlanId, '00000000-0000-4000-8000-000000000002');
    expect(planRow?['user_id'], userId);
    final item = Map<String, Object?>.from(itemRows!.single as Map);
    expect(item['user_id'], userId);
  });

  test('savePlan can still persist unauthenticated smoke rows', () async {
    Map<String, Object?>? planRow;
    List<Object?>? itemRows;
    final repository = SupabaseItineraryRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/itinerary_plans')) {
          planRow = Map<String, Object?>.from(jsonDecode(request.body) as Map);
          return http.Response(
            jsonEncode([
              {'id': '00000000-0000-4000-8000-000000000003'},
            ]),
            201,
          );
        }
        if (request.url.path.endsWith('/itinerary_items')) {
          itemRows = List<Object?>.from(jsonDecode(request.body) as List);
          return http.Response('', 201);
        }
        return http.Response('unexpected', 500);
      }),
    );

    await repository.savePlan(_plan());

    expect(planRow!.containsKey('user_id'), isFalse);
    final item = Map<String, Object?>.from(itemRows!.single as Map);
    expect(item.containsKey('user_id'), isFalse);
  });

  test(
    'savePlan falls back safely when unauthenticated insert is blocked',
    () async {
      var requestCount = 0;
      final repository = SupabaseItineraryRepository(
        config: const SupabaseConfig(
          url: 'https://project.supabase.co',
          anonKey: 'anon-key',
        ),
        client: MockClient((request) async {
          requestCount += 1;
          return http.Response(
            jsonEncode({
              'message': 'new row violates row-level security policy',
            }),
            403,
          );
        }),
      );

      final plan = _plan();
      final saved = await repository.savePlan(plan);

      expect(saved.id, plan.id);
      expect(saved.persistedPlanId, isNull);
      expect(requestCount, 1);
    },
  );
}

ItineraryPlan _plan() {
  return const ItineraryPlan(
    id: 'local-plan',
    dateLabel: 'May 18, Sun',
    title: 'Owned route',
    estimatedTimeSaved: '1h',
    sourceType: 'kto_openapi_ennoia',
    sourceBadge: 'KTO OpenAPI + ennoia',
    items: [
      ItineraryItem(
        id: 'owned-stop',
        order: 1,
        time: '09:00',
        placeName: 'Owned Stop',
        crowdLevel: ItineraryCrowdLevel.low,
        stayTime: 'Stay 1h',
        aiTip: 'A useful stop.',
      ),
    ],
  );
}

String _jwtForSub(String sub) {
  String encode(Object value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.'
      '${encode({'sub': sub, 'role': 'authenticated'})}.signature';
}
