import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/utils/crowd_utils.dart';

void main() {
  test('crowd score includes app queue risk', () {
    final noAppQueue = CrowdScoreCalculator.calculateScore(
      densityPercent: 70,
      waitMinutes: 20,
    );
    final appQueueFull = CrowdScoreCalculator.calculateScore(
      densityPercent: 70,
      waitMinutes: 20,
      appQueueFull: true,
    );

    expect(appQueueFull, greaterThan(noAppQueue));
    expect(CrowdScoreCalculator.labelForScore(86), 'Very High');
  });
}
