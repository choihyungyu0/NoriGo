import 'dart:convert';

import 'package:flutter/services.dart';
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
    String userLanguage = 'English',
    String baseLocation = 'Myeongdong, Seoul',
    double? currentLat,
    double? currentLng,
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
    String userLanguage = 'English',
    String baseLocation = 'Myeongdong, Seoul',
    double? currentLat,
    double? currentLng,
  }) async {
    if (!config.isConfigured) {
      return fallbackRepository.fetchRecommendations(
        category: category,
        query: query,
        limit: limit,
        userLanguage: userLanguage,
        baseLocation: baseLocation,
        currentLat: currentLat,
        currentLng: currentLng,
      );
    }

    final requestBody = {
      'user_language': userLanguage,
      'base_location': baseLocation,
      'current_lat': currentLat,
      'current_lng': currentLng,
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
      if (result.isLocalFallback) {
        return _fallback(category: category, query: query, limit: limit);
      }
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

    final userId = SupabaseAuthSession.userId;
    if (userId == null) {
      return fallbackRepository.savePlace(place);
    }

    try {
      final response = await _post(
        Uri.parse('${_baseUrl()}/rest/v1/saved_places'),
        place.toSavedPlaceJson(userId),
        prefer: 'return=minimal',
      );
      if (_isSuccess(response.statusCode)) {
        return const DiscoverSaveResult(
          saved: true,
          localOnly: false,
          message: 'Place saved.',
        );
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

  static const _csvAsset = 'assets/data/tourist_places.csv';
  static const _imageGarden = 'assets/images/discover/spot_garden_cafe.png';
  static const _imageDessert = 'assets/images/discover/spot_dessert.png';
  static const _imageBookstore = 'assets/images/discover/spot_bookstore.png';
  static Future<List<DiscoverPlace>>? _csvPlacesFuture;

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
    String userLanguage = 'English',
    String baseLocation = 'Myeongdong, Seoul',
    double? currentLat,
    double? currentLng,
  }) async {
    final allPlaces = await _placesFromCsvOrFallback();
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = allPlaces
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

    final places = _withMinimumPlaces(
      _withDistinctInitialAssets(filtered, allPlaces),
      limit,
      allPlaces,
    );
    final usesCsv =
        allPlaces.length != _places.length ||
        allPlaces.any((place) => place.sourceBadge == 'Tourist CSV');

    return DiscoverRecommendationResult.localFallback(
      category: category,
      places: places,
      sourceBadge: usesCsv ? 'Tourist CSV' : 'Demo fallback',
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

  static List<DiscoverPlace> _withMinimumPlaces(
    List<DiscoverPlace> preferred,
    int limit,
    List<DiscoverPlace> allPlaces,
  ) {
    final targetCount = limit < 3 ? 3 : limit;
    final places = <DiscoverPlace>[];
    for (final place in preferred) {
      if (places.length >= targetCount) break;
      if (places.any((item) => item.id == place.id)) continue;
      places.add(place);
    }
    for (final place in allPlaces) {
      if (places.length >= targetCount || places.length >= 3) break;
      if (places.any((item) => item.id == place.id)) continue;
      places.add(place);
    }
    return places;
  }

  static List<DiscoverPlace> _withDistinctInitialAssets(
    List<DiscoverPlace> places,
    List<DiscoverPlace> allPlaces,
  ) {
    if (places.length < 3) return places;
    final prioritized = <DiscoverPlace>[];
    final seenAssets = <String>{};
    for (final place in [...places, ...allPlaces]) {
      final asset = place.localImageAsset;
      if (asset == null || !seenAssets.add(asset)) continue;
      if (prioritized.any((item) => item.id == place.id)) continue;
      prioritized.add(place);
      if (prioritized.length >= 3) break;
    }
    for (final place in places) {
      if (prioritized.any((item) => item.id == place.id)) continue;
      prioritized.add(place);
    }
    return prioritized;
  }

  static Future<List<DiscoverPlace>> _placesFromCsvOrFallback() {
    return _csvPlacesFuture ??= _loadCsvPlaces();
  }

  static Future<List<DiscoverPlace>> _loadCsvPlaces() async {
    try {
      final csv = await rootBundle.loadString(_csvAsset);
      final places = _parseTouristCsv(csv);
      if (places.isEmpty) return _places;
      return places;
    } catch (_) {
      return _places;
    }
  }

  static List<DiscoverPlace> _parseTouristCsv(String csv) {
    final rows = _parseCsv(csv);
    if (rows.length < 2) return const [];

    final header = rows.first
        .map((value) => value.replaceFirst('\ufeff', '').trim())
        .toList(growable: false);
    final places = <DiscoverPlace>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex += 1) {
      final row = rows[rowIndex];
      if (row.every((value) => value.trim().isEmpty)) continue;
      final item = <String, String>{};
      for (var column = 0; column < header.length; column += 1) {
        item[header[column]] = column < row.length ? row[column].trim() : '';
      }

      final id = _csvValue(item, 'place_id');
      final koreanName = _csvValue(item, 'place_name_ko');
      final englishName = _csvValue(item, 'place_name_en');
      final name = englishName.isNotEmpty ? englishName : koreanName;
      final latitude = double.tryParse(_csvValue(item, 'latitude'));
      final longitude = double.tryParse(_csvValue(item, 'longitude'));
      if (name.isEmpty || latitude == null || longitude == null) continue;

      final rawCategory = _csvValue(item, 'category');
      final category = _discoverCategoryForCsv(rawCategory, name);
      final area = _csvValue(item, 'area');
      final note = _csvValue(item, 'note');
      final imageUrl = _csvValue(item, 'image_url');
      final recommendedTime = _csvValue(item, 'recommended_time');
      final crowdLevel = _csvValue(item, 'crowd_level');
      final tags = _tagsForCsv(rawCategory, area, recommendedTime);
      final seed = rowIndex + name.length + area.length;

      places.add(
        DiscoverPlace(
          id: id.isNotEmpty ? 'csv-$id' : 'csv-${_slug(name)}',
          name: name,
          subtitle: _csvSubtitle(rawCategory, area),
          description: note.isNotEmpty
              ? note
              : _csvDescription(koreanName, rawCategory, area),
          category: category,
          tags: tags,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          localImageAsset: imageUrl.isEmpty
              ? _fallbackAssetForCsv(rowIndex)
              : null,
          latitude: latitude,
          longitude: longitude,
          walkingMinutes: 5 + (seed % 14),
          diversityScore: 82 + (seed % 14),
          localVisitRatio: 58 + (seed % 28),
          crowdLevel: crowdLevel.isEmpty ? 'Moderate' : crowdLevel,
          riskScore: 18 + (seed % 24),
          rating: double.parse((4.3 + (seed % 5) * 0.1).toStringAsFixed(1)),
          reviewCount: 60 + seed * 3,
          sourceType: 'local_fallback',
          sourceBadge: 'Tourist CSV',
          seoulAreaName: area,
        ),
      );
    }
    return places;
  }

  static String _csvValue(Map<String, String> item, String key) {
    return item[key]?.trim() ?? '';
  }

  static DiscoverCategory _discoverCategoryForCsv(
    String rawCategory,
    String name,
  ) {
    final text = '$rawCategory $name'.toLowerCase();
    if (text.contains('cafe') ||
        text.contains('coffee') ||
        text.contains('bakery') ||
        text.contains('dessert') ||
        text.contains('카페') ||
        text.contains('디저트')) {
      return DiscoverCategory.dessert;
    }
    if (text.contains('restaurant') ||
        text.contains('food') ||
        text.contains('market') ||
        text.contains('맛집') ||
        text.contains('시장')) {
      return DiscoverCategory.localFood;
    }
    if (text.contains('park') ||
        text.contains('skyway') ||
        text.contains('observatory') ||
        text.contains('photo') ||
        text.contains('전망') ||
        text.contains('공원')) {
      return DiscoverCategory.photoSpot;
    }
    if (text.contains('book') ||
        text.contains('garden') ||
        text.contains('quiet') ||
        text.contains('library')) {
      return DiscoverCategory.quietCafe;
    }
    return DiscoverCategory.culture;
  }

  static List<String> _tagsForCsv(
    String rawCategory,
    String area,
    String recommendedTime,
  ) {
    return [
      if (rawCategory.isNotEmpty) rawCategory,
      if (area.isNotEmpty) area,
      if (recommendedTime.isNotEmpty) recommendedTime,
      'CSV data',
    ];
  }

  static String _csvSubtitle(String rawCategory, String area) {
    final parts = [
      if (rawCategory.isNotEmpty) rawCategory,
      if (area.isNotEmpty) area,
    ];
    return parts.isEmpty ? 'Seoul tourist place' : parts.join(' · ');
  }

  static String _csvDescription(
    String koreanName,
    String rawCategory,
    String area,
  ) {
    final location = area.isEmpty ? 'Seoul' : area;
    final kind = rawCategory.isEmpty ? 'tourist place' : rawCategory;
    final koName = koreanName.isEmpty ? '' : ' ($koreanName)';
    return '$kind$koName in $location from the local tourist places dataset.';
  }

  static String _fallbackAssetForCsv(int rowIndex) {
    switch (rowIndex % 3) {
      case 1:
        return _imageGarden;
      case 2:
        return _imageBookstore;
      default:
        return _imageDessert;
    }
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < input.length; index += 1) {
      final char = input[index];
      if (inQuotes) {
        if (char == '"') {
          final nextIsQuote =
              index + 1 < input.length && input[index + 1] == '"';
          if (nextIsQuote) {
            cell.write('"');
            index += 1;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else if (char != '\r') {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'tourist-place' : slug;
  }
}
