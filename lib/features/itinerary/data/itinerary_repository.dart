import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

abstract interface class ItineraryRepository {
  Future<ItineraryPlan> fetchPlan();

  Future<void> savePlan(ItineraryPlan plan);
}
