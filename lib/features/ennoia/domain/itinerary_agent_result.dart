import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class ItineraryAgentResult {
  const ItineraryAgentResult({
    required this.id,
    required this.dateLabel,
    required this.title,
    required this.items,
    required this.estimatedTimeSaved,
    required this.sourceType,
    this.sourceNote,
    this.persisted = false,
    this.persistedPlanId,
  });

  final String id;
  final String dateLabel;
  final String title;
  final List<ItineraryAgentItemResult> items;
  final String estimatedTimeSaved;
  final String sourceType;
  final String? sourceNote;
  final bool persisted;
  final String? persistedPlanId;

  bool get isRealEnnoia =>
      sourceType == 'ennoia' ||
      sourceType == 'ennoia_kto_mcp' ||
      sourceType == 'kto_openapi_ennoia' ||
      sourceType == 'kto_openapi_fallback';

  factory ItineraryAgentResult.fromJson(Map<String, Object?> json) {
    final data = _nestedMap(json) ?? json;
    final sourceType = _sourceType(json);
    final fallback = ItineraryAgentResult.mock(sourceType: sourceType);
    final rawItems = _list(data, const [
      'items',
      'itinerary',
      'itineraryItems',
      'itinerary_items',
      'places',
    ]);
    final items = rawItems
        .whereType<Map>()
        .map((item) => ItineraryAgentItemResult.fromJson(item))
        .take(5)
        .toList(growable: false);

    if (items.isEmpty && sourceType != 'mock') {
      throw const FormatException(
        'Real ennoia itinerary did not include items.',
      );
    }

    return ItineraryAgentResult(
      id: _string(data, const ['id'], fallback.id),
      dateLabel: _string(data, const [
        'dateLabel',
        'date_label',
        'travelDate',
        'travel_date',
      ], fallback.dateLabel),
      title: _string(data, const ['title'], fallback.title),
      estimatedTimeSaved: _string(data, const [
        'estimatedTimeSaved',
        'estimated_time_saved',
        'timeSaved',
      ], fallback.estimatedTimeSaved),
      items: items.isEmpty ? fallback.items : items,
      sourceType: sourceType,
      sourceNote:
          _nullableString(data, const [
            'sourceNote',
            'source_note',
            'evidence',
            'evidenceNote',
            'evidence_note',
          ]) ??
          _nullableString(json, const [
            'sourceNote',
            'source_note',
            'evidence',
            'evidenceNote',
            'evidence_note',
          ]),
      persisted: _persisted(json),
      persistedPlanId: _persistedPlanId(json),
    );
  }

  factory ItineraryAgentResult.mock({
    String sourceType = 'mock',
    bool persisted = false,
    String? persistedPlanId,
  }) {
    return ItineraryAgentResult(
      id: 'mock-seoul-one-day',
      dateLabel: 'May 18, Sun',
      title: 'AI Itinerary Planner',
      estimatedTimeSaved: '1h 25m',
      sourceType: sourceType,
      sourceNote: 'Mock itinerary evidence for demo fallback.',
      persisted: persisted,
      persistedPlanId: persistedPlanId,
      items: const [
        ItineraryAgentItemResult(
          id: 'gyeongbokgung-palace',
          order: 1,
          time: '09:00',
          placeName: 'Gyeongbokgung Palace',
          crowdLevel: 'low',
          stayTime: 'Stay 1h 30m',
          aiTip: 'Best time to enter!',
        ),
        ItineraryAgentItemResult(
          id: 'bukchon-hanok-village',
          order: 2,
          time: '11:00',
          placeName: 'Bukchon Hanok Village',
          crowdLevel: 'moderate',
          stayTime: 'Stay 1h',
          aiTip: 'Explore quiet alleyways',
        ),
        ItineraryAgentItemResult(
          id: 'dessert-cafe',
          order: 3,
          time: '13:00',
          placeName: 'Dessert Cafe',
          crowdLevel: 'low',
          stayTime: 'Stay 1h',
          aiTip: 'Perfect time for a break',
        ),
        ItineraryAgentItemResult(
          id: 'seongsu-select-shop',
          order: 4,
          time: '15:00',
          placeName: 'Seongsu Select Shop',
          crowdLevel: 'moderate',
          stayTime: 'Stay 1h 30m',
          aiTip: 'Trendy finds in Seongsu',
        ),
        ItineraryAgentItemResult(
          id: 'n-seoul-tower',
          order: 5,
          time: '18:30',
          placeName: 'N Seoul Tower',
          crowdLevel: 'low',
          stayTime: 'Stay 1h',
          aiTip: 'Catch the best sunset view',
          extraBadge: 'Sunset view',
        ),
      ],
    );
  }

  ItineraryPlan toItineraryPlan() {
    return ItineraryPlan(
      id: id,
      dateLabel: dateLabel,
      title: title,
      estimatedTimeSaved: estimatedTimeSaved,
      sourceType: sourceType,
      sourceNote: sourceNote,
      items: items
          .map((item) => item.toItineraryItem())
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'dateLabel': dateLabel,
      'title': title,
      'estimatedTimeSaved': estimatedTimeSaved,
      'sourceType': sourceType,
      'sourceNote': sourceNote,
      'persisted': persisted,
      'persistedPlanId': persistedPlanId,
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  static Map<String, Object?>? _nestedMap(Map<String, Object?> json) {
    for (final key in const ['itinerary', 'plan', 'result', 'data']) {
      final value = json[key];
      if (value is Map<String, Object?>) return value;
      if (value is Map) return Map<String, Object?>.from(value);
    }
    return null;
  }

  static String _sourceType(Map<String, Object?> json) {
    final source = json['source_type'] ?? json['sourceType'] ?? json['source'];
    if (source is String && source.trim().isNotEmpty) {
      final normalized = source.trim().toLowerCase().replaceAll('-', '_');
      if (normalized == 'mock') return 'mock';
      if (normalized == 'ennoia_kto_mcp') return 'ennoia_kto_mcp';
      if (normalized == 'kto_openapi_ennoia') return 'kto_openapi_ennoia';
      if (normalized == 'kto_openapi_fallback') return 'kto_openapi_fallback';
      if (normalized == 'ennoia') return 'ennoia';
    }

    return 'ennoia';
  }

  static bool _persisted(Map<String, Object?> json) {
    final value = json['persisted'];
    if (value is bool) return value;

    final persistence = json['persistence'];
    if (persistence is Map && persistence['saved'] is bool) {
      return persistence['saved'] as bool;
    }

    return false;
  }

  static String? _persistedPlanId(Map<String, Object?> json) {
    final value = json['persistedPlanId'] ?? json['persisted_plan_id'];
    if (value is String && value.trim().isNotEmpty) return value.trim();

    final persistence = json['persistence'];
    if (persistence is Map) {
      final id = persistence['id'] ?? persistence['plan_id'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }

    return null;
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

  static String? _nullableString(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

class ItineraryAgentItemResult {
  const ItineraryAgentItemResult({
    required this.id,
    required this.order,
    required this.time,
    required this.placeName,
    required this.crowdLevel,
    required this.stayTime,
    required this.aiTip,
    this.extraBadge,
    this.imageAssetPath,
    this.contentId,
    this.mapX,
    this.mapY,
  });

  final String id;
  final int order;
  final String time;
  final String placeName;
  final String crowdLevel;
  final String stayTime;
  final String aiTip;
  final String? extraBadge;
  final String? imageAssetPath;
  final String? contentId;
  final double? mapX;
  final double? mapY;

  factory ItineraryAgentItemResult.fromJson(Map<dynamic, dynamic> json) {
    final placeName = _string(json, const [
      'placeName',
      'place_name',
      'name',
      'title',
    ], 'Recommended stop');
    return ItineraryAgentItemResult(
      id: _string(json, const ['id'], _slug(placeName)),
      order: _int(json, const ['order', 'sequence'], 1),
      time: _string(json, const ['time', 'startTime', 'start_time'], '09:00'),
      placeName: placeName,
      crowdLevel: _string(json, const [
        'crowdLevel',
        'crowd_level',
        'crowd',
      ], 'low'),
      stayTime: _string(json, const [
        'stayTime',
        'stay_time',
        'duration',
        'stay',
      ], 'Stay 1h'),
      aiTip: _string(json, const [
        'aiTip',
        'ai_tip',
        'cultureTip',
        'culture_tip',
        'tip',
        'reason',
        'description',
      ], 'Recommended by ennoia.'),
      extraBadge: _nullableString(json, const ['extraBadge', 'extra_badge']),
      imageAssetPath: _nullableString(json, const [
        'imageAssetPath',
        'image_asset_path',
      ]),
      contentId: _nullableValueAsString(json, const [
        'contentId',
        'content_id',
        'ktoContentId',
        'kto_content_id',
        'contentid',
      ]),
      mapX: _double(json, const ['mapX', 'mapx', 'x']),
      mapY: _double(json, const ['mapY', 'mapy', 'y']),
    );
  }

  ItineraryItem toItineraryItem() {
    return ItineraryItem(
      id: id,
      order: order,
      time: time,
      placeName: placeName,
      crowdLevel: _crowdLevel(crowdLevel),
      stayTime: stayTime,
      aiTip: aiTip,
      extraBadge: extraBadge,
      imageAssetPath: imageAssetPath,
      contentId: contentId,
      mapX: mapX,
      mapY: mapY,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'order': order,
      'time': time,
      'placeName': placeName,
      'crowdLevel': crowdLevel,
      'stayTime': stayTime,
      'aiTip': aiTip,
      'extraBadge': extraBadge,
      'imageAssetPath': imageAssetPath,
      'contentId': contentId,
      'mapX': mapX,
      'mapY': mapY,
    };
  }

  static ItineraryCrowdLevel _crowdLevel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('moderate') || normalized.contains('high')) {
      return ItineraryCrowdLevel.moderate;
    }
    return ItineraryCrowdLevel.low;
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

  static String? _nullableValueAsString(
    Map<dynamic, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
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
    return slug.isEmpty ? 'recommended-stop' : slug;
  }
}
