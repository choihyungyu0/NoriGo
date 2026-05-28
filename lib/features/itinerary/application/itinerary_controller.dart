import 'package:flutter/foundation.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/itinerary/data/itinerary_repository.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class ItineraryController extends ChangeNotifier {
  ItineraryController({
    required ItineraryRepository repository,
    EnnoiaAgentRepository ennoiaRepository =
        const SupabaseEnnoiaAgentRepository(),
    EnnoiaAgentRepository fallbackEnnoiaRepository =
        const MockEnnoiaAgentRepository(),
  }) : _repository = repository,
       _ennoiaRepository = ennoiaRepository,
       _fallbackEnnoiaRepository = fallbackEnnoiaRepository;

  final ItineraryRepository _repository;
  final EnnoiaAgentRepository _ennoiaRepository;
  final EnnoiaAgentRepository _fallbackEnnoiaRepository;

  bool _disposed = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isGeneratingEnnoia = false;
  String? _errorMessage;
  ItineraryPlan? _plan;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isGeneratingEnnoia => _isGeneratingEnnoia;
  String? get errorMessage => _errorMessage;
  ItineraryPlan? get plan => _plan;
  String get sourceLabel {
    return _plan?.sourceType == 'ennoia' ? 'ennoia + KTO MCP' : 'Mock ennoia';
  }

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

  Future<void> generateWithEnnoia() async {
    _isGeneratingEnnoia = true;
    _errorMessage = null;
    _safeNotifyListeners();

    final request = ItineraryAgentRequest.defaults();

    try {
      final result = await _ennoiaRepository.fetchItinerary(request);
      _plan = result.toItineraryPlan();
    } catch (_) {
      final fallback = await _fallbackEnnoiaRepository.fetchItinerary(request);
      _plan = fallback.toItineraryPlan();
      _errorMessage = 'Using mock ennoia itinerary.';
    } finally {
      _isGeneratingEnnoia = false;
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
