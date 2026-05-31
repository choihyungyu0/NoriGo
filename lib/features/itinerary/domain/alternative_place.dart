class AlternativePlace {
  const AlternativePlace({
    required this.id,
    required this.name,
    required this.description,
    required this.walkingTime,
    required this.diversityScore,
    required this.crowdLevel,
    this.imageAssetPath,
    this.imageUrl,
    this.contentId,
    this.contentTypeId,
    this.address,
    this.recommendationCopy,
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
  final String? imageUrl;
  final String? contentId;
  final String? contentTypeId;
  final String? address;
  final String? recommendationCopy;
  final double? mapX;
  final double? mapY;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'place_name': name,
      'description': description,
      'walking_time': walkingTime,
      'diversity_score': diversityScore,
      'crowd_level': crowdLevel,
      'image_url': imageUrl,
      'kto_content_id': contentId,
      'content_type_id': contentTypeId,
      'address': address,
      'recommendation_copy': recommendationCopy,
      'mapx': mapX,
      'mapy': mapY,
    };
  }
}
