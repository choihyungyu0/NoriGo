import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';

enum DiscoverLoadState { loading, loaded, empty, error, localFallback }

class DiscoverRecommendationResult {
  const DiscoverRecommendationResult({
    required this.category,
    required this.sourceType,
    required this.sourceBadge,
    required this.places,
    this.errorMessage,
  });

  final DiscoverCategory category;
  final String sourceType;
  final String sourceBadge;
  final List<DiscoverPlace> places;
  final String? errorMessage;

  bool get isLocalFallback => sourceType == 'local_fallback';

  factory DiscoverRecommendationResult.fromJson(
    Map<String, Object?> json,
    DiscoverCategory fallbackCategory,
  ) {
    final rawPlaces = json['places'];
    final places = rawPlaces is List
        ? rawPlaces
              .whereType<Map>()
              .map((item) => DiscoverPlace.fromJson(Map.from(item)))
              .toList(growable: false)
        : const <DiscoverPlace>[];

    final firstPlace = places.isEmpty ? null : places.first;

    return DiscoverRecommendationResult(
      category: DiscoverCategory.fromApiValue(
        json['category'] is String ? json['category'] as String : null,
      ),
      sourceType: json['source_type'] is String
          ? json['source_type'] as String
          : firstPlace?.sourceType ?? 'local_fallback',
      sourceBadge: json['source_badge'] is String
          ? json['source_badge'] as String
          : firstPlace?.sourceBadge ?? 'Demo fallback',
      places: places,
    );
  }

  factory DiscoverRecommendationResult.localFallback({
    required DiscoverCategory category,
    required List<DiscoverPlace> places,
    String? errorMessage,
    String sourceBadge = 'Demo fallback',
  }) {
    return DiscoverRecommendationResult(
      category: category,
      sourceType: 'local_fallback',
      sourceBadge: sourceBadge,
      places: places,
      errorMessage: errorMessage,
    );
  }
}
