import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/onboarding/domain/interests_alerts.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';

class OnboardingPreferencesStore {
  const OnboardingPreferencesStore._();

  static TripBasics _tripBasics = const TripBasics();
  static InterestsAlerts _interestsAlerts = const InterestsAlerts();

  static TripBasics get tripBasics => _tripBasics;
  static InterestsAlerts get interestsAlerts => _interestsAlerts;

  static void saveTripBasics(TripBasics basics) {
    _tripBasics = basics;
  }

  static void saveInterestsAlerts(InterestsAlerts interestsAlerts) {
    _interestsAlerts = interestsAlerts;
  }

  static void resetForTesting() {
    _tripBasics = const TripBasics();
    _interestsAlerts = const InterestsAlerts();
  }

  static ItineraryAgentRequest itineraryRequest({String? userLanguage}) {
    final basics = _tripBasics;
    final interests = _interestsAlerts;
    final language = userLanguage ?? basics.preferredLanguage;
    final selectedInterests = interests.selectedInterests.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ItineraryAgentRequest(
      preferredLanguage: language,
      userLanguage: language,
      destination: basics.destination,
      tripDays: basics.tripLengthDays.toString(),
      baseLocation: basics.baseLocation,
      travelDate: 'May 18, Sun',
      interests: selectedInterests.join(', '),
      companionType: basics.companionType,
      crowdPreference: _crowdPreferenceLabel(interests.crowdPreference),
      foodNeeds: basics.foodNeed,
    );
  }

  static String _crowdPreferenceLabel(double value) {
    if (value <= 0.25) return 'Quiet';
    if (value < 0.50) return 'Quiet to Moderate';
    if (value < 0.80) return 'Moderate';
    return 'Lively';
  }
}
