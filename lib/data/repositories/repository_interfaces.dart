import 'package:norigo/data/models/crowd_forecast.dart';
import 'package:norigo/data/models/culture_guide.dart';
import 'package:norigo/data/models/dashboard_metric.dart';
import 'package:norigo/data/models/itinerary.dart';
import 'package:norigo/data/models/place.dart';
import 'package:norigo/data/models/recommendation.dart';
import 'package:norigo/data/models/user_preference.dart';
import 'package:norigo/data/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

abstract class UserPreferenceRepository {
  Future<UserPreference?> getPreference(String userId);

  Future<UserPreference> savePreference(UserPreference preference);
}

abstract class PlaceRepository {
  Future<List<Place>> searchPlaces({
    required String query,
    required String category,
  });

  Future<List<Place>> getHiddenSpots();
}

abstract class ItineraryRepository {
  Future<Itinerary> getTodayPlan(String userId);

  Future<void> savePlan(Itinerary itinerary);
}

abstract class CrowdRepository {
  Future<CrowdForecast> getForecastForPlace(String placeId);

  Future<List<Recommendation>> getAlternatives({required String placeId});
}

abstract class CultureGuideRepository {
  Future<CultureGuide> getGuideForLocation(String location);
}

abstract class DashboardRepository {
  Future<List<DashboardMetric>> getAggregateMetrics();
}
