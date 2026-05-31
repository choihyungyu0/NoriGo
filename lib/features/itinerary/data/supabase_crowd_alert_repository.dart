import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/data/mock_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

class SupabaseCrowdAlertRepository implements CrowdAlertRepository {
  const SupabaseCrowdAlertRepository({
    this.config = const SupabaseConfig(),
    this.fallbackRepository = const MockCrowdAlertRepository(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final CrowdAlertRepository fallbackRepository;
  final http.Client? _client;

  @override
  Future<CrowdAlert> fetchCurrentCrowdAlert() {
    return fallbackRepository.fetchCurrentCrowdAlert();
  }

  @override
  Future<void> keepOriginalPlan() async {
    return fallbackRepository.keepOriginalPlan();
  }

  @override
  Future<void> switchToAlternative(
    CrowdAlert alert,
    AlternativePlace alternative,
  ) async {
    if (!config.isConfigured) return;

    final planId = alert.planId;
    final originalItemId = alert.originalItemId;
    if (planId == null ||
        originalItemId == null ||
        !_looksLikeUuid(planId) ||
        originalItemId.trim().isEmpty) {
      return;
    }

    final sortOrder = await _fetchOriginalSortOrder(planId, originalItemId);
    await _markOriginalItemReplaced(planId, originalItemId);
    await _insertReplacementItem(
      planId,
      originalItemId,
      alert,
      alternative,
      sortOrder,
    );
    await _saveSelectedAlternative(alert.retripEventId, alternative);
  }

  Future<int?> _fetchOriginalSortOrder(
    String planId,
    String originalItemId,
  ) async {
    final response = await _get(
      _restUri('itinerary_items', {
        'plan_id': 'eq.$planId',
        'local_item_id': 'eq.$originalItemId',
        'select': 'sort_order',
        'limit': '1',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CrowdAlertPersistenceException(
        'Unable to read original item order (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final sortOrder = decoded.first['sort_order'];
      if (sortOrder is int) return sortOrder;
      if (sortOrder is num) return sortOrder.toInt();
      if (sortOrder is String) return int.tryParse(sortOrder);
    }
    return null;
  }

  Future<void> _markOriginalItemReplaced(
    String planId,
    String originalItemId,
  ) async {
    final uri = _restUri('itinerary_items', {
      'plan_id': 'eq.$planId',
      'local_item_id': 'eq.$originalItemId',
      'status': 'eq.planned',
    });
    final response = await _patch(uri, {'status': 'replaced'});

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CrowdAlertPersistenceException(
        'Unable to mark original item replaced (${response.statusCode}).',
      );
    }
  }

  Future<void> _insertReplacementItem(
    String planId,
    String originalItemId,
    CrowdAlert alert,
    AlternativePlace alternative,
    int? sortOrder,
  ) async {
    final response = await _post(_restUri('itinerary_items'), {
      'plan_id': planId,
      'local_item_id': alternative.id,
      'time_label': alert.scheduledTime,
      'sort_order': sortOrder,
      'place_name': alternative.name,
      'kto_content_id': alternative.contentId,
      'content_type_id': alternative.contentTypeId,
      'address': alternative.address,
      'image_url': alternative.imageUrl,
      'reason': alternative.recommendationCopy ?? alternative.description,
      'crowd_level': alternative.crowdLevel,
      'stay_time': 'Stay 1h',
      'longitude': alternative.mapX,
      'latitude': alternative.mapY,
      'status': 'planned',
      'replaced_from_local_item_id': originalItemId,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CrowdAlertPersistenceException(
        'Unable to persist replacement item (${response.statusCode}).',
      );
    }
  }

  Future<void> _saveSelectedAlternative(
    String? retripEventId,
    AlternativePlace alternative,
  ) async {
    if (retripEventId == null || !_looksLikeUuid(retripEventId)) return;

    final response = await _patch(
      _restUri('retrip_events', {'id': 'eq.$retripEventId'}),
      {'selected_alternative_json': alternative.toJson()},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CrowdAlertPersistenceException(
        'Unable to persist selected alternative (${response.statusCode}).',
      );
    }
  }

  Uri _restUri(String table, [Map<String, String>? query]) {
    return Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/$table',
    ).replace(queryParameters: query);
  }

  Future<http.Response> _get(Uri uri) {
    final client = _client;
    if (client != null) {
      return client.get(uri, headers: _headers(''));
    }
    return http.get(uri, headers: _headers(''));
  }

  Future<http.Response> _post(Uri uri, Object body) {
    final client = _client;
    final encoded = jsonEncode(body);
    if (client != null) {
      return client.post(
        uri,
        headers: _headers('return=minimal'),
        body: encoded,
      );
    }
    return http.post(uri, headers: _headers('return=minimal'), body: encoded);
  }

  Future<http.Response> _patch(Uri uri, Object body) {
    final client = _client;
    final encoded = jsonEncode(body);
    if (client != null) {
      return client.patch(
        uri,
        headers: _headers('return=minimal'),
        body: encoded,
      );
    }
    return http.patch(uri, headers: _headers('return=minimal'), body: encoded);
  }

  Map<String, String> _headers(String prefer) {
    final authorizationToken =
        SupabaseAuthSession.accessToken ?? config.anonKey;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $authorizationToken',
      'Content-Type': 'application/json; charset=utf-8',
      if (prefer.isNotEmpty) 'Prefer': prefer,
    };
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

class CrowdAlertPersistenceException implements Exception {
  const CrowdAlertPersistenceException(this.message);

  final String message;

  @override
  String toString() => 'CrowdAlertPersistenceException: $message';
}
