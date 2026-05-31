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
    this.summary,
    this.sourceBadge,
    this.sourceNote,
    this.persistedPlanId,
  });

  final String id;
  final String dateLabel;
  final String title;
  final List<ItineraryAgentItemResult> items;
  final String estimatedTimeSaved;
  final String sourceType;
  final String? summary;
  final String? sourceBadge;
  final String? sourceNote;
  final String? persistedPlanId;

  bool get isRealEnnoia => sourceType == 'kto_openapi_ennoia';

  factory ItineraryAgentResult.fromJson(Map<String, Object?> json) {
    final data = _nestedMap(json) ?? json;
    final fallback = ItineraryAgentResult.mock(
      sourceType: _sourceType(json) ?? _sourceType(data) ?? 'ennoia',
    );
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
      sourceType: fallback.sourceType,
      summary:
          _nullableString(data, const ['summary', 'route_summary']) ??
          _nullableString(json, const ['summary', 'route_summary']),
      sourceBadge:
          _nullableString(data, const ['sourceBadge', 'source_badge']) ??
          _nullableString(json, const ['sourceBadge', 'source_badge']),
      sourceNote:
          _nullableString(data, const ['sourceNote', 'source_note']) ??
          _nullableString(json, const ['sourceNote', 'source_note']),
      persistedPlanId:
          _nullableString(data, const [
            'persistedPlanId',
            'persisted_plan_id',
          ]) ??
          _nullableString(json, const ['persistedPlanId', 'persisted_plan_id']),
    );
  }

  factory ItineraryAgentResult.mock({String sourceType = 'mock'}) {
    return ItineraryAgentResult(
      id: 'mock-seoul-one-day',
      dateLabel: 'May 18, Sun',
      title: 'AI Itinerary Planner',
      estimatedTimeSaved: '1h 25m',
      sourceType: sourceType,
      summary: null,
      sourceBadge: null,
      sourceNote: null,
      persistedPlanId: null,
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
      sourceBadge: sourceBadge,
      sourceNote: sourceNote,
      summary: summary,
      persistedPlanId: persistedPlanId,
      items: items
          .map((item) => item.toItineraryItem())
          .toList(growable: false),
    );
  }

  static Map<String, Object?>? _nestedMap(Map<String, Object?> json) {
    for (final key in const ['itinerary', 'plan', 'result', 'data']) {
      final value = json[key];
      if (value is Map<String, Object?>) return value;
      if (value is Map) return Map<String, Object?>.from(value);
    }
    return null;
  }

  static String? _sourceType(Map<String, Object?> json) {
    final source = json['source'] ?? json['sourceType'] ?? json['source_type'];
    if (source is String && source.trim().isNotEmpty) {
      return source.trim();
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
    this.imageUrl,
    this.contentId,
    this.contentTypeId,
    this.address,
    this.cultureTip,
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
  final String? imageUrl;
  final String? contentId;
  final String? contentTypeId;
  final String? address;
  final String? cultureTip;
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
        'tip',
        'reason',
        'description',
      ], 'Recommended by ennoia.'),
      extraBadge: _nullableString(json, const ['extraBadge', 'extra_badge']),
      imageAssetPath: _nullableString(json, const [
        'imageAssetPath',
        'image_asset_path',
      ]),
      imageUrl: _nullableString(json, const [
        'imageUrl',
        'image_url',
        'firstimage',
        'image',
      ]),
      contentId: _nullableString(json, const [
        'kto_content_id',
        'contentId',
        'content_id',
        'contentid',
      ]),
      contentTypeId: _nullableString(json, const [
        'contentTypeId',
        'content_type_id',
        'contenttypeid',
      ]),
      address: _nullableString(json, const ['addr1', 'address']),
      cultureTip: _nullableString(json, const [
        'cultureTip',
        'culture_tip',
        'local_tip',
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
      imageUrl: imageUrl,
      contentId: contentId,
      contentTypeId: contentTypeId,
      address: address,
      cultureTip: cultureTip,
      mapX: mapX,
      mapY: mapY,
    );
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
