import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

class SeoulRealtimeRiskRequest {
  const SeoulRealtimeRiskRequest({
    this.currentLat,
    this.currentLng,
    this.currentPlaceName,
    this.scheduledPlaceName,
    this.scheduledTime,
    this.triggerContext = 'itinerary_check',
  });

  final double? currentLat;
  final double? currentLng;
  final String? currentPlaceName;
  final String? scheduledPlaceName;
  final String? scheduledTime;
  final String triggerContext;

  Map<String, Object?> toJson() {
    return {
      'current_lat': currentLat,
      'current_lng': currentLng,
      'current_place_name': currentPlaceName,
      'scheduled_place_name': scheduledPlaceName,
      'scheduled_time': scheduledTime,
      'trigger_context': triggerContext,
    };
  }

  String get cacheKey {
    final place = [currentPlaceName, scheduledPlaceName]
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (place.isNotEmpty) return _normalizeCacheKey(place);
    if (currentLat != null && currentLng != null) {
      return '${currentLat!.toStringAsFixed(4)},${currentLng!.toStringAsFixed(4)}';
    }
    return 'unknown';
  }
}

class SeoulRealtimeRisk {
  const SeoulRealtimeRisk({
    required this.areaNm,
    required this.matchedPlaceName,
    required this.scheduledPlaceName,
    required this.congestionLevel,
    required this.congestionMessage,
    required this.populationMin,
    required this.populationMax,
    required this.populationTime,
    required this.crowdScore,
    required this.incidentBonus,
    required this.riskScore,
    required this.riskLevel,
    required this.shouldAlert,
    required this.triggerType,
    required this.alertMessage,
    required this.riskReason,
    required this.sourceType,
    required this.sourceBadge,
  });

  final String areaNm;
  final String matchedPlaceName;
  final String scheduledPlaceName;
  final String congestionLevel;
  final String congestionMessage;
  final int? populationMin;
  final int? populationMax;
  final String populationTime;
  final int crowdScore;
  final int incidentBonus;
  final int riskScore;
  final String riskLevel;
  final bool shouldAlert;
  final String triggerType;
  final String alertMessage;
  final String riskReason;
  final String sourceType;
  final String sourceBadge;

  bool get isUnavailable => sourceType == 'seoul_realtime_unavailable';
  bool get isUnmatched => sourceType == 'seoul_area_unmatched';
  bool get shouldShowCrowdRisingBadge => riskScore >= 65 && riskScore < 85;

  String get estimatedWait {
    return switch (riskLevel) {
      'Very High' => '40-60 min',
      'High' => '20-40 min',
      'Moderate' => '10-20 min',
      _ => 'none',
    };
  }

  factory SeoulRealtimeRisk.fromJson(Map<String, Object?> json) {
    return SeoulRealtimeRisk(
      areaNm: _string(json, 'area_nm'),
      matchedPlaceName: _string(json, 'matched_place_name'),
      scheduledPlaceName: _string(json, 'scheduled_place_name'),
      congestionLevel: _string(json, 'congestion_level'),
      congestionMessage: _string(json, 'congestion_message'),
      populationMin: _intOrNull(json['population_min']),
      populationMax: _intOrNull(json['population_max']),
      populationTime: _string(json, 'population_time'),
      crowdScore: _int(json['crowd_score']),
      incidentBonus: _int(json['incident_bonus']),
      riskScore: _int(json['risk_score']),
      riskLevel: _string(json, 'risk_level', fallback: 'Low'),
      shouldAlert: json['should_alert'] == true,
      triggerType: _string(json, 'trigger_type', fallback: 'none'),
      alertMessage: _string(json, 'alert_message'),
      riskReason: _string(json, 'risk_reason'),
      sourceType: _string(
        json,
        'source_type',
        fallback: 'seoul_realtime_unavailable',
      ),
      sourceBadge: _string(json, 'source_badge', fallback: 'Seoul Real-time'),
    );
  }

  factory SeoulRealtimeRisk.unavailable({
    String? scheduledPlaceName,
    String reason = 'Seoul real-time city data is unavailable.',
  }) {
    return SeoulRealtimeRisk(
      areaNm: '',
      matchedPlaceName: '',
      scheduledPlaceName: scheduledPlaceName ?? '',
      congestionLevel: '',
      congestionMessage: '',
      populationMin: null,
      populationMax: null,
      populationTime: '',
      crowdScore: 0,
      incidentBonus: 0,
      riskScore: 0,
      riskLevel: 'Low',
      shouldAlert: false,
      triggerType: 'none',
      alertMessage: '',
      riskReason: reason,
      sourceType: 'seoul_realtime_unavailable',
      sourceBadge: 'Seoul Real-time',
    );
  }

  CrowdAlert toCrowdAlert({
    required String id,
    required String originalPlace,
    required String scheduledTime,
    String? planId,
    String? originalItemId,
    String? originalImageUrl,
  }) {
    return CrowdAlert(
      id: id,
      originalPlace: originalPlace,
      scheduledTime: scheduledTime,
      crowdLevel: congestionLevel.isEmpty ? riskLevel : congestionLevel,
      estimatedWait: estimatedWait,
      alertMessage: alertMessage.isEmpty
          ? '$originalPlace is $riskLevel crowd risk now.'
          : alertMessage,
      foreignerQueueTip: riskReason,
      alternatives: const [],
      sourceType: sourceType,
      sourceBadge: sourceBadge,
      planId: planId,
      originalItemId: originalItemId,
      recommendedAction: 'Review lower-crowd Re-Trip alternatives.',
      congestionLevel: congestionLevel,
      riskScore: riskScore,
      riskReason: riskReason,
      originalImageUrl: originalImageUrl,
    );
  }
}

String _normalizeCacheKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r"[\s._'`-]+"), '').trim();
}

String _string(Map<String, Object?> json, String key, {String fallback = ''}) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return value.toString();
  return fallback;
}

int _int(Object? value) {
  return _intOrNull(value) ?? 0;
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.replaceAll(',', ''));
  return null;
}
