import 'package:flutter/foundation.dart';
import 'package:norigo/features/itinerary/data/itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class ItineraryController extends ChangeNotifier {
  ItineraryController({required ItineraryRepository repository})
    : _repository = repository;

  final ItineraryRepository _repository;

  bool _disposed = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  ItineraryPlan? _plan;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  ItineraryPlan? get plan => _plan;

  Future<void> loadPlan() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _plan = await _repository.fetchPlan();
    } catch (_) {
      _errorMessage = 'Unable to load itinerary.';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> savePlan() async {
    final currentPlan = _plan;
    if (currentPlan == null) {
      _errorMessage = 'No itinerary is ready to save.';
      _safeNotifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _repository.savePlan(currentPlan);
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save itinerary.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
