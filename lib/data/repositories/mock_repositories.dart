import 'package:norigo/core/utils/crowd_utils.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';
import 'package:norigo/data/models/crowd_forecast.dart';
import 'package:norigo/data/models/culture_guide.dart';
import 'package:norigo/data/models/dashboard_metric.dart';
import 'package:norigo/data/models/itinerary.dart';
import 'package:norigo/data/models/place.dart';
import 'package:norigo/data/models/recommendation.dart';
import 'package:norigo/data/models/user_preference.dart';
import 'package:norigo/data/models/user_profile.dart';
import 'package:norigo/data/repositories/repository_interfaces.dart';

Future<T> _mockDelay<T>(T value) async {
  await Future<void>.delayed(const Duration(milliseconds: 90));
  return value;
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserProfile?> getCurrentUser() => _mockDelay(MockNoriGoData.user);

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _mockDelay(MockNoriGoData.user);
  }

  @override
  Future<void> signOut() => _mockDelay(null);
}

class MockUserPreferenceRepository implements UserPreferenceRepository {
  @override
  Future<UserPreference?> getPreference(String userId) {
    if (userId.isEmpty) {
      return _mockDelay(null);
    }
    return _mockDelay(MockNoriGoData.preference);
  }

  @override
  Future<UserPreference> savePreference(UserPreference preference) {
    return _mockDelay(preference);
  }
}

class MockPlaceRepository implements PlaceRepository {
  @override
  Future<List<Place>> getHiddenSpots() =>
      _mockDelay(MockNoriGoData.hiddenSpots);

  @override
  Future<List<Place>> searchPlaces({
    required String query,
    required String category,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = category.trim().toLowerCase();
    final places = MockNoriGoData.hiddenSpots.where((place) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          place.name.toLowerCase().contains(normalizedQuery) ||
          place.area.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          normalizedCategory.isEmpty ||
          normalizedCategory == 'all' ||
          place.category.toLowerCase() == normalizedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
    return _mockDelay(places);
  }
}

class MockItineraryRepository implements ItineraryRepository {
  @override
  Future<Itinerary> getTodayPlan(String userId) {
    return _mockDelay(MockNoriGoData.itinerary);
  }

  @override
  Future<void> savePlan(Itinerary itinerary) => _mockDelay(null);
}

class MockCrowdRepository implements CrowdRepository {
  @override
  Future<List<Recommendation>> getAlternatives({required String placeId}) {
    return _mockDelay(
      RecommendationRanker.rankNearby(MockNoriGoData.alertAlternatives),
    );
  }

  @override
  Future<CrowdForecast> getForecastForPlace(String placeId) {
    return _mockDelay(MockNoriGoData.crowdForecast);
  }
}

class MockCultureGuideRepository implements CultureGuideRepository {
  @override
  Future<CultureGuide> getGuideForLocation(String location) {
    return _mockDelay(MockNoriGoData.cultureGuide);
  }
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<List<DashboardMetric>> getAggregateMetrics() {
    return _mockDelay(MockNoriGoData.dashboardMetrics);
  }
}
