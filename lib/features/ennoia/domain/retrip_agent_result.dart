import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

class RetripAgentResult {
  const RetripAgentResult({
    required this.id,
    required this.originalPlace,
    required this.scheduledTime,
    required this.crowdLevel,
    required this.estimatedWait,
    required this.alertMessage,
    required this.foreignerQueueTip,
    required this.alternatives,
    required this.sourceType,
  });

  final String id;
  final String originalPlace;
  final String scheduledTime;
  final String crowdLevel;
  final String estimatedWait;
  final String alertMessage;
  final String foreignerQueueTip;
  final List<RetripAlternativeResult> alternatives;
  final String sourceType;

  bool get isRealEnnoia =>
      sourceType == 'ennoia' ||
      sourceType == 'kto_openapi_ennoia' ||
      sourceType == 'kto_openapi_basic' ||
      sourceType == 'kto_openapi_direct';

  factory RetripAgentResult.fromJson(Map<String, Object?> json) {
    final data = _nestedMap(json) ?? json;
    final fallback = RetripAgentResult.mock(sourceType: _sourceType(json));
    final rawAlternatives = _list(data, const [
      'alternatives',
      'places',
      'recommendations',
      'items',
    ]);
    final alternatives = rawAlternatives
        .whereType<Map>()
        .map((item) => RetripAlternativeResult.fromJson(item))
        .take(3)
        .toList(growable: false);

    return RetripAgentResult(
      id: _string(data, const ['id'], fallback.id),
      originalPlace: _string(data, const [
        'originalPlace',
        'original_place',
      ], fallback.originalPlace),
      scheduledTime: _string(data, const [
        'scheduledTime',
        'scheduled_time',
      ], fallback.scheduledTime),
      crowdLevel: _string(data, const [
        'crowdLevel',
        'crowd_level',
      ], fallback.crowdLevel),
      estimatedWait: _string(data, const [
        'estimatedWait',
        'estimated_wait',
      ], fallback.estimatedWait),
      alertMessage: _string(data, const [
        'alertMessage',
        'alert_message',
        'message',
      ], fallback.alertMessage),
      foreignerQueueTip: _string(data, const [
        'foreignerQueueTip',
        'foreigner_queue_tip',
        'queueTip',
      ], fallback.foreignerQueueTip),
      alternatives: alternatives.isEmpty ? fallback.alternatives : alternatives,
      sourceType: fallback.sourceType,
    );
  }

  factory RetripAgentResult.mock({String sourceType = 'mock'}) {
    return RetripAgentResult(
      id: 'cafe-arte-crowd-alert',
      originalPlace: 'Cafe Arte',
      scheduledTime: '13:00',
      crowdLevel: 'Very High',
      estimatedWait: '40-60 min',
      alertMessage: 'Cafe Arte may become very busy within 30 minutes.',
      foreignerQueueTip:
          'Even if no visible line, app-based queues may already be full.',
      sourceType: sourceType,
      alternatives: const [
        RetripAlternativeResult(
          id: 'cafe-owall',
          name: 'Cafe Owall',
          description: 'Dessert in a calm hanok alley',
          walkingTime: '5 min walk',
          diversityScore: 92,
          crowdLevel: 'Low',
        ),
        RetripAlternativeResult(
          id: 'seosullan-small-book-cafe',
          name: 'Seosullan Small Book Cafe',
          description: 'Quiet book cafe beloved by locals',
          walkingTime: '7 min walk',
          diversityScore: 88,
          crowdLevel: 'Low',
        ),
        RetripAlternativeResult(
          id: 'yunsul-bakery',
          name: 'Yunsul Bakery',
          description: 'Local favorite bakery with short wait',
          walkingTime: '8 min walk',
          diversityScore: 90,
          crowdLevel: 'Low',
        ),
      ],
    );
  }

  CrowdAlert toCrowdAlert() {
    return CrowdAlert(
      id: id,
      originalPlace: originalPlace,
      scheduledTime: scheduledTime,
      crowdLevel: crowdLevel,
      estimatedWait: estimatedWait,
      alertMessage: alertMessage,
      foreignerQueueTip: foreignerQueueTip,
      sourceType: sourceType,
      alternatives: alternatives
          .map((alternative) => alternative.toAlternativePlace())
          .toList(growable: false),
    );
  }

  static Map<String, Object?>? _nestedMap(Map<String, Object?> json) {
    for (final key in const ['retrip', 'reTrip', 'result', 'data']) {
      final value = json[key];
      if (value is Map<String, Object?>) return value;
      if (value is Map) return Map<String, Object?>.from(value);
    }
    return null;
  }

  static String _sourceType(Map<String, Object?> json) {
    final source = json['source'] ?? json['sourceType'] ?? json['source_type'];
    if (source is String && source.trim().isNotEmpty) {
      return source.trim();
    }
    return 'ennoia';
  }

  static List<Object?> _list(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
    return const [];
  }

  static String _string(
    Map<String, Object?> json,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }
}

class RetripAlternativeResult {
  const RetripAlternativeResult({
    required this.id,
    required this.name,
    required this.description,
    required this.walkingTime,
    required this.diversityScore,
    required this.crowdLevel,
    this.imageAssetPath,
    this.contentId,
    this.mapX,
    this.mapY,
  });

  final String id;
  final String name;
  final String description;
  final String walkingTime;
  final int diversityScore;
  final String crowdLevel;
  final String? imageAssetPath;
  final String? contentId;
  final double? mapX;
  final double? mapY;

  factory RetripAlternativeResult.fromJson(Map<dynamic, dynamic> json) {
    final name = _string(json, const [
      'name',
      'placeName',
      'place_name',
    ], 'Cafe');
    return RetripAlternativeResult(
      id: _string(json, const ['id'], _slug(name)),
      name: name,
      description: _string(json, const [
        'description',
        'reason',
        'value',
      ], 'Nearby alternative recommended by ennoia.'),
      walkingTime: _string(json, const [
        'walkingTime',
        'walking_time',
        'distance',
      ], '5 min walk'),
      diversityScore: _int(json, const [
        'diversityScore',
        'diversity_score',
        'score',
      ], 90),
      crowdLevel: _string(json, const [
        'crowdLevel',
        'crowd_level',
        'crowd',
      ], 'Low'),
      imageAssetPath: _nullableString(json, const [
        'imageAssetPath',
        'image_asset_path',
      ]),
      contentId: _nullableString(json, const [
        'contentId',
        'content_id',
        'kto_content_id',
        'contentid',
      ]),
      mapX: _double(json, const ['mapX', 'mapx', 'x']),
      mapY: _double(json, const ['mapY', 'mapy', 'y']),
    );
  }

  AlternativePlace toAlternativePlace() {
    return AlternativePlace(
      id: id,
      name: name,
      description: description,
      walkingTime: walkingTime,
      diversityScore: diversityScore,
      crowdLevel: crowdLevel,
      imageAssetPath: imageAssetPath,
      contentId: contentId,
      mapX: mapX,
      mapY: mapY,
    );
  }

  static String _string(
    Map<dynamic, dynamic> json,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  static String? _nullableString(
    Map<dynamic, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static int _int(Map<dynamic, dynamic> json, List<String> keys, int fallback) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double? _double(Map<dynamic, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'retrip-alternative' : slug;
  }
}
