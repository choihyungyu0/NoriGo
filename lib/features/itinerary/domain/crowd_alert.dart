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
}
