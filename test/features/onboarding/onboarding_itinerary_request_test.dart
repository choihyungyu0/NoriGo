import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/features/onboarding/application/onboarding_preferences_store.dart';
import 'package:norigo/features/onboarding/domain/interests_alerts.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';

void main() {
  tearDown(OnboardingPreferencesStore.resetForTesting);

  test('onboarding values are used to build ItineraryRequest', () {
    OnboardingPreferencesStore.saveTripBasics(
      const TripBasics(
        preferredLanguage: 'English',
        destination: 'South Korea',
        baseLocation: 'Hongdae, Seoul',
        tripLengthDays: 4,
        companionType: 'Friends',
        foodNeed: 'Vegetarian',
      ),
    );
    OnboardingPreferencesStore.saveInterestsAlerts(
      const InterestsAlerts(
        selectedInterests: {'K-pop', 'Shopping', 'Cafe'},
        crowdPreference: 0.9,
      ),
    );

    final json = OnboardingPreferencesStore.itineraryRequest().toJson();

    expect(json['preferred_language'], 'English');
    expect(json['user_language'], 'English');
    expect(json['destination'], 'South Korea');
    expect(json['base_location'], 'Hongdae, Seoul');
    expect(json['trip_days'], '4');
    expect(json['companion_type'], 'Friends');
    expect(json['crowd_preference'], 'Lively');
    expect(json['interests'], 'Cafe, K-pop, Shopping');
    expect(json['food_needs'], 'Vegetarian');
  });

  test('different interests produce different request payloads', () {
    OnboardingPreferencesStore.saveInterestsAlerts(
      const InterestsAlerts(
        selectedInterests: {'Palace', 'Hanok village'},
        crowdPreference: 0.2,
      ),
    );
    final palacePayload = OnboardingPreferencesStore.itineraryRequest()
        .toJson();

    OnboardingPreferencesStore.saveInterestsAlerts(
      const InterestsAlerts(
        selectedInterests: {'K-pop', 'Shopping', 'Cafe'},
        crowdPreference: 0.9,
      ),
    );
    final hongdaePayload = OnboardingPreferencesStore.itineraryRequest()
        .toJson();

    expect(palacePayload['interests'], isNot(hongdaePayload['interests']));
    expect(
      palacePayload['crowd_preference'],
      isNot(hongdaePayload['crowd_preference']),
    );
  });
}
