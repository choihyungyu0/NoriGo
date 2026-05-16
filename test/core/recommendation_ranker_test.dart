import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/utils/crowd_utils.dart';
import 'package:norigo/data/models/recommendation.dart';

void main() {
  test('recommendation ranker favors nearby low-crowd diverse places', () {
    final ranked = RecommendationRanker.rankNearby(const [
      Recommendation(
        id: 'far',
        placeName: 'Far Famous Cafe',
        walkingMinutes: 18,
        diversityScore: 80,
        crowdLevel: 'High',
        rating: 4.8,
        tags: ['Famous'],
        message: 'Popular but busy.',
      ),
      Recommendation(
        id: 'near',
        placeName: 'Near Quiet Cafe',
        walkingMinutes: 4,
        diversityScore: 88,
        crowdLevel: 'Low',
        rating: 4.5,
        tags: ['Quiet'],
        message: 'Calmer and close.',
      ),
    ]);

    expect(ranked.first.id, 'near');
  });
}
