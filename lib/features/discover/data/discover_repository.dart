import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';
import 'package:norigo/features/discover/domain/discover_recommendation_result.dart';

abstract class DiscoverRepository {
  const DiscoverRepository();

  Future<DiscoverRecommendationResult> fetchRecommendations({
    required DiscoverCategory category,
    String query = '',
    int limit = 10,
  });

  Future<DiscoverSaveResult> savePlace(DiscoverPlace place);
}

class DiscoverSaveResult {
  const DiscoverSaveResult({
    required this.saved,
    required this.localOnly,
    this.message,
  });

  final bool saved;
  final bool localOnly;
  final String? message;
}

class SupabaseDiscoverRepository extends DiscoverRepository {
  const SupabaseDiscoverRepository({
    this.config = const SupabaseConfig(),
    this.fallbackRepository = const LocalDiscoverRepository(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final DiscoverRepository fallbackRepository;
  final http.Client? _client;

  @override
  Future<DiscoverRecommendationResult> fetchRecommendations({
    required DiscoverCategory category,
    String query = '',
    int limit = 10,
  }) async {
    if (!config.isConfigured) {
      return fallbackRepository.fetchRecommendations(
        category: category,
        query: query,
        limit: limit,
      );
    }

    final requestBody = {
      'user_language': 'English',
      'base_location': 'Myeongdong, Seoul',
      'current_lat': null,
      'current_lng': null,
      'category': category.apiValue,
      'query': query,
      'limit': limit,
    };

    try {
      final response = await _post(
        Uri.parse('${_baseUrl()}/functions/v1/discover-recommendations'),
        requestBody,
      );
      if (!_isSuccess(response.statusCode)) {
        return _fallback(
          category: category,
          query: query,
          limit: limit,
          errorMessage: 'Discover backend returned ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return _fallback(
          category: category,
          query: query,
          limit: limit,
          errorMessage: 'Discover backend returned an unexpected payload.',
        );
      }

      final result = DiscoverRecommendationResult.fromJson(
        Map<String, Object?>.from(decoded),
        category,
      );
      if (result.places.isEmpty) {
        return DiscoverRecommendationResult(
          category: category,
          sourceType: result.sourceType,
          sourceBadge: result.sourceBadge,
          places: const [],
        );
      }
      return result;
    } catch (_) {
      return _fallback(
        category: category,
        query: query,
        limit: limit,
        errorMessage:
            'Using local recommendations while Discover sync warms up.',
      );
    }
  }

  @override
  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async {
    if (!config.isConfigured) {
      return fallbackRepository.savePlace(place);
    }

    try {
      final response = await _post(
        Uri.parse('${_baseUrl()}/rest/v1/saved_places'),
        place.toSavedPlaceJson(SupabaseAuthSession.userId),
        prefer: 'return=minimal',
      );
      if (_isSuccess(response.statusCode)) {
        return const DiscoverSaveResult(saved: true, localOnly: false);
      }
      return DiscoverSaveResult(
        saved: true,
        localOnly: true,
        message: _looksLikeMissingTable(response.body)
            ? 'Saved locally. The saved_places table is not ready yet.'
            : 'Saved locally. Cloud sync is not available right now.',
      );
    } catch (_) {
      return const DiscoverSaveResult(
        saved: true,
        localOnly: true,
        message: 'Saved locally. Cloud sync is not available right now.',
      );
    }
  }

  Future<DiscoverRecommendationResult> _fallback({
    required DiscoverCategory category,
    required String query,
    required int limit,
    String? errorMessage,
  }) async {
    final result = await fallbackRepository.fetchRecommendations(
      category: category,
      query: query,
      limit: limit,
    );
    return DiscoverRecommendationResult.localFallback(
      category: category,
      places: result.places,
      errorMessage: errorMessage,
    );
  }

  Future<http.Response> _post(Uri uri, Object body, {String prefer = ''}) {
    final client = _client;
    final headers = {..._headers(), if (prefer.isNotEmpty) 'Prefer': prefer};
    final encoded = jsonEncode(body);
    if (client != null) {
      return client.post(uri, headers: headers, body: encoded);
    }
    return http.post(uri, headers: headers, body: encoded);
  }

  Map<String, String> _headers() {
    final authToken = SupabaseAuthSession.accessToken ?? config.anonKey;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  String _baseUrl() => config.url.replaceAll(RegExp(r'/+$'), '');

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static bool _looksLikeMissingTable(String body) {
    final normalized = body.toLowerCase();
    return normalized.contains('saved_places') &&
        (normalized.contains('schema cache') ||
            normalized.contains('does not exist') ||
            normalized.contains('not found'));
  }
}

class LocalDiscoverRepository extends DiscoverRepository {
  const LocalDiscoverRepository();

  static const _imageGarden = 'assets/images/discover/spot_garden_cafe.png';
  static const _imageDessert = 'assets/images/discover/spot_dessert.png';
  static const _imageBookstore = 'assets/images/discover/spot_bookstore.png';

  static const _places = [
    DiscoverPlace(
      id: 'yeonnam-small-garden',
      name: 'Yeonnam Small Garden',
      subtitle: 'quiet garden cafe',
      description: 'A calm garden cafe tucked behind Yeonnam streets.',
      category: DiscoverCategory.quietCafe,
      tags: ['Quiet', 'Local pick', 'Photo-friendly'],
      localImageAsset: _imageGarden,
      latitude: 37.5629,
      longitude: 126.9247,
      walkingMinutes: 5,
      diversityScore: 92,
      localVisitRatio: 68,
      crowdLevel: 'Low crowd',
      riskScore: 18,
      rating: 4.7,
      reviewCount: 128,
      sourceType: 'local_fallback',
      sourceBadge: 'Demo fallback',
      seoulAreaName: 'HONGDAE',
    ),
    DiscoverPlace(
      id: 'dear-dessert',
      name: 'Dear Dessert',
      subtitle: 'handmade seasonal desserts',
      description:
          'A small dessert room with seasonal fruit and lighter waits.',
      category: DiscoverCategory.dessert,
      tags: ['Local pick', 'Sweet spot', 'Quiet'],
      localImageAsset: _imageDessert,
      latitude: 37.5563,
      longitude: 126.9062,
      walkingMinutes: 7,
      diversityScore: 88,
      localVisitRatio: 76,
      crowdLevel: 'Low crowd',
      riskScore: 16,
      rating: 4.8,
      reviewCount: 96,
      sourceType: 'local_fallback',
      sourceBadge: 'Demo fallback',
      seoulAreaName: 'MANGWON',
    ),
    DiscoverPlace(
      id: 'page-turn',
      name: 'Page Turn',
      subtitle: 'independent bookstore & cultural space',
      description: 'A quiet bookstore cafe near galleries and old lanes.',
      category: DiscoverCategory.culture,
      tags: ['Cultural space', 'Quiet', 'Local pick'],
      localImageAsset: _imageBookstore,
      latitude: 37.5798,
      longitude: 126.9694,
      walkingMinutes: 9,
      diversityScore: 90,
      localVisitRatio: 61,
      crowdLevel: 'Low crowd',
      riskScore: 22,
      rating: 4.6,
      reviewCount: 74,
      sourceType: 'local_fallback',
      sourceBadge: 'Demo fallback',
      seoulAreaName: 'SEOCHON',
    ),
    DiscoverPlace(
      id: 'market-bowl',
      name: 'Market Bowl',
      subtitle: 'local food counter',
      description: 'A simple market lunch counter with steady local traffic.',
      category: DiscoverCategory.localFood,
      tags: ['Local food', 'High local ratio', 'Low crowd'],
      localImageAsset: _imageDessert,
      latitude: 37.5702,
      longitude: 126.9995,
      walkingMinutes: 8,
      diversityScore: 86,
      localVisitRatio: 72,
      crowdLevel: 'Low crowd',
      riskScore: 24,
      rating: 4.5,
      reviewCount: 88,
      sourceType: 'local_fallback',
      sourceBadge: 'Demo fallback',
      seoulAreaName: 'GWANGJANG',
    ),
    DiscoverPlace(
      id: 'hanok-frame',
      name: 'Hanok Frame',
      subtitle: 'quiet photo lane',
      description: 'A soft morning photo spot away from the main tour flow.',
      category: DiscoverCategory.photoSpot,
      tags: ['Photo-friendly', 'Quiet', 'Culture'],
      localImageAsset: _imageGarden,
      latitude: 37.5815,
      longitude: 126.9849,
      walkingMinutes: 6,
      diversityScore: 89,
      localVisitRatio: 64,
      crowdLevel: 'Low crowd',
      riskScore: 21,
      rating: 4.7,
      reviewCount: 112,
      sourceType: 'local_fallback',
      sourceBadge: 'Demo fallback',
      seoulAreaName: 'BUKCHON',
    ),
  ];

  @override
  Future<DiscoverRecommendationResult> fetchRecommendations({
    required DiscoverCategory category,
    String query = '',
    int limit = 10,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = _places
        .where((place) {
          final matchesCategory =
              place.category == category ||
              place.tags.any(
                (tag) =>
                    tag.toLowerCase().contains(category.label.toLowerCase()),
              );
          final matchesQuery =
              normalizedQuery.isEmpty ||
              place.name.toLowerCase().contains(normalizedQuery) ||
              place.subtitle.toLowerCase().contains(normalizedQuery) ||
              place.description.toLowerCase().contains(normalizedQuery) ||
              place.tags.any(
                (tag) => tag.toLowerCase().contains(normalizedQuery),
              );
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);

    final places = filtered.isEmpty && normalizedQuery.isEmpty
        ? _places.take(3).toList(growable: false)
        : filtered.take(limit).toList(growable: false);

    return DiscoverRecommendationResult.localFallback(
      category: category,
      places: places,
    );
  }

  @override
  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async {
    return const DiscoverSaveResult(
      saved: true,
      localOnly: true,
      message: 'Saved locally for this session.',
    );
  }
}
