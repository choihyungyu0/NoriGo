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
  });

  final String id;
  final String originalPlace;
  final String scheduledTime;
  final String crowdLevel;
  final String estimatedWait;
  final String alertMessage;
  final String foreignerQueueTip;
  final List<AlternativePlace> alternatives;
}
