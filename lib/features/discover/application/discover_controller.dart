import 'package:flutter/foundation.dart';
import 'package:norigo/features/discover/data/discover_repository.dart';
import 'package:norigo/features/discover/domain/discover_category.dart';
import 'package:norigo/features/discover/domain/discover_place.dart';
import 'package:norigo/features/discover/domain/discover_recommendation_result.dart';

class DiscoverController extends ChangeNotifier {
  DiscoverController({required DiscoverRepository repository})
    : _repository = repository;

  final DiscoverRepository _repository;

  DiscoverCategory _category = DiscoverCategory.quietCafe;
  DiscoverLoadState _state = DiscoverLoadState.loading;
  List<DiscoverPlace> _places = const [];
  String _query = '';
  String? _errorMessage;
  String _sourceBadge = 'Demo fallback';
  String _sourceType = 'local_fallback';
  String? _lastSaveMessage;
  String? _selectedPlaceId;

  DiscoverCategory get category => _category;
  DiscoverLoadState get state => _state;
  List<DiscoverPlace> get places => _places;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  String get sourceBadge => _sourceBadge;
  String get sourceType => _sourceType;
  String? get lastSaveMessage => _lastSaveMessage;
  String? get selectedPlaceId => _selectedPlaceId;
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
    notifyListeners();
  }

  Future<DiscoverSaveResult> savePlace(DiscoverPlace place) async {
    final result = await _repository.savePlace(place);
    if (result.saved) {
      _places = _places
          .map(
            (item) => item.id == place.id ? item.copyWith(isSaved: true) : item,
          )
          .toList(growable: false);
    }
    _lastSaveMessage = result.message;
    notifyListeners();
    return result;
  }

  Future<void> _fetch() async {
    _state = DiscoverLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.fetchRecommendations(
        category: _category,
        query: _query,
      );
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
      _places = const [];
      _errorMessage = 'Unable to load Discover recommendations.';
      _state = DiscoverLoadState.error;
    }
    notifyListeners();
  }
}
