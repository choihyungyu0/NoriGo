enum ItineraryCrowdLevel { low, moderate }

class ItineraryItem {
  const ItineraryItem({
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
    this.status = 'planned',
  });

  final String id;
  final int order;
  final String time;
  final String placeName;
  final ItineraryCrowdLevel crowdLevel;
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
  final String status;

  String get crowdLabel {
    return switch (crowdLevel) {
      ItineraryCrowdLevel.low => 'Low crowd',
      ItineraryCrowdLevel.moderate => 'Moderate crowd',
    };
  }

  ItineraryItem copyWith({
    String? id,
    int? order,
    String? time,
    String? placeName,
    ItineraryCrowdLevel? crowdLevel,
    String? stayTime,
    String? aiTip,
    String? extraBadge,
    String? imageAssetPath,
    String? imageUrl,
    String? contentId,
    String? contentTypeId,
    String? address,
    String? cultureTip,
    double? mapX,
    double? mapY,
    String? status,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      order: order ?? this.order,
      time: time ?? this.time,
      placeName: placeName ?? this.placeName,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      stayTime: stayTime ?? this.stayTime,
      aiTip: aiTip ?? this.aiTip,
      extraBadge: extraBadge ?? this.extraBadge,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      imageUrl: imageUrl ?? this.imageUrl,
      contentId: contentId ?? this.contentId,
      contentTypeId: contentTypeId ?? this.contentTypeId,
      address: address ?? this.address,
      cultureTip: cultureTip ?? this.cultureTip,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      status: status ?? this.status,
    );
  }
}
