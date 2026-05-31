import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/itinerary/data/itinerary_repository.dart';
import 'package:norigo/features/itinerary/data/mock_itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class SupabaseItineraryRepository implements ItineraryRepository {
  const SupabaseItineraryRepository({
    this.config = const SupabaseConfig(),
    this.fallbackRepository = const MockItineraryRepository(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final ItineraryRepository fallbackRepository;
  final http.Client? _client;

  @override
  Future<ItineraryPlan> fetchPlan() {
    return fallbackRepository.fetchPlan();
  }

  @override
  Future<ItineraryPlan> savePlan(ItineraryPlan plan) async {
    if (!config.isConfigured) return fallbackRepository.savePlan(plan);

    final planId = await _insertPlan(plan);
    await _insertItems(plan.copyWith(persistedPlanId: planId));
    return plan.copyWith(persistedPlanId: planId);
  }

  Future<String> _insertPlan(ItineraryPlan plan) async {
    final uri = _restUri('itinerary_plans');
    final response = await _post(uri, {
      'title': plan.title,
      'date_label': plan.dateLabel,
      'source_type': plan.sourceType,
      'source_badge': plan.sourceBadge,
      'raw_json': _planJson(plan),
    }, prefer: 'return=representation');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ItineraryPersistenceException(
        'Unable to persist itinerary plan (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final id = decoded.first['id'];
      if (id is String && id.isNotEmpty) return id;
    }

    throw const ItineraryPersistenceException(
      'Supabase did not return a persisted plan id.',
    );
  }

  Future<void> _insertItems(ItineraryPlan plan) async {
    final planId = plan.persistedPlanId;
    if (planId == null || planId.isEmpty || plan.items.isEmpty) return;

    final response = await _post(
      _restUri('itinerary_items'),
      plan.items.map((item) => _itemRow(planId, item)).toList(growable: false),
      prefer: 'return=minimal',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ItineraryPersistenceException(
        'Unable to persist itinerary items (${response.statusCode}).',
      );
    }
  }

  Uri _restUri(String table) {
    return Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/$table',
    );
  }

  Future<http.Response> _post(Uri uri, Object body, {required String prefer}) {
    final encoded = jsonEncode(body);
    final client = _client;
    final headers = {..._headers(), 'Prefer': prefer};
    if (client != null) {
      return client.post(uri, headers: headers, body: encoded);
    }
    return http.post(uri, headers: headers, body: encoded);
  }

  Map<String, String> _headers() {
    final authorizationToken =
        SupabaseAuthSession.accessToken ?? config.anonKey;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $authorizationToken',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Map<String, Object?> _planJson(ItineraryPlan plan) {
    return {
      'id': plan.id,
      'date_label': plan.dateLabel,
      'title': plan.title,
      'estimated_time_saved': plan.estimatedTimeSaved,
      'source_type': plan.sourceType,
      'source_badge': plan.sourceBadge,
      'source_note': plan.sourceNote,
      'summary': plan.summary,
      'items': plan.items.map(_itemJson).toList(growable: false),
    };
  }

  Map<String, Object?> _itemJson(ItineraryItem item) {
    return {
      'id': item.id,
      'order': item.order,
      'time': item.time,
      'place_name': item.placeName,
      'crowd_level': item.crowdLabel,
      'stay_time': item.stayTime,
      'ai_tip': item.aiTip,
      'kto_content_id': item.contentId,
      'content_type_id': item.contentTypeId,
      'address': item.address,
      'image_url': item.imageUrl,
      'culture_tip': item.cultureTip,
      'mapx': item.mapX,
      'mapy': item.mapY,
      'status': item.status,
    };
  }

  Map<String, Object?> _itemRow(String planId, ItineraryItem item) {
    return {
      'plan_id': planId,
      'local_item_id': item.id,
      'sort_order': item.order,
      'time_label': item.time,
      'place_name': item.placeName,
      'kto_content_id': item.contentId,
      'content_type_id': item.contentTypeId,
      'address': item.address,
      'image_url': item.imageUrl,
      'reason': item.aiTip,
      'crowd_level': item.crowdLabel,
      'stay_time': item.stayTime,
      'culture_tip': item.cultureTip,
      'longitude': item.mapX,
      'latitude': item.mapY,
      'status': item.status,
    };
  }
}

class ItineraryPersistenceException implements Exception {
  const ItineraryPersistenceException(this.message);

  final String message;

  @override
  String toString() => 'ItineraryPersistenceException: $message';
}
