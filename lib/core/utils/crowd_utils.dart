import 'package:norigo/data/models/recommendation.dart';

class CrowdScoreCalculator {
  const CrowdScoreCalculator._();

  static int calculateScore({
    required int densityPercent,
    required int waitMinutes,
    bool appQueueFull = false,
    int localEventImpact = 0,
  }) {
    final densityScore = densityPercent.clamp(0, 100);
    final waitScore = (waitMinutes * 1.2).round().clamp(0, 70);
    final appQueuePenalty = appQueueFull ? 18 : 0;
    final eventPenalty = localEventImpact.clamp(0, 20);
    return (densityScore * 0.55 +
            waitScore * 0.3 +
            appQueuePenalty +
            eventPenalty)
        .round()
        .clamp(0, 100);
  }

  static String labelForScore(int score) {
    if (score >= 82) return 'Very High';
    if (score >= 62) return 'High';
    if (score >= 38) return 'Moderate';
    return 'Low';
  }

  static String travelerMessage(String crowdLevel) {
    switch (crowdLevel) {
      case 'Very High':
        return 'Expect app-based queues and limited seats. Consider switching now.';
      case 'High':
        return 'It may look calm nearby, but waitlists can fill before arrival.';
      case 'Moderate':
        return 'Go soon or keep a backup nearby.';
      default:
        return 'Good timing for a relaxed visit.';
    }
  }
}

class RecommendationRanker {
  const RecommendationRanker._();

  static List<Recommendation> rankNearby(List<Recommendation> recommendations) {
    final ranked = [...recommendations];
    ranked.sort((a, b) {
      final scoreA = _score(a);
      final scoreB = _score(b);
      return scoreB.compareTo(scoreA);
    });
    return ranked;
  }

  static double _score(Recommendation recommendation) {
    final walkPenalty = recommendation.walkingMinutes * 1.7;
    final crowdBonus = recommendation.crowdLevel == 'Low' ? 16 : 6;
    return recommendation.diversityScore +
        crowdBonus +
        recommendation.rating * 4 -
        walkPenalty;
  }
}
