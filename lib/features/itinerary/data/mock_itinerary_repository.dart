import 'package:norigo/features/itinerary/data/itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class MockItineraryRepository implements ItineraryRepository {
  const MockItineraryRepository();

  @override
  Future<ItineraryPlan> fetchPlan() async {
    return mockPlan;
  }

  @override
  Future<void> savePlan(ItineraryPlan plan) async {
    return;
  }

  static const mockPlan = ItineraryPlan(
    id: 'mock-seoul-one-day',
    dateLabel: 'May 18, Sun',
    title: 'AI Itinerary Planner',
    estimatedTimeSaved: '1h 25m',
    sourceType: 'mock',
    items: [
      ItineraryItem(
        id: 'gyeongbokgung-palace',
        order: 1,
        time: '09:00',
        placeName: 'Gyeongbokgung Palace',
        crowdLevel: ItineraryCrowdLevel.low,
        stayTime: 'Stay 1h 30m',
        aiTip: 'Best time to enter!',
      ),
      ItineraryItem(
        id: 'bukchon-hanok-village',
        order: 2,
        time: '11:00',
        placeName: 'Bukchon Hanok Village',
        crowdLevel: ItineraryCrowdLevel.moderate,
        stayTime: 'Stay 1h',
        aiTip: 'Explore quiet alleyways',
      ),
      ItineraryItem(
        id: 'dessert-cafe',
        order: 3,
        time: '13:00',
        placeName: 'Dessert Cafe',
        crowdLevel: ItineraryCrowdLevel.low,
        stayTime: 'Stay 1h',
        aiTip: 'Perfect time for a break',
      ),
      ItineraryItem(
        id: 'seongsu-select-shop',
        order: 4,
        time: '15:00',
        placeName: 'Seongsu Select Shop',
        crowdLevel: ItineraryCrowdLevel.moderate,
        stayTime: 'Stay 1h 30m',
        aiTip: 'Trendy finds in Seongsu',
      ),
      ItineraryItem(
        id: 'n-seoul-tower',
        order: 5,
        time: '18:30',
        placeName: 'N Seoul Tower',
        crowdLevel: ItineraryCrowdLevel.low,
        stayTime: 'Stay 1h',
        aiTip: 'Catch the best sunset view',
        extraBadge: 'Sunset view',
      ),
    ],
  );
}
