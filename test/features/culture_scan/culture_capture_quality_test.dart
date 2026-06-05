import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/culture_scan/application/culture_capture_quality.dart';

void main() {
  const analyzer = DefaultCultureCaptureQualityAnalyzer();

  test('solid black frame is rejected before classification', () {
    final quality = analyzer.analyzeRgbaForTesting(
      _solidRgba(64, 64, 0, 0, 0),
      64,
      64,
    );

    expect(quality.isUsable, isFalse);
    expect(quality.issue, CultureCaptureQualityIssue.tooDarkOrBlank);
    expect(quality.captureBrightRatioForTest, 0);
  });

  test('dark noisy covered frame is rejected before classification', () {
    final quality = analyzer.analyzeRgbaForTesting(
      _darkNoisyRgba(64, 64),
      64,
      64,
    );

    expect(quality.isUsable, isFalse);
    expect(quality.issue, CultureCaptureQualityIssue.tooDarkOrBlank);
    expect(quality.lumaP90, lessThan(72));
    expect(quality.brightRatio, lessThan(0.05));
  });

  test('lit tabletop frame with a dark central object remains usable', () {
    final quality = analyzer.analyzeRgbaForTesting(
      _tabletopWithDarkObjectRgba(64, 64),
      64,
      64,
    );

    expect(quality.isUsable, isTrue);
    expect(quality.brightRatio, greaterThan(0.30));
    expect(quality.lumaP90, greaterThan(110));
  });
}

Uint8List _solidRgba(int width, int height, int r, int g, int b) {
  final bytes = Uint8List(width * height * 4);
  for (var index = 0; index < bytes.length; index += 4) {
    bytes[index] = r;
    bytes[index + 1] = g;
    bytes[index + 2] = b;
    bytes[index + 3] = 255;
  }
  return bytes;
}

Uint8List _darkNoisyRgba(int width, int height) {
  final bytes = Uint8List(width * height * 4);
  for (var pixel = 0; pixel < width * height; pixel++) {
    final shade = pixel % 5 == 0 ? 62 : 28;
    final index = pixel * 4;
    bytes[index] = shade;
    bytes[index + 1] = shade;
    bytes[index + 2] = shade;
    bytes[index + 3] = 255;
  }
  return bytes;
}

Uint8List _tabletopWithDarkObjectRgba(int width, int height) {
  final bytes = _solidRgba(width, height, 180, 145, 108);
  final left = width ~/ 4;
  final right = width - left;
  final top = height ~/ 4;
  final bottom = height - top;

  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final index = ((y * width) + x) * 4;
      bytes[index] = 25;
      bytes[index + 1] = 25;
      bytes[index + 2] = 25;
      bytes[index + 3] = 255;
    }
  }
  return bytes;
}

extension on CultureCaptureQuality {
  double get captureBrightRatioForTest => brightRatio ?? -1;
}
