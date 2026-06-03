import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/itinerary/application/itinerary_request_builder.dart';
import 'package:norigo/features/onboarding/domain/interests_alerts.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';

void main() {
  test('ItineraryRequestBuilder uses onboarding values', () {
    final request = const ItineraryRequestBuilder().build(
      basics: const TripBasics(
        preferredLanguage: 'English',
        destination: 'Seoul',
        tripLengthDays: 4,
        companionType: 'Friends',
      ),
      alerts: const InterestsAlerts(
        selectedInterests: {'Food', 'Hanok', 'Night view'},
        crowdPreference: 0.8,
      ),
    );

    expect(request.userLanguage, 'English');
    expect(request.tripDays, '4');
    expect(request.baseLocation, 'Seoul');
    expect(request.travelDate, 'May 18, Sun');
    expect(request.interests, 'Food, Hanok, Night view');
    expect(request.companionType, 'Friends');
    expect(request.crowdPreference, 'Lively');
  });

  test('ItineraryRequestBuilder uses defaults when values are missing', () {
    final request = const ItineraryRequestBuilder().build();

    expect(request.userLanguage, 'English');
    expect(request.tripDays, '1');
    expect(request.baseLocation, 'Myeongdong, Seoul');
    expect(request.travelDate, 'May 18, Sun');
    expect(
      request.interests,
      'Palace, Hanok village, Traditional market, Dessert cafe, Photo spot, Night view',
    );
    expect(request.companionType, 'Solo');
    expect(request.crowdPreference, 'Quiet to Moderate');
  });
}
