import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/my/domain/my_page_summary.dart';

abstract class MyPageRepository {
  const MyPageRepository();

  Future<MyPageSummary> fetchSummary();
}

class SupabaseMyPageRepository extends MyPageRepository {
  const SupabaseMyPageRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<MyPageSummary> fetchSummary() async {
    if (!config.isConfigured) {
      return MyPageSummary.localPreview(errorMessage: 'Local mode');
    }

    final token = SupabaseAuthSession.accessToken;
    if (token == null || token.isEmpty) {
      return MyPageSummary.localPreview(
        errorMessage: 'Sign in to sync your My Page.',
      );
    }

    try {
      var partial = false;
      final user = await _fetchCurrentUser(token);
      final userId = _string(user['id']) ?? '';
      final email = _string(user['email']) ?? '';
      final metadata = _map(user['user_metadata']);

      Future<T> safe<T>(Future<T> Function() load, T fallback) async {
        try {
          return await load();
        } catch (_) {
          partial = true;
          return fallback;
        }
      }

      final profile = userId.isEmpty
          ? const <String, Object?>{}
          : await safe(() => _fetchProfile(userId), const <String, Object?>{});
      final preferences = await safe(
        _fetchLatestPreferences,
        const <String, Object?>{},
      );
      final planOwnershipFilter = userId.isEmpty
          ? const <String, String>{}
          : {'user_id': 'eq.$userId'};
      final planCount = await safe(
        () => _countRows('itinerary_plans', planOwnershipFilter),
        0,
      );
      final savedPlacesCount = await safe(() => _countRows('saved_places'), 0);
      final cultureScansCount = await safe(
        () => _countRows('culture_scan_records'),
        0,
      );
      final retripCount = await safe(() => _countRows('retrip_events'), 0);
      final itineraries = await safe(
        () => _fetchItineraryPreviews(userId),
        const <MyItineraryPlanPreview>[],
      );
      final savedPlaces = await safe(
        _fetchSavedPlacePreviews,
        const <MySavedPlacePreview>[],
      );
      final cultureGuides = await safe(
        _fetchCultureGuidePreviews,
        const <MyCultureGuidePreview>[],
      );
      final retripEvents = await safe(
        _fetchRetripEventPreviews,
        const <MyRetripEventPreview>[],
      );

      final effectivePlanCount = planCount == 0 && itineraries.isNotEmpty
          ? itineraries.length
          : planCount;
      final effectiveSavedPlacesCount =
          savedPlacesCount == 0 && savedPlaces.isNotEmpty
          ? savedPlaces.length
          : savedPlacesCount;
      final effectiveCultureScansCount =
          cultureScansCount == 0 && cultureGuides.isNotEmpty
          ? cultureGuides.length
          : cultureScansCount;
      final effectiveRetripCount = retripCount == 0 && retripEvents.isNotEmpty
          ? retripEvents.length
          : retripCount;
      final xp = _xp(
        planCount: effectivePlanCount,
        savedPlacesCount: effectiveSavedPlacesCount,
        cultureScansCount: effectiveCultureScansCount,
        retripCount: effectiveRetripCount,
      );
      final level = _levelForXp(xp);
      final xpTarget = _targetForLevel(level);
      final minutesSaved =
          await safe(() => _fetchTimeSavedMinutes(userId), 0) ??
          (effectivePlanCount * 35);

      return MyPageSummary(
        displayName:
            _string(profile['display_name']) ??
            _string(profile['displayName']) ??
            _string(profile['full_name']) ??
            _string(metadata['display_name']) ??
            _displayNameFromEmail(email),
        email: email,
        avatarUrl:
            _string(profile['avatar_url']) ?? _string(profile['avatarUrl']),
        levelLabel: _string(profile['level_label']) ?? 'Local Explorer',
        level: _int(profile['level']) ?? level,
        xp: _int(profile['xp']) ?? xp,
        xpTarget: _int(profile['xp_target']) ?? xpTarget,
        locationLabel: _locationLabel(preferences),
        languageLabel:
            _string(preferences['preferred_language']) ??
            _string(preferences['preferredLanguage']) ??
            'English',
        savedPlansCount: effectivePlanCount,
        savedPlacesCount: effectiveSavedPlacesCount,
        cultureScansCount: effectiveCultureScansCount,
        timeSavedLabel: _formatMinutes(minutesSaved),
        interests: _stringList(preferences['interests']),
        foodNeeds:
            _string(preferences['food_needs']) ??
            _string(preferences['foodNeeds']) ??
            'None',
        latestPlanId: itineraries.isEmpty ? null : itineraries.first.id,
        localOnly: false,
        errorMessage: partial ? 'Some My Page data could not be loaded.' : null,
        itineraries: itineraries,
        savedPlaces: savedPlaces,
        cultureGuides: cultureGuides,
        retripEvents: retripEvents,
      );
    } catch (error) {
      return MyPageSummary.localPreview(
        errorMessage: 'Unable to sync My Page right now.',
      );
    }
  }

  Future<Map<String, Object?>> _fetchCurrentUser(String token) async {
    final response = await _get(
      Uri.parse('${_baseUrl()}/auth/v1/user'),
      authorizationToken: token,
    );
    if (!_isSuccess(response.statusCode)) {
      if (response.statusCode == 401) SupabaseAuthSession.clear();
      throw const MyPageRepositoryException('Unable to load current user.');
    }
    return _decodeMap(response.body);
  }

  Future<Map<String, Object?>> _fetchProfile(String userId) async {
    try {
      final byId = await _fetchFirstRow('profiles', {
        'select': '*',
        'id': 'eq.$userId',
        'limit': '1',
      });
      if (byId.isNotEmpty) return byId;
    } catch (_) {
      // Some projects use user_id instead of id for profile ownership.
    }

    try {
      return await _fetchFirstRow('profiles', {
        'select': '*',
        'user_id': 'eq.$userId',
        'limit': '1',
      });
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, Object?>> _fetchLatestPreferences() {
    return _fetchFirstRow('trip_preferences', {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '1',
    });
  }

  Future<List<MyItineraryPlanPreview>> _fetchItineraryPreviews(
    String userId,
  ) async {
    final rows = await _fetchRows('itinerary_plans', {
      'select': '*',
      if (userId.isNotEmpty) 'user_id': 'eq.$userId',
      'order': 'created_at.desc',
      'limit': '8',
    });
    if (rows.isEmpty) return const [];

    final planIds = rows
        .map((row) => _string(row['id']))
        .whereType<String>()
        .toList(growable: false);
    var itemsByPlan = const <String, List<String>>{};
    if (planIds.isNotEmpty) {
      try {
        itemsByPlan = await _fetchItineraryItemNames(planIds, userId);
      } catch (_) {
        itemsByPlan = const <String, List<String>>{};
      }
    }

    return rows
        .map((row) {
          final rawJson = _map(row['raw_json']);
          final id = _string(row['id']) ?? _string(rawJson['id']) ?? 'plan';
          final title =
              _string(row['title']) ??
              _string(rawJson['title']) ??
              'Saved itinerary';
          return MyItineraryPlanPreview(
            id: id,
            title: title,
            createdAtLabel:
                _dateLabel(row['created_at']) ??
                _string(row['date_label']) ??
                _string(rawJson['date_label']) ??
                'Saved plan',
            sourceBadge:
                _string(row['source_badge']) ??
                _string(rawJson['source_badge']) ??
                _string(row['source_type']) ??
                'Saved',
            summary:
                _string(row['summary']) ??
                _string(rawJson['summary']) ??
                'A saved NoriGo itinerary plan.',
            placeNames: itemsByPlan[id] ?? _placeNamesFromRaw(rawJson),
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, List<String>>> _fetchItineraryItemNames(
    List<String> planIds,
    String userId,
  ) async {
    final rows = await _fetchItineraryItemRows(planIds, userId);

    final result = <String, List<String>>{};
    for (final row in rows) {
      final planId = _string(row['plan_id']);
      final placeName = _string(row['place_name']);
      if (planId == null || placeName == null) continue;
      result.putIfAbsent(planId, () => []).add(placeName);
    }
    return result;
  }

  Future<List<Map<String, Object?>>> _fetchItineraryItemRows(
    List<String> planIds,
    String userId,
  ) async {
    final query = {
      'select': '*',
      'plan_id': 'in.(${planIds.join(',')})',
      if (userId.isNotEmpty) 'user_id': 'eq.$userId',
      'order': 'sort_order.asc,created_at.asc',
    };

    try {
      return await _fetchRows('itinerary_items', query);
    } catch (error) {
      if (userId.isNotEmpty && _looksLikeMissingColumn(error, 'user_id')) {
        return _fetchRows('itinerary_items', {
          'select': '*',
          'plan_id': 'in.(${planIds.join(',')})',
          'order': 'sort_order.asc,created_at.asc',
        });
      }
      rethrow;
    }
  }

  Future<List<MySavedPlacePreview>> _fetchSavedPlacePreviews() async {
    final rows = await _fetchRows('saved_places', {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '20',
    });
    return rows
        .map((row) {
          final name =
              _string(row['place_name']) ??
              _string(row['name']) ??
              'Saved place';
          final details = [
            _string(row['category']),
            _string(row['area']),
          ].whereType<String>().join(' in ');
          return MySavedPlacePreview(
            name: name,
            subtitle: details.isEmpty ? 'Saved place' : details,
          );
        })
        .toList(growable: false);
  }

  Future<List<MyCultureGuidePreview>> _fetchCultureGuidePreviews() async {
    final rows = await _fetchRows('culture_scan_records', {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '20',
    });
    return rows
        .map((row) {
          final responseJson = _map(row['response_json']);
          final locationName =
              _string(row['location_name']) ??
              _string(row['location']) ??
              _string(responseJson['location_name']) ??
              'Saved culture guide';
          final detectedObject =
              _string(row['detected_object']) ??
              _string(responseJson['detected_object']) ??
              'culture situation';
          final sourceBadge =
              _string(row['source_badge']) ??
              _string(responseJson['source_badge']) ??
              'Culture Guide';
          final koreanPhrase =
              _string(responseJson['korean_phrase']) ??
              _string(row['korean_phrase']) ??
              '';
          return MyCultureGuidePreview(
            title: locationName,
            subtitle: [
              detectedObject.replaceAll('_', ' '),
              sourceBadge,
              if (koreanPhrase.isNotEmpty) koreanPhrase,
            ].join('\n'),
            createdAtLabel: _dateLabel(row['created_at']) ?? 'Saved',
            locationName: locationName,
            detectedObject: detectedObject,
            sourceBadge: sourceBadge,
            koreanPhrase: koreanPhrase,
          );
        })
        .toList(growable: false);
  }

  Future<List<MyRetripEventPreview>> _fetchRetripEventPreviews() async {
    final rows = await _fetchRows('retrip_events', {
      'select': '*',
      'order': 'created_at.desc',
      'limit': '20',
    });
    return rows
        .map((row) {
          return MyRetripEventPreview(
            originalPlaceName:
                _string(row['original_place_name']) ?? 'Original place',
            triggerType: _string(row['trigger_type']) ?? 'wait_time_help',
            sourceBadge: _string(row['source_badge']) ?? 'Re-Trip',
            createdAtLabel: _dateLabel(row['created_at']) ?? 'Saved',
          );
        })
        .toList(growable: false);
  }

  Future<int?> _fetchTimeSavedMinutes(String userId) async {
    final rows = await _fetchRows('itinerary_plans', {
      'select': '*',
      if (userId.isNotEmpty) 'user_id': 'eq.$userId',
      'order': 'created_at.desc',
      'limit': '25',
    });
    final minutes = rows.fold<int>(0, (sum, row) {
      return sum + _minutesFromRawJson(_map(row['raw_json']));
    });
    return minutes == 0 ? null : minutes;
  }

  Future<int> _countRows(
    String table, [
    Map<String, String> filters = const {},
  ]) async {
    final response = await _get(
      _restUri(table, {'select': '*', ...filters}),
      extraHeaders: const {'Prefer': 'count=exact', 'Range': '0-0'},
    );
    if (!_isSuccess(response.statusCode)) {
      throw MyPageRepositoryException(
        'Unable to count $table: ${response.body}',
      );
    }
    return _countFromContentRange(response.headers['content-range']) ??
        _decodeList(response.body).length;
  }

  Future<Map<String, Object?>> _fetchFirstRow(
    String table,
    Map<String, String> query,
  ) async {
    final rows = await _fetchRows(table, query);
    return rows.isEmpty ? const {} : rows.first;
  }

  Future<List<Map<String, Object?>>> _fetchRows(
    String table,
    Map<String, String> query,
  ) async {
    final response = await _get(_restUri(table, query));
    if (!_isSuccess(response.statusCode)) {
      throw MyPageRepositoryException(
        'Unable to load $table: ${response.body}',
      );
    }
    return _decodeList(response.body)
        .whereType<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }

  Future<http.Response> _get(
    Uri uri, {
    String? authorizationToken,
    Map<String, String> extraHeaders = const {},
  }) {
    final client = _client;
    final headers = {..._headers(authorizationToken), ...extraHeaders};
    if (client != null) return client.get(uri, headers: headers);
    return http.get(uri, headers: headers);
  }

  Map<String, String> _headers(String? authorizationToken) {
    final token = authorizationToken ?? SupabaseAuthSession.accessToken;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer ${token ?? config.anonKey}',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Uri _restUri(String table, Map<String, String> query) {
    return Uri.parse('$_baseRest/$table').replace(queryParameters: query);
  }

  String get _baseRest => '${_baseUrl()}/rest/v1';

  String _baseUrl() => config.url.replaceAll(RegExp(r'/+$'), '');

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static Map<String, Object?> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
    throw const MyPageRepositoryException('Expected a JSON object.');
  }

  static List<Object?> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw const MyPageRepositoryException('Expected a JSON list.');
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    return const {};
  }

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map(_string).whereType<String>().toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static String _displayNameFromEmail(String email) {
    final localPart = email.trim().split('@').first;
    return localPart.isEmpty ? 'Traveler' : localPart;
  }

  static String _locationLabel(Map<String, Object?> preferences) {
    return _string(preferences['base_location']) ??
        _string(preferences['baseLocation']) ??
        _string(preferences['destination']) ??
        'Exploring Seoul';
  }

  static List<String> _placeNamesFromRaw(Map<String, Object?> rawJson) {
    final items = rawJson['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => _string(item['place_name']) ?? _string(item['title']))
        .whereType<String>()
        .take(3)
        .toList(growable: false);
  }

  static int _minutesFromRawJson(Map<String, Object?> rawJson) {
    final minuteFields = [
      rawJson['time_saved_minutes'],
      rawJson['timeSavedMinutes'],
    ];
    for (final field in minuteFields) {
      final parsed = _int(field);
      if (parsed != null) return parsed;
    }

    final label =
        _string(rawJson['time_saved']) ??
        _string(rawJson['estimated_time_saved']) ??
        _string(rawJson['estimatedTimeSaved']);
    if (label == null) return 0;

    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(label.toLowerCase());
    final minuteMatch = RegExp(r'(\d+)\s*m').firstMatch(label.toLowerCase());
    final hours = int.tryParse(hourMatch?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(minuteMatch?.group(1) ?? '') ?? 0;
    return hours * 60 + minutes;
  }

  static int? _countFromContentRange(String? value) {
    if (value == null || !value.contains('/')) return null;
    return int.tryParse(value.split('/').last);
  }

  static String? _dateLabel(Object? value) {
    final raw = _string(value);
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static String _formatMinutes(int? minutes) {
    final value = minutes ?? 0;
    if (value <= 0) return '0m';
    if (value < 60) return '${value}m';
    final hours = value ~/ 60;
    final remainingMinutes = value % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  static int _xp({
    required int planCount,
    required int savedPlacesCount,
    required int cultureScansCount,
    required int retripCount,
  }) {
    return planCount * 300 +
        savedPlacesCount * 50 +
        cultureScansCount * 80 +
        retripCount * 120;
  }

  static int _levelForXp(int xp) => (xp ~/ 1500 + 1).clamp(1, 9);

  static int _targetForLevel(int level) => (level * 1500).clamp(1000, 12000);

  static bool _looksLikeMissingColumn(Object error, String columnName) {
    final text = error.toString().toLowerCase();
    final column = columnName.toLowerCase();
    return text.contains(column) &&
        (text.contains('column') || text.contains('schema cache'));
  }
}

class MyPageRepositoryException implements Exception {
  const MyPageRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'MyPageRepositoryException: $message';
}
