import 'package:norigo/data/models/crowd_forecast.dart';
import 'package:norigo/data/models/itinerary.dart';
import 'package:norigo/data/models/place.dart';
import 'package:norigo/data/models/recommendation.dart';
import 'package:norigo/data/models/user_preference.dart';

class AiTravelContext {
  const AiTravelContext({
    required this.userLanguage,
    required this.userInterests,
    required this.tripLengthDays,
    required this.currentLocation,
    required this.crowdPreference,
    required this.foodRestrictions,
    required this.queueHelpPreference,
    this.scheduledItinerary,
    this.placeData = const [],
    this.publicDataSummary,
    this.nearbyAlternatives = const [],
    this.crowdForecast,
  });

  final String userLanguage;
  final List<String> userInterests;
  final int tripLengthDays;
  final String currentLocation;
  final double crowdPreference;
  final String foodRestrictions;
  final bool queueHelpPreference;
  final Itinerary? scheduledItinerary;
  final List<Place> placeData;
  final String? publicDataSummary;
  final List<Recommendation> nearbyAlternatives;
  final CrowdForecast? crowdForecast;

  Map<String, Object?> toCompactMap() {
    return {
      'language': userLanguage,
      'interests': userInterests.take(6).toList(),
      'tripLengthDays': tripLengthDays,
      'currentLocation': currentLocation,
      'crowdPreference': crowdPreference,
      'foodRestrictions': foodRestrictions,
      'queueHelpPreference': queueHelpPreference,
      'itinerary': scheduledItinerary?.items
          .map(
            (item) => {
              'time': item.time,
              'title': item.title,
              'crowd': item.crowdLevel,
            },
          )
          .toList(),
      'publicDataSummary': publicDataSummary ?? 'No public data connected yet.',
      'placeData': placeData
          .take(5)
          .map(
            (place) => {
              'name': place.name,
              'area': place.area,
              'crowd': place.crowdLevel,
              'diversity': place.diversityScore,
            },
          )
          .toList(),
      'nearbyAlternatives': nearbyAlternatives
          .take(5)
          .map(
            (place) => {
              'name': place.placeName,
              'walkMin': place.walkingMinutes,
              'diversity': place.diversityScore,
              'crowd': place.crowdLevel,
            },
          )
          .toList(),
      'crowdForecast': crowdForecast == null
          ? null
          : {
              'placeName': crowdForecast!.placeName,
              'level': crowdForecast!.crowdLevel,
              'waitMin': crowdForecast!.estimatedWaitMin,
              'waitMax': crowdForecast!.estimatedWaitMax,
              'scheduledTime': crowdForecast!.scheduledTime,
            },
    };
  }
}

class AiContextBuilder {
  const AiContextBuilder._();

  static AiTravelContext fromPreference({
    required UserPreference preference,
    required String currentLocation,
    Itinerary? itinerary,
    List<Place> places = const [],
    List<Recommendation> nearbyAlternatives = const [],
    CrowdForecast? crowdForecast,
    String? publicDataSummary,
  }) {
    return AiTravelContext(
      userLanguage: preference.preferredLanguage,
      userInterests: preference.interests,
      tripLengthDays: preference.tripLengthDays,
      currentLocation: currentLocation,
      crowdPreference: preference.crowdPreference,
      foodRestrictions: preference.foodNeeds,
      queueHelpPreference: preference.needsQueueHelp,
      scheduledItinerary: itinerary,
      placeData: places,
      publicDataSummary: publicDataSummary,
      nearbyAlternatives: nearbyAlternatives,
      crowdForecast: crowdForecast,
    );
  }
}
