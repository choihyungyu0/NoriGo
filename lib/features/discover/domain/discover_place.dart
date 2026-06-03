import 'package:norigo/features/discover/domain/discover_category.dart';

class DiscoverPlace {
  const DiscoverPlace({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.walkingMinutes,
    required this.diversityScore,
    required this.localVisitRatio,
    required this.crowdLevel,
    required this.riskScore,
    required this.rating,
    required this.reviewCount,
    required this.sourceType,
    required this.sourceBadge,
    this.imageUrl,
    this.localImageAsset,
    this.ktoContentId,
    this.seoulAreaName,
    this.isSaved = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final DiscoverCategory category;
  final List<String> tags;
  final String? imageUrl;
  final String? localImageAsset;
  final double latitude;
  final double longitude;
  final int walkingMinutes;
  final int diversityScore;
  final int localVisitRatio;
  final String crowdLevel;
  final int riskScore;
  final double rating;
  final int reviewCount;
  final String sourceType;
  final String sourceBadge;
  final String? ktoContentId;
  final String? seoulAreaName;
  final bool isSaved;

  DiscoverPlace copyWith({bool? isSaved}) {
    return DiscoverPlace(
      id: id,
      name: name,
      subtitle: subtitle,
      description: description,
      category: category,
      tags: tags,
      imageUrl: imageUrl,
      localImageAsset: localImageAsset,
      latitude: latitude,
      longitude: longitude,
      walkingMinutes: walkingMinutes,
      diversityScore: diversityScore,
      localVisitRatio: localVisitRatio,
      crowdLevel: crowdLevel,
      riskScore: riskScore,
      rating: rating,
      reviewCount: reviewCount,
      sourceType: sourceType,
      sourceBadge: sourceBadge,
      ktoContentId: ktoContentId,
      seoulAreaName: seoulAreaName,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  factory DiscoverPlace.fromJson(Map<String, Object?> json) {
    return DiscoverPlace(
      id: _string(json['id']) ?? _slug(_string(json['name']) ?? 'place'),
      name: _string(json['name']) ?? 'Hidden spot',
      subtitle:
          _string(json['subtitle']) ??
          _string(json['description']) ??
          'Local recommendation',
      description:
          _string(json['description']) ??
          _string(json['subtitle']) ??
          'A quieter local place recommended by NoriGo.',
      category: DiscoverCategory.fromApiValue(_string(json['category'])),
      tags: _stringList(json['tags']),
      imageUrl: _string(json['image_url']) ?? _string(json['imageUrl']),
      localImageAsset:
          _string(json['local_image_asset']) ??
          _string(json['localImageAsset']),
      latitude: _double(json['latitude']) ?? 37.5665,
      longitude: _double(json['longitude']) ?? 126.9780,
      walkingMinutes: _int(json['walking_minutes']) ?? 5,
      diversityScore: _int(json['diversity_score']) ?? 90,
      localVisitRatio: _int(json['local_visit_ratio']) ?? 68,
      crowdLevel: _string(json['crowd_level']) ?? 'Low crowd',
      riskScore: _int(json['risk_score']) ?? 20,
      rating: _double(json['rating']) ?? 4.7,
      reviewCount: _int(json['review_count']) ?? 96,
      sourceType: _string(json['source_type']) ?? 'local_fallback',
      sourceBadge: _string(json['source_badge']) ?? 'Demo fallback',
      ktoContentId:
          _string(json['kto_content_id']) ?? _string(json['ktoContentId']),
      seoulAreaName:
          _string(json['seoul_area_name']) ?? _string(json['seoulAreaName']),
      isSaved: json['is_saved'] == true || json['isSaved'] == true,
    );
  }

  Map<String, Object?> toSavedPlaceJson(String? userId) {
    return {
      'user_id': ?userId,
      'place_name': name,
      'category': category.label,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'tags': tags,
      'source_type': sourceType,
      'source_badge': sourceBadge,
      'kto_content_id': ktoContentId,
      'raw_json': {
        'id': id,
        'subtitle': subtitle,
        'description': description,
        'local_image_asset': localImageAsset,
        'walking_minutes': walkingMinutes,
        'diversity_score': diversityScore,
        'local_visit_ratio': localVisitRatio,
        'crowd_level': crowdLevel,
        'risk_score': riskScore,
        'rating': rating,
        'review_count': reviewCount,
        'seoul_area_name': seoulAreaName,
      },
    };
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

  static double? _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
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

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'hidden-spot' : slug;
  }
}
