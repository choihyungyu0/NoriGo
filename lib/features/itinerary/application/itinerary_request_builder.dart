import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/onboarding/domain/interests_alerts.dart';
import 'package:norigo/features/onboarding/domain/trip_basics.dart';

typedef ItineraryRequest = ItineraryAgentRequest;

class ItineraryRequestBuilder {
  const ItineraryRequestBuilder();

  static const defaultUserLanguage = 'English';
  static const defaultTripDays = '1';
  static const defaultBaseLocation = 'Myeongdong, Seoul';
  static const defaultTravelDate = 'May 18, Sun';
  static const defaultInterests =
      'Palace, Hanok village, Traditional market, Dessert cafe, Photo spot, Night view';
  static const defaultCompanionType = 'Solo';
  static const defaultCrowdPreference = 'Quiet to Moderate';

  ItineraryRequest build({TripBasics? basics, InterestsAlerts? alerts}) {
    final selectedInterests = alerts?.selectedInterests
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList(growable: false);

    return ItineraryRequest(
      userLanguage: _clean(basics?.preferredLanguage, defaultUserLanguage),
      tripDays: basics == null
          ? defaultTripDays
          : basics.tripLengthDays.clamp(1, 30).toString(),
      baseLocation: _baseLocationFrom(basics),
      travelDate: defaultTravelDate,
      interests: selectedInterests == null || selectedInterests.isEmpty
          ? defaultInterests
          : selectedInterests.join(', '),
      companionType: _clean(basics?.companionType, defaultCompanionType),
      crowdPreference: _crowdPreference(alerts?.crowdPreference),
    );
  }

  String _baseLocationFrom(TripBasics? basics) {
    final destination = basics?.destination.trim();
    if (destination == null || destination.isEmpty) {
      return defaultBaseLocation;
    }
    if (destination.toLowerCase() == 'south korea') {
      return defaultBaseLocation;
    }
    return destination;
  }

  String _crowdPreference(double? value) {
    if (value == null) return defaultCrowdPreference;
    if (value <= 0.25) return 'Quiet';
    if (value >= 0.75) return 'Lively';
    return defaultCrowdPreference;
  }

  String _clean(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}
