import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class RetripContext {
  const RetripContext({
    required this.plan,
    required this.item,
    this.triggerType = 'crowd_spike',
    this.crowdLevel = 'Very High',
    this.estimatedWait = '40-60 min',
    this.userPreference = 'Nearby low-crowd alternative',
  });

  final ItineraryPlan plan;
  final ItineraryItem item;
  final String triggerType;
  final String crowdLevel;
  final String estimatedWait;
  final String userPreference;

  String get planId => plan.persistedPlanId ?? plan.id;
  String get originalItemId => item.id;
}
