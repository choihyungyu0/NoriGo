import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/itinerary/data/supabase_itinerary_repository.dart';

void main() {
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
}
