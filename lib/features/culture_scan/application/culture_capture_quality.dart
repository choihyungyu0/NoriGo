import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';

enum CultureCaptureQualityIssue { none, tooDarkOrBlank }

class CultureCaptureQuality {
  const CultureCaptureQuality._({
    required this.isUsable,
    required this.issue,
    this.meanLuma,
    this.lumaStdDev,
    this.lumaRange,
    this.lumaP50,
    this.lumaP90,
    this.nearBlackRatio,
    this.dimRatio,
    this.brightRatio,
  });

  const CultureCaptureQuality.usable({
    double? meanLuma,
    double? lumaStdDev,
    double? lumaRange,
    double? lumaP50,
    double? lumaP90,
    double? nearBlackRatio,
    double? dimRatio,
    double? brightRatio,
  }) : this._(
         isUsable: true,
         issue: CultureCaptureQualityIssue.none,
         meanLuma: meanLuma,
         lumaStdDev: lumaStdDev,
         lumaRange: lumaRange,
         lumaP50: lumaP50,
         lumaP90: lumaP90,
         nearBlackRatio: nearBlackRatio,
         dimRatio: dimRatio,
         brightRatio: brightRatio,
       );

  const CultureCaptureQuality.tooDarkOrBlank({
    double? meanLuma,
    double? lumaStdDev,
    double? lumaRange,
    double? lumaP50,
    double? lumaP90,
    double? nearBlackRatio,
    double? dimRatio,
    double? brightRatio,
  }) : this._(
         isUsable: false,
         issue: CultureCaptureQualityIssue.tooDarkOrBlank,
         meanLuma: meanLuma,
         lumaStdDev: lumaStdDev,
         lumaRange: lumaRange,
         lumaP50: lumaP50,
         lumaP90: lumaP90,
         nearBlackRatio: nearBlackRatio,
         dimRatio: dimRatio,
         brightRatio: brightRatio,
       );

  final bool isUsable;
  final CultureCaptureQualityIssue issue;
  final double? meanLuma;
  final double? lumaStdDev;
  final double? lumaRange;
  final double? lumaP50;
  final double? lumaP90;
  final double? nearBlackRatio;
  final double? dimRatio;
  final double? brightRatio;
}

abstract class CultureCaptureQualityAnalyzer {
  const CultureCaptureQualityAnalyzer();

  Future<CultureCaptureQuality> analyze(CultureImageCapture capture);
}

class DefaultCultureCaptureQualityAnalyzer
    extends CultureCaptureQualityAnalyzer {
  const DefaultCultureCaptureQualityAnalyzer();

  static const _decodeTimeout = Duration(milliseconds: 900);
  static const _targetWidth = 96;

  @override
  Future<CultureCaptureQuality> analyze(CultureImageCapture capture) async {
    if (capture.isEmpty) return const CultureCaptureQuality.tooDarkOrBlank();

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui
          .instantiateImageCodec(capture.bytes, targetWidth: _targetWidth)
          .timeout(_decodeTimeout);
      final frame = await codec.getNextFrame().timeout(_decodeTimeout);
      image = frame.image;
      final byteData = await image
          .toByteData(format: ui.ImageByteFormat.rawRgba)
          .timeout(_decodeTimeout);
      if (byteData == null) return const CultureCaptureQuality.usable();

      final rgba = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      return _analyzeRgba(rgba, image.width, image.height);
    } catch (_) {
      return const CultureCaptureQuality.usable();
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  @visibleForTesting
  CultureCaptureQuality analyzeRgbaForTesting(
    Uint8List rgba,
    int width,
    int height,
  ) {
    return _analyzeRgba(rgba, width, height);
  }

  CultureCaptureQuality _analyzeRgba(Uint8List rgba, int width, int height) {
    final totalPixels = width * height;
    if (totalPixels <= 0) return const CultureCaptureQuality.usable();

    final stride = math.max(1, totalPixels ~/ 4096);
    var sampleCount = 0;
    var nearBlackPixelCount = 0;
    var dimPixelCount = 0;
    var brightPixelCount = 0;
    var sum = 0.0;
    var sumSquares = 0.0;
    var minLuma = 255.0;
    var maxLuma = 0.0;
    final sampledLumas = <double>[];

    for (var pixel = 0; pixel < totalPixels; pixel += stride) {
      final index = pixel * 4;
      if (index + 2 >= rgba.length) break;

      final r = rgba[index];
      final g = rgba[index + 1];
      final b = rgba[index + 2];
      final luma = (r * 0.299) + (g * 0.587) + (b * 0.114);

      sampleCount++;
      sum += luma;
      sumSquares += luma * luma;
      minLuma = math.min(minLuma, luma);
      maxLuma = math.max(maxLuma, luma);
      sampledLumas.add(luma);
      if (luma < 45) nearBlackPixelCount++;
      if (luma < 70) dimPixelCount++;
      if (luma > 110) brightPixelCount++;
    }

    if (sampleCount == 0) return const CultureCaptureQuality.usable();

    final mean = sum / sampleCount;
    final variance = math.max(0, (sumSquares / sampleCount) - (mean * mean));
    final stdDev = math.sqrt(variance);
    final range = maxLuma - minLuma;
    final nearBlackRatio = nearBlackPixelCount / sampleCount;
    final dimRatio = dimPixelCount / sampleCount;
    final brightRatio = brightPixelCount / sampleCount;
    sampledLumas.sort();
    final p50 = _percentile(sampledLumas, 0.50);
    final p90 = _percentile(sampledLumas, 0.90);

    final isFlatBlank = stdDev < 7 && range < 24;
    final isVeryDark = mean < 22 || p90 < 34;
    final isMostlyCovered =
        nearBlackRatio > 0.90 && brightRatio < 0.02 && p90 < 64;
    final isDarkLowInfo =
        mean < 44 && p90 < 72 && brightRatio < 0.05 && stdDev < 24;
    final isDimLowEvidence =
        mean < 54 && p90 < 82 && dimRatio > 0.88 && brightRatio < 0.04;

    final quality = (
      meanLuma: mean,
      lumaStdDev: stdDev,
      lumaRange: range,
      lumaP50: p50,
      lumaP90: p90,
      nearBlackRatio: nearBlackRatio,
      dimRatio: dimRatio,
      brightRatio: brightRatio,
    );
    if (isFlatBlank ||
        isVeryDark ||
        isMostlyCovered ||
        isDarkLowInfo ||
        isDimLowEvidence) {
      return CultureCaptureQuality.tooDarkOrBlank(
        meanLuma: quality.meanLuma,
        lumaStdDev: quality.lumaStdDev,
        lumaRange: quality.lumaRange,
        lumaP50: quality.lumaP50,
        lumaP90: quality.lumaP90,
        nearBlackRatio: quality.nearBlackRatio,
        dimRatio: quality.dimRatio,
        brightRatio: quality.brightRatio,
      );
    }

    return CultureCaptureQuality.usable(
      meanLuma: quality.meanLuma,
      lumaStdDev: quality.lumaStdDev,
      lumaRange: quality.lumaRange,
      lumaP50: quality.lumaP50,
      lumaP90: quality.lumaP90,
      nearBlackRatio: quality.nearBlackRatio,
      dimRatio: quality.dimRatio,
      brightRatio: quality.brightRatio,
    );
  }

  double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;
    final index = ((sortedValues.length - 1) * percentile).round();
    final clampedIndex = math.min(math.max(index, 0), sortedValues.length - 1);
    return sortedValues[clampedIndex];
  }
}
