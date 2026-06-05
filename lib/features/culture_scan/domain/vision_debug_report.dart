import 'dart:convert';

class VisionDebugLabel {
  const VisionDebugLabel({
    required this.text,
    this.index,
    required this.confidence,
  });

  final String text;
  final int? index;
  final double confidence;

  Map<String, Object?> toJson() {
    return {
      'text': text,
      if (index != null) 'index': index,
      'confidence': confidence,
    };
  }

  factory VisionDebugLabel.fromJson(Map<String, Object?> json) {
    return VisionDebugLabel(
      text: (json['text'] as String?) ?? '',
      index: json['index'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VisionDebugReport {
  const VisionDebugReport({
    required this.createdAt,
    required this.platform,
    required this.cameraMode,
    required this.customModelExpectedPath,
    required this.customModelLoaded,
    required this.labelsFileLoaded,
    this.modelVersionOrHash,
    required this.captureSucceeded,
    this.capturedImagePath,
    this.capturedImageWidth,
    this.capturedImageHeight,
    this.capturedImageFileSizeBytes,
    this.capturedImageRotation,
    this.capturedImageSource,
    this.captureMeanLuma,
    this.captureLumaStdDev,
    this.captureLumaRange,
    this.captureLumaP50,
    this.captureLumaP90,
    this.captureNearBlackRatio,
    this.captureDimRatio,
    this.captureBrightRatio,
    this.customLabels = const [],
    this.baseLabels = const [],
    this.serverVisionResult,
    this.mappedDetectedObject,
    this.mappedPlaceType,
    this.detectedObjectSource,
    this.visionConfidence,
    required this.thresholdAuto,
    required this.thresholdSuggest,
    required this.finalDecision,
    this.errorMessage,
  });

  final DateTime createdAt;
  final String platform;
  final String cameraMode;
  final String customModelExpectedPath;
  final bool customModelLoaded;
  final bool labelsFileLoaded;
  final String? modelVersionOrHash;
  final bool captureSucceeded;
  final String? capturedImagePath;
  final int? capturedImageWidth;
  final int? capturedImageHeight;
  final int? capturedImageFileSizeBytes;
  final int? capturedImageRotation;
  final String? capturedImageSource;
  final double? captureMeanLuma;
  final double? captureLumaStdDev;
  final double? captureLumaRange;
  final double? captureLumaP50;
  final double? captureLumaP90;
  final double? captureNearBlackRatio;
  final double? captureDimRatio;
  final double? captureBrightRatio;
  final List<VisionDebugLabel> customLabels;
  final List<VisionDebugLabel> baseLabels;
  final Map<String, Object?>? serverVisionResult;
  final String? mappedDetectedObject;
  final String? mappedPlaceType;
  final String? detectedObjectSource;
  final double? visionConfidence;
  final double thresholdAuto;
  final double thresholdSuggest;
  final String finalDecision;
  final String? errorMessage;

  Map<String, Object?> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'platform': platform,
      'cameraMode': cameraMode,
      'customModelExpectedPath': customModelExpectedPath,
      'customModelLoaded': customModelLoaded,
      'labelsFileLoaded': labelsFileLoaded,
      if (modelVersionOrHash != null) 'modelVersionOrHash': modelVersionOrHash,
      'captureSucceeded': captureSucceeded,
      if (capturedImagePath != null) 'capturedImagePath': capturedImagePath,
      if (capturedImageWidth != null) 'capturedImageWidth': capturedImageWidth,
      if (capturedImageHeight != null)
        'capturedImageHeight': capturedImageHeight,
      if (capturedImageFileSizeBytes != null)
        'capturedImageFileSizeBytes': capturedImageFileSizeBytes,
      if (capturedImageRotation != null)
        'capturedImageRotation': capturedImageRotation,
      if (capturedImageSource != null)
        'capturedImageSource': capturedImageSource,
      if (captureMeanLuma != null) 'captureMeanLuma': captureMeanLuma,
      if (captureLumaStdDev != null) 'captureLumaStdDev': captureLumaStdDev,
      if (captureLumaRange != null) 'captureLumaRange': captureLumaRange,
      if (captureLumaP50 != null) 'captureLumaP50': captureLumaP50,
      if (captureLumaP90 != null) 'captureLumaP90': captureLumaP90,
      if (captureNearBlackRatio != null)
        'captureNearBlackRatio': captureNearBlackRatio,
      if (captureDimRatio != null) 'captureDimRatio': captureDimRatio,
      if (captureBrightRatio != null) 'captureBrightRatio': captureBrightRatio,
      'customLabels': customLabels.map((item) => item.toJson()).toList(),
      'baseLabels': baseLabels.map((item) => item.toJson()).toList(),
      if (serverVisionResult != null) 'serverVisionResult': serverVisionResult,
      if (mappedDetectedObject != null)
        'mappedDetectedObject': mappedDetectedObject,
      if (mappedPlaceType != null) 'mappedPlaceType': mappedPlaceType,
      if (detectedObjectSource != null)
        'detectedObjectSource': detectedObjectSource,
      if (visionConfidence != null) 'visionConfidence': visionConfidence,
      'thresholdAuto': thresholdAuto,
      'thresholdSuggest': thresholdSuggest,
      'finalDecision': finalDecision,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory VisionDebugReport.fromJson(Map<String, Object?> json) {
    return VisionDebugReport(
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      platform: (json['platform'] as String?) ?? 'unknown',
      cameraMode: (json['cameraMode'] as String?) ?? 'unknown',
      customModelExpectedPath:
          (json['customModelExpectedPath'] as String?) ?? '',
      customModelLoaded: json['customModelLoaded'] == true,
      labelsFileLoaded: json['labelsFileLoaded'] == true,
      modelVersionOrHash: json['modelVersionOrHash'] as String?,
      captureSucceeded: json['captureSucceeded'] == true,
      capturedImagePath: json['capturedImagePath'] as String?,
      capturedImageWidth: (json['capturedImageWidth'] as num?)?.toInt(),
      capturedImageHeight: (json['capturedImageHeight'] as num?)?.toInt(),
      capturedImageFileSizeBytes: (json['capturedImageFileSizeBytes'] as num?)
          ?.toInt(),
      capturedImageRotation: (json['capturedImageRotation'] as num?)?.toInt(),
      capturedImageSource: json['capturedImageSource'] as String?,
      captureMeanLuma: (json['captureMeanLuma'] as num?)?.toDouble(),
      captureLumaStdDev: (json['captureLumaStdDev'] as num?)?.toDouble(),
      captureLumaRange: (json['captureLumaRange'] as num?)?.toDouble(),
      captureLumaP50: (json['captureLumaP50'] as num?)?.toDouble(),
      captureLumaP90: (json['captureLumaP90'] as num?)?.toDouble(),
      captureNearBlackRatio: (json['captureNearBlackRatio'] as num?)
          ?.toDouble(),
      captureDimRatio: (json['captureDimRatio'] as num?)?.toDouble(),
      captureBrightRatio: (json['captureBrightRatio'] as num?)?.toDouble(),
      customLabels: _labelsFromJson(json['customLabels']),
      baseLabels: _labelsFromJson(json['baseLabels']),
      serverVisionResult: json['serverVisionResult'] is Map
          ? Map<String, Object?>.from(json['serverVisionResult'] as Map)
          : null,
      mappedDetectedObject: json['mappedDetectedObject'] as String?,
      mappedPlaceType: json['mappedPlaceType'] as String?,
      detectedObjectSource: json['detectedObjectSource'] as String?,
      visionConfidence: (json['visionConfidence'] as num?)?.toDouble(),
      thresholdAuto: (json['thresholdAuto'] as num?)?.toDouble() ?? 0,
      thresholdSuggest: (json['thresholdSuggest'] as num?)?.toDouble() ?? 0,
      finalDecision: (json['finalDecision'] as String?) ?? 'error',
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

List<VisionDebugLabel> _labelsFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => VisionDebugLabel.fromJson(Map<String, Object?>.from(item)))
      .toList(growable: false);
}
