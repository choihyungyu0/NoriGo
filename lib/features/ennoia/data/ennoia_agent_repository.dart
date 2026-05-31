import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';

abstract interface class EnnoiaAgentRepository {
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  );

  Future<ItineraryAgentResult> fetchItinerary(ItineraryAgentRequest request);

  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request);
}

class CultureGuideAgentRequest {
  const CultureGuideAgentRequest({
    required this.userLanguage,
    required this.currentLocation,
    required this.detectedObject,
    required this.koreanKeyword,
    required this.userIntent,
  });

  final String userLanguage;
  final String currentLocation;
  final String detectedObject;
  final String koreanKeyword;
  final String userIntent;

  factory CultureGuideAgentRequest.defaults() {
    return const CultureGuideAgentRequest(
      userLanguage: 'English',
      currentLocation: 'Bulguksa',
      detectedObject: 'Stone stack',
      koreanKeyword: '소원성취',
      userIntent: 'Understand local culture and etiquette',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user_language': userLanguage,
      'current_location': currentLocation,
      'detected_object': detectedObject,
      'korean_keyword': koreanKeyword,
      'user_intent': userIntent,
    };
  }
}

class ItineraryAgentRequest {
  const ItineraryAgentRequest({
    required this.preferredLanguage,
    required this.userLanguage,
    required this.destination,
    required this.tripDays,
    required this.baseLocation,
    required this.travelDate,
    required this.interests,
    required this.companionType,
    required this.crowdPreference,
    required this.foodNeeds,
  });

  final String preferredLanguage;
  final String userLanguage;
  final String destination;
  final String tripDays;
  final String baseLocation;
  final String travelDate;
  final String interests;
  final String companionType;
  final String crowdPreference;
  final String foodNeeds;

  factory ItineraryAgentRequest.defaults() {
    return const ItineraryAgentRequest(
      preferredLanguage: 'English',
      userLanguage: 'English',
      destination: 'South Korea',
      tripDays: '1',
      baseLocation: 'Myeongdong, Seoul',
      travelDate: 'May 18, Sun',
      interests:
          'Palace, Hanok village, Traditional market, Dessert cafe, Photo spot, Night view',
      companionType: 'Solo',
      crowdPreference: 'Quiet to Moderate',
      foodNeeds: 'None',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'preferred_language': preferredLanguage,
      'user_language': userLanguage,
      'destination': destination,
      'trip_days': tripDays,
      'base_location': baseLocation,
      'travel_date': travelDate,
      'interests': interests,
      'companion_type': companionType,
      'crowd_preference': crowdPreference,
      'food_needs': foodNeeds,
    };
  }
}

class RetripAgentRequest {
  const RetripAgentRequest({
    required this.userLanguage,
    required this.currentLocation,
    required this.originalPlace,
    required this.originalPlaceType,
    required this.originalPlaceValue,
    required this.scheduledTime,
    required this.triggerType,
    required this.crowdLevel,
    required this.estimatedWait,
    required this.userPreference,
  });

  final String userLanguage;
  final String currentLocation;
  final String originalPlace;
  final String originalPlaceType;
  final String originalPlaceValue;
  final String scheduledTime;
  final String triggerType;
  final String crowdLevel;
  final String estimatedWait;
  final String userPreference;

  factory RetripAgentRequest.defaults() {
    return const RetripAgentRequest(
      userLanguage: 'English',
      currentLocation: 'Bukchon, Seoul',
      originalPlace: 'Cafe Arte',
      originalPlaceType: 'Dessert cafe',
      originalPlaceValue:
          'Dessert, quiet break, photogenic cafe, hanok atmosphere',
      scheduledTime: '13:00',
      triggerType: 'crowd_spike',
      crowdLevel: 'Very High',
      estimatedWait: '40-60 min',
      userPreference: 'Dessert, Quiet, Local pick, Hanok atmosphere',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user_language': userLanguage,
      'current_location': currentLocation,
      'original_place': originalPlace,
      'original_place_type': originalPlaceType,
      'original_place_value': originalPlaceValue,
      'scheduled_time': scheduledTime,
      'trigger_type': triggerType,
      'crowd_level': crowdLevel,
      'estimated_wait': estimatedWait,
      'user_preference': userPreference,
    };
  }
}
