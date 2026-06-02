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
  Future<ItineraryPlan> fetchPlan() async {
    if (!config.isConfigured) return fallbackRepository.fetchPlan();

    final userId = SupabaseAuthSession.userId;
    final latestPlan = await _fetchLatestPlanRow(userId);
    if (latestPlan == null) return fallbackRepository.fetchPlan();

    final planId = _string(latestPlan, 'id');
    if (planId == null) return fallbackRepository.fetchPlan();

    final itemRows = await _fetchPlannedItemRows(planId, userId);
    if (itemRows.isEmpty) return fallbackRepository.fetchPlan();

    return _planFromRows(latestPlan, itemRows);
  }

  @override
  Future<ItineraryPlan> savePlan(ItineraryPlan plan) async {
    if (!config.isConfigured) return fallbackRepository.savePlan(plan);

    final userId = SupabaseAuthSession.userId;
    try {
      final planId = await _insertPlan(plan, userId);
      await _insertItems(plan.copyWith(persistedPlanId: planId), userId);
      return plan.copyWith(persistedPlanId: planId);
    } on ItineraryPersistenceException catch (error) {
      if (userId == null && _isAuthBlocked(error)) {
        return fallbackRepository.savePlan(plan);
      }
      rethrow;
    }
  }

  Future<String> _insertPlan(ItineraryPlan plan, String? userId) async {
    final uri = _restUri('itinerary_plans');
    final row = {
      'title': plan.title,
      'date_label': plan.dateLabel,
      'source_type': plan.sourceType,
      'source_badge': plan.sourceBadge,
      'raw_json': _planJson(plan),
      'user_id': ?userId,
    };
    var response = await _post(uri, row, prefer: 'return=representation');

    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _post(
        uri,
        Map<String, Object?>.from(row)..remove('user_id'),
        prefer: 'return=representation',
      );
    }

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

  Future<void> _insertItems(ItineraryPlan plan, String? userId) async {
    final planId = plan.persistedPlanId;
    if (planId == null || planId.isEmpty || plan.items.isEmpty) return;

    final rows = plan.items
        .map((item) => _itemRow(planId, item, userId))
        .toList(growable: false);
    var response = await _post(
      _restUri('itinerary_items'),
      rows,
      prefer: 'return=minimal',
    );

    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _post(
        _restUri('itinerary_items'),
        rows
            .map((row) => Map<String, Object?>.from(row)..remove('user_id'))
            .toList(growable: false),
        prefer: 'return=minimal',
      );
    }

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

  Uri _restUriWithQuery(String table, Map<String, String> query) {
    return _restUri(table).replace(queryParameters: query);
  }

  Future<Map<String, Object?>?> _fetchLatestPlanRow(String? userId) async {
    var response = await _get(_latestPlanUri(userId));
    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _get(_latestPlanUri(null));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ItineraryPersistenceException(
        'Unable to load latest itinerary plan (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, Object?>.from(decoded.first as Map);
    }
    return null;
  }

  Future<List<Map<String, Object?>>> _fetchPlannedItemRows(
    String planId,
    String? userId,
  ) async {
    var response = await _get(_plannedItemsUri(planId, userId));
    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _get(_plannedItemsUri(planId, null));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ItineraryPersistenceException(
        'Unable to load itinerary items (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }

  ItineraryPlan _planFromRows(
    Map<String, Object?> planRow,
    List<Map<String, Object?>> itemRows,
  ) {
    final rawJson = _map(planRow['raw_json']);
    final planId = _string(planRow, 'id') ?? 'persisted-plan';

    return ItineraryPlan(
      id: _string(rawJson, 'id') ?? planId,
      persistedPlanId: planId,
      dateLabel:
          _string(planRow, 'date_label') ??
          _string(rawJson, 'date_label') ??
          'Today',
      title:
          _string(planRow, 'title') ??
          _string(rawJson, 'title') ??
          'AI Itinerary Planner',
      estimatedTimeSaved: _string(rawJson, 'estimated_time_saved') ?? '1h',
      sourceType:
          _string(planRow, 'source_type') ??
          _string(rawJson, 'source_type') ??
          'kto_openapi_ennoia',
      sourceBadge:
          _string(planRow, 'source_badge') ?? _string(rawJson, 'source_badge'),
      sourceNote: _string(rawJson, 'source_note'),
      summary: _string(rawJson, 'summary'),
      items: itemRows.map(_itemFromRow).toList(growable: false),
    );
  }

  ItineraryItem _itemFromRow(Map<String, Object?> row) {
    final placeName = _string(row, 'place_name') ?? 'Recommended stop';
    final sortOrder = _int(row, 'sort_order') ?? 1;

    return ItineraryItem(
      id: _string(row, 'local_item_id') ?? _slug(placeName),
      order: sortOrder,
      time: _string(row, 'time_label') ?? '09:00',
      placeName: placeName,
      crowdLevel: _crowdLevel(_string(row, 'crowd_level') ?? ''),
      stayTime: _string(row, 'stay_time') ?? 'Stay 1h',
      aiTip: _string(row, 'reason') ?? 'Recommended by ennoia.',
      contentId: _string(row, 'kto_content_id'),
      contentTypeId: _string(row, 'content_type_id'),
      address: _string(row, 'address'),
      imageUrl: _string(row, 'image_url'),
      cultureTip: _string(row, 'culture_tip'),
      mapX: _double(row, 'longitude'),
      mapY: _double(row, 'latitude'),
      status: _string(row, 'status') ?? 'planned',
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

  Future<http.Response> _get(Uri uri) {
    final client = _client;
    if (client != null) {
      return client.get(uri, headers: _headers());
    }
    return http.get(uri, headers: _headers());
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

  Uri _latestPlanUri(String? userId) {
    return _restUriWithQuery('itinerary_plans', {
      'select': '*',
      if (userId != null) 'user_id': 'eq.$userId',
      'order': 'created_at.desc',
      'limit': '1',
    });
  }

  Uri _plannedItemsUri(String planId, String? userId) {
    return _restUriWithQuery('itinerary_items', {
      'plan_id': 'eq.$planId',
      'user_id': ?(userId == null ? null : 'eq.$userId'),
      'status': 'eq.planned',
      'select': '*',
      'order': 'sort_order.asc,created_at.asc',
    });
  }

  Map<String, Object?> _itemRow(
    String planId,
    ItineraryItem item,
    String? userId,
  ) {
    return {
      'plan_id': planId,
      'user_id': ?userId,
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

  static Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    return const {};
  }

  static String? _string(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  static int? _int(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _double(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static ItineraryCrowdLevel _crowdLevel(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('moderate') || normalized.contains('high')
        ? ItineraryCrowdLevel.moderate
        : ItineraryCrowdLevel.low;
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'itinerary-item' : slug;
  }

  static bool _isMissingColumn(http.Response response, String columnName) {
    if (response.statusCode < 400) return false;
    final body = response.body.toLowerCase();
    final column = columnName.toLowerCase();
    return body.contains(column) &&
        (body.contains('column') || body.contains('schema cache'));
  }

  static bool _isAuthBlocked(ItineraryPersistenceException error) {
    return error.message.contains('(401)') || error.message.contains('(403)');
  }
}

class ItineraryPersistenceException implements Exception {
  const ItineraryPersistenceException(this.message);

  final String message;

  @override
  String toString() => 'ItineraryPersistenceException: $message';
}
