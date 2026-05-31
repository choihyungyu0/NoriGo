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
    this.address,
    this.cultureTip,
    this.mapX,
    this.mapY,
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
  final String? address;
  final String? cultureTip;
  final double? mapX;
  final double? mapY;

  String get crowdLabel {
    return switch (crowdLevel) {
      ItineraryCrowdLevel.low => 'Low crowd',
      ItineraryCrowdLevel.moderate => 'Moderate crowd',
    };
  }
}
