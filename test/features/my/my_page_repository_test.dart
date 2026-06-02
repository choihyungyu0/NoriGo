import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/my/data/my_page_repository.dart';

void main() {
  tearDown(SupabaseAuthSession.clear);

  test('SupabaseMyPageRepository maps REST data into a summary', () async {
    SupabaseAuthSession.updateAccessToken('user-token');
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/auth/v1/user')) {
        return _json({
          'id': 'user-1',
          'email': 'ari@example.com',
          'user_metadata': {'display_name': 'Ari fallback'},
        });
      }

      final table = request.url.pathSegments.last;
      if (request.headers['Range'] == '0-0') {
        return _count(switch (table) {
          'itinerary_plans' => 2,
          'saved_places' => 3,
          'culture_scan_records' => 4,
          'retrip_events' => 1,
          _ => 0,
        });
      }

      return switch (table) {
        'profiles' => _json([
          {
            'display_name': 'Ari Lee',
            'avatar_url': 'https://example.com/ari.png',
          },
        ]),
        'trip_preferences' => _json([
          {
            'base_location': 'Exploring Busan',
            'preferred_language': 'Korean',
            'interests': ['Food', 'Markets'],
            'food_needs': 'Vegetarian',
          },
        ]),
        'itinerary_plans' => _json([
          {
            'id': 'plan-1',
            'title': 'Busan low-crowd route',
            'source_badge': 'KTO OpenAPI + ennoia',
            'summary': 'Quiet route with markets and culture.',
            'user_id': null,
            'raw_json': {'time_saved': '2h'},
            'created_at': '2026-06-02T00:00:00Z',
          },
        ]),
        'itinerary_items' => _json([
          {'plan_id': 'plan-1', 'place_name': 'Gamcheon Culture Village'},
          {'plan_id': 'plan-1', 'place_name': 'Bupyeong Market'},
        ]),
        'saved_places' => _json([
          {'place_name': 'Page Turn', 'category': 'Culture', 'area': 'Seochon'},
        ]),
        'culture_scan_records' => _json([
          {
            'location_name': 'Bulguksa',
            'detected_object': 'temple_stone_stack',
            'source_badge': 'Culture DB',
            'response_json': {'korean_phrase': 'Make a quiet wish'},
            'created_at': '2026-06-01T00:00:00Z',
          },
        ]),
        'retrip_events' => _json([
          {
            'original_place_name': 'Cafe Myeong',
            'trigger_type': 'crowd_spike',
            'source_badge': 'kto_openapi_ennoia',
            'created_at': '2026-06-02T00:00:00Z',
          },
        ]),
        _ => _json([]),
      };
    });

    final repository = SupabaseMyPageRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: client,
    );

    final summary = await repository.fetchSummary();

    expect(summary.localOnly, isFalse);
    expect(summary.displayName, 'Ari Lee');
    expect(summary.locationLabel, 'Exploring Busan');
    expect(summary.languageLabel, 'Korean');
    expect(summary.savedPlansCount, 2);
    expect(summary.savedPlacesCount, 3);
    expect(summary.cultureScansCount, 4);
    expect(summary.timeSavedLabel, '2h');
    expect(summary.itineraries.single.placeNames, [
      'Gamcheon Culture Village',
      'Bupyeong Market',
    ]);
    expect(summary.cultureGuides.single.locationName, 'Bulguksa');
    expect(summary.cultureGuides.single.detectedObject, 'temple_stone_stack');
    expect(summary.cultureGuides.single.sourceBadge, 'Culture DB');
    expect(summary.cultureGuides.single.koreanPhrase, 'Make a quiet wish');
    expect(summary.retripEvents.single.originalPlaceName, 'Cafe Myeong');

    final planRequests = requests
        .where((request) => request.url.path.endsWith('/itinerary_plans'))
        .toList(growable: false);
    expect(planRequests, isNotEmpty);
    for (final request in planRequests) {
      expect(request.url.query, contains('user_id=eq.user-1'));
    }
  });

  test(
    'SupabaseMyPageRepository handles missing itinerary user_id column',
    () async {
      SupabaseAuthSession.updateAccessToken('user-token');
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return _json({
            'id': 'user-1',
            'email': 'ari@example.com',
            'user_metadata': const <String, Object?>{},
          });
        }

        final table = request.url.pathSegments.last;
        if (table == 'itinerary_plans' &&
            request.url.query.contains('user_id=eq.user-1')) {
          return http.Response(
            jsonEncode({
              'message':
                  'column itinerary_plans.user_id does not exist in schema cache',
            }),
            400,
          );
        }
        if (request.headers['Range'] == '0-0') {
          return _count(0);
        }

        return switch (table) {
          'profiles' => _json([]),
          'trip_preferences' => _json([]),
          'saved_places' => _json([]),
          'culture_scan_records' => _json([]),
          'retrip_events' => _json([]),
          _ => _json([]),
        };
      });

      final repository = SupabaseMyPageRepository(
        config: const SupabaseConfig(
          url: 'https://project.supabase.co',
          anonKey: 'anon-key',
        ),
        client: client,
      );

      final summary = await repository.fetchSummary();

      expect(summary.localOnly, isFalse);
      expect(summary.savedPlansCount, 0);
      expect(summary.itineraries, isEmpty);
      expect(summary.errorMessage, 'Some My Page data could not be loaded.');
    },
  );

  test(
    'SupabaseMyPageRepository returns local mode when not configured',
    () async {
      final summary = await const SupabaseMyPageRepository(
        config: SupabaseConfig(),
      ).fetchSummary();

      expect(summary.localOnly, isTrue);
      expect(summary.savedPlansCount, 0);
      expect(summary.savedPlacesCount, 0);
      expect(summary.cultureScansCount, 0);
      expect(summary.timeSavedLabel, '0m');
    },
  );
}

http.Response _json(Object body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: const {'Content-Type': 'application/json'},
  );
}

http.Response _count(int count) {
  return http.Response('[]', 200, headers: {'content-range': '0-0/$count'});
}
