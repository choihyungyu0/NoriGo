import 'package:norigo/features/itinerary/domain/alternative_place.dart';

class CrowdAlert {
  const CrowdAlert({
    required this.id,
    required this.originalPlace,
    required this.scheduledTime,
    required this.crowdLevel,
    required this.estimatedWait,
    required this.alertMessage,
    required this.foreignerQueueTip,
    required this.alternatives,
    this.sourceType = 'mock',
    this.sourceBadge,
    this.planId,
    this.originalItemId,
    this.retripEventId,
    this.persisted = false,
    this.recommendedAction,
    this.congestionLevel,
    this.riskScore,
    this.riskReason,
    this.originalImageUrl,
  });

  final String id;
  final String originalPlace;
  final String scheduledTime;
  final String crowdLevel;
  final String estimatedWait;
  final String alertMessage;
  final String foreignerQueueTip;
  final List<AlternativePlace> alternatives;
  final String sourceType;
  final String? sourceBadge;
  final String? planId;
  final String? originalItemId;
  final String? retripEventId;
  final bool persisted;
  final String? recommendedAction;
  final String? congestionLevel;
  final int? riskScore;
  final String? riskReason;
  final String? originalImageUrl;

  CrowdAlert copyWith({
    String? id,
    String? originalPlace,
    String? scheduledTime,
    String? crowdLevel,
    String? estimatedWait,
    String? alertMessage,
    String? foreignerQueueTip,
    List<AlternativePlace>? alternatives,
    String? sourceType,
    String? sourceBadge,
    String? planId,
    String? originalItemId,
    String? retripEventId,
    bool? persisted,
    String? recommendedAction,
    String? congestionLevel,
    int? riskScore,
    String? riskReason,
    String? originalImageUrl,
  }) {
    return CrowdAlert(
      id: id ?? this.id,
      originalPlace: originalPlace ?? this.originalPlace,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      estimatedWait: estimatedWait ?? this.estimatedWait,
      alertMessage: alertMessage ?? this.alertMessage,
      foreignerQueueTip: foreignerQueueTip ?? this.foreignerQueueTip,
      alternatives: alternatives ?? this.alternatives,
      sourceType: sourceType ?? this.sourceType,
      sourceBadge: sourceBadge ?? this.sourceBadge,
      planId: planId ?? this.planId,
      originalItemId: originalItemId ?? this.originalItemId,
      retripEventId: retripEventId ?? this.retripEventId,
      persisted: persisted ?? this.persisted,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      riskScore: riskScore ?? this.riskScore,
      riskReason: riskReason ?? this.riskReason,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
    );
  }
}
