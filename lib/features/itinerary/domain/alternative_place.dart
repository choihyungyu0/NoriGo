class AlternativePlace {
  const AlternativePlace({
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
}
