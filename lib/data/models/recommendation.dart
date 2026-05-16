class Recommendation {
  const Recommendation({
    required this.id,
    required this.placeName,
    required this.walkingMinutes,
    required this.diversityScore,
    required this.crowdLevel,
    required this.rating,
    required this.tags,
    required this.message,
  });

  final String id;
  final String placeName;
  final int walkingMinutes;
  final int diversityScore;
  final String crowdLevel;
  final double rating;
  final List<String> tags;
  final String message;
}
