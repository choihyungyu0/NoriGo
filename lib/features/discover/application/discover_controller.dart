import 'package:flutter/foundation.dart';
import 'package:norigo/core/location/current_location_service.dart';
import 'package:norigo/features/discover/data/discover_repository.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';
import 'package:norigo/features/discover/domain/discover_recommendation_result.dart';
import 'package:norigo/features/onboarding/application/onboarding_preferences_store.dart';
import 'package:norigo/features/onboarding/application/user_consent_store.dart';

class DiscoverController extends ChangeNotifier {
  DiscoverController({
    required DiscoverRepository repository,
    CurrentLocationService? locationService,
  }) : _repository = repository,
       _locationService = locationService ?? CurrentLocationService();

  final DiscoverRepository _repository;
  final CurrentLocationService _locationService;

  DiscoverCategory _category = DiscoverCategory.quietCafe;
  DiscoverLoadState _state = DiscoverLoadState.loading;
  List<DiscoverPlace> _places = const [];
  String _query = '';
  String? _errorMessage;
  String _sourceBadge = 'Demo fallback';
  String _sourceType = 'local_fallback';
  String? _lastSaveMessage;
  String? _selectedPlaceId;
  DiscoverMapCenter _mapCenter = const DiscoverMapCenter.seoul();
  bool _usedCurrentLocation = false;
  bool _isDisposed = false;

  DiscoverCategory get category => _category;
  DiscoverLoadState get state => _state;
  List<DiscoverPlace> get places => _places;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  String get sourceBadge => _sourceBadge;
  String get sourceType => _sourceType;
  String? get lastSaveMessage => _lastSaveMessage;
  String? get selectedPlaceId => _selectedPlaceId;
  DiscoverMapCenter get mapCenter => _mapCenter;
  bool get usedCurrentLocation => _usedCurrentLocation;
  DiscoverPlace? get selectedPlace {
    for (final place in _places) {
      if (place.id == _selectedPlaceId) return place;
    }
    return _places.isEmpty ? null : _places.first;
  }

  bool get isLoading => _state == DiscoverLoadState.loading;

  Future<void> load() => _fetch();

  Future<void> selectCategory(DiscoverCategory category) async {
    if (_category == category && _places.isNotEmpty) return;
    _category = category;
    _selectedPlaceId = null;
    await _fetch();
  }

  Future<void> search(String query) async {
    _query = query;
    _selectedPlaceId = null;
    await _fetch();
  }

  void selectPlace(String placeId) {
    if (_selectedPlaceId == placeId) return;
    _selectedPlaceId = placeId;
    _notifyIfActive();
  }

  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async {
    final result = await _repository.savePlace(place);
    if (_isDisposed) return result;
    if (result.saved) {
      _places = _places
          .map(
            (item) => item.id == place.id ? item.copyWith(isSaved: true) : item,
          )
          .toList(growable: false);
    }
    _lastSaveMessage = result.message;
    _notifyIfActive();
    return result;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_isDisposed) return;
    _state = DiscoverLoadState.loading;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final basics = OnboardingPreferencesStore.tripBasics;
      final consent = await UserConsentStore.loadLocal();
      CurrentLocation? currentLocation;
      if (consent.locationConsent) {
        final locationResult = await _locationService.getCurrentLocation();
        currentLocation = locationResult.location;
        if (currentLocation == null &&
            locationResult.error != CurrentLocationError.permissionDenied &&
            locationResult.error !=
                CurrentLocationError.permissionDeniedForever &&
            locationResult.error != CurrentLocationError.serviceDisabled) {
          currentLocation = await _locationService.latestKnownLocation();
        }
      }
      _usedCurrentLocation = currentLocation != null;
      _mapCenter = currentLocation == null
          ? DiscoverMapCenter.forBaseLocation(basics.baseLocation)
          : DiscoverMapCenter(
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude,
            );
      final result = await _repository.fetchRecommendations(
        category: _category,
        query: _query,
        userLanguage: basics.preferredLanguage,
        baseLocation: basics.baseLocation,
        currentLat: currentLocation?.latitude,
        currentLng: currentLocation?.longitude,
      );
      if (_isDisposed) return;
      _places = result.places;
      _sourceBadge = result.sourceBadge;
      _sourceType = result.sourceType;
      _errorMessage = result.errorMessage;
      _selectedPlaceId = _places.isEmpty ? null : _places.first.id;
      _state = _places.isEmpty
          ? DiscoverLoadState.empty
          : result.isLocalFallback
          ? DiscoverLoadState.localFallback
          : DiscoverLoadState.loaded;
    } catch (error) {
      if (_isDisposed) return;
      _places = const [];
      _errorMessage = 'Unable to load Discover recommendations.';
      _state = DiscoverLoadState.error;
      _usedCurrentLocation = false;
    }
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }
}

class DiscoverMapCenter {
  const DiscoverMapCenter({required this.latitude, required this.longitude});

  const DiscoverMapCenter.seoul() : latitude = 37.5665, longitude = 126.9780;

  final double latitude;
  final double longitude;

  static DiscoverMapCenter forBaseLocation(String baseLocation) {
    final normalized = baseLocation.toLowerCase();
    if (normalized.contains('hongdae') || normalized.contains('홍대')) {
      return const DiscoverMapCenter(latitude: 37.5563, longitude: 126.9236);
    }
    if (normalized.contains('myeongdong') || normalized.contains('명동')) {
      return const DiscoverMapCenter(latitude: 37.5636, longitude: 126.9820);
    }
    if (normalized.contains('gangnam') || normalized.contains('강남')) {
      return const DiscoverMapCenter(latitude: 37.4979, longitude: 127.0276);
    }
    if (normalized.contains('gwanghwamun') || normalized.contains('광화문')) {
      return const DiscoverMapCenter(latitude: 37.5759, longitude: 126.9768);
    }
    if (normalized.contains('bukchon') || normalized.contains('북촌')) {
      return const DiscoverMapCenter(latitude: 37.5815, longitude: 126.9849);
    }
    return const DiscoverMapCenter.seoul();
  }
}
