import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

class MockCrowdAlertRepository implements CrowdAlertRepository {
  const MockCrowdAlertRepository();

  @override
  Future<CrowdAlert> fetchCurrentCrowdAlert() async {
    // KTO OpenAPI will later provide nearby candidate places.
    // ennoia Re-Trip Agent will later generate recommendation copy.
    return mockAlert;
  }

  @override
  Future<void> keepOriginalPlan() async {
    // Supabase will later persist that the traveler kept the original stop.
  }

  @override
  Future<void> switchToAlternative(AlternativePlace alternative) async {
    // Supabase will later persist the selected alternative itinerary item.
  }

  static const mockAlert = CrowdAlert(
    id: 'cafe-arte-crowd-alert',
    originalPlace: 'Cafe Arte',
    scheduledTime: '13:00',
    crowdLevel: 'Very High',
    estimatedWait: '40-60 min',
    alertMessage: 'Cafe Arte may become very busy within 30 minutes.',
    foreignerQueueTip:
        'Even if no visible line, app-based queues may already be full.',
    alternatives: [
      AlternativePlace(
        id: 'cafe-owall',
        name: 'Cafe Owall',
        description: 'Dessert in a calm hanok alley',
        walkingTime: '5 min walk',
        diversityScore: 92,
        crowdLevel: 'Low',
      ),
      AlternativePlace(
        id: 'seosullan-small-book-cafe',
        name: 'Seosullan Small Book Cafe',
        description: 'Quiet book cafe beloved by locals',
        walkingTime: '7 min walk',
        diversityScore: 88,
        crowdLevel: 'Low',
      ),
      AlternativePlace(
        id: 'yunsul-bakery',
        name: 'Yunsul Bakery',
        description: 'Local favorite bakery with short wait',
        walkingTime: '8 min walk',
        diversityScore: 90,
        crowdLevel: 'Low',
      ),
    ],
  );
}
