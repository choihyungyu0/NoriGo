import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

abstract interface class CrowdAlertRepository {
  Future<CrowdAlert> fetchCurrentCrowdAlert();

  Future<void> switchToAlternative(
    CrowdAlert alert,
    AlternativePlace alternative,
  );

  Future<void> keepOriginalPlan();
}
