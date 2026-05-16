class Place {
  const Place({
    required this.id,
    required this.name,
    required this.area,
    required this.category,
    required this.walkingMinutes,
    required this.crowdLevel,
    required this.localVisitRatio,
    required this.diversityScore,
    required this.rating,
    required this.tags,
  });

  final String id;
  final String name;
  final String area;
  final String category;
  final int walkingMinutes;
  final String crowdLevel;
  final int localVisitRatio;
  final int diversityScore;
  final double rating;
  final List<String> tags;
}
