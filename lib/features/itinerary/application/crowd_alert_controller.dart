import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

enum CrowdAlertStatus { initial, loading, loaded, switching, error }

class CrowdAlertController extends ChangeNotifier {
  CrowdAlertController({
    required CrowdAlertRepository repository,
    EnnoiaAgentRepository ennoiaRepository =
        const SupabaseEnnoiaAgentRepository(),
    EnnoiaAgentRepository fallbackEnnoiaRepository =
        const MockEnnoiaAgentRepository(),
  }) : _repository = repository,
       _ennoiaRepository = ennoiaRepository,
       _fallbackEnnoiaRepository = fallbackEnnoiaRepository;

  final CrowdAlertRepository _repository;
  final EnnoiaAgentRepository _ennoiaRepository;
  final EnnoiaAgentRepository _fallbackEnnoiaRepository;

  bool _disposed = false;
  bool _isGeneratingRetrip = false;
  CrowdAlertStatus _status = CrowdAlertStatus.initial;
  CrowdAlert? _alert;
  AlternativePlace? _selectedAlternative;
  String? _errorMessage;
  String _persistenceLabel = 'Local mock only';

  CrowdAlertStatus get status => _status;
  CrowdAlert? get alert => _alert;
  AlternativePlace? get selectedAlternative => _selectedAlternative;
  String? get errorMessage => _errorMessage;
  String get persistenceLabel => _persistenceLabel;
  bool get isLoading => _status == CrowdAlertStatus.loading;
  bool get isSwitching => _status == CrowdAlertStatus.switching;
  bool get isGeneratingRetrip => _isGeneratingRetrip;
  String get sourceLabel {
    return _alert?.sourceType == 'ennoia' ? 'ennoia + KTO MCP' : 'Mock ennoia';
  }

  Future<void> loadAlert() async {
    _status = CrowdAlertStatus.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _alert = await _repository.fetchCurrentCrowdAlert();
      _selectedAlternative = null;
      _persistenceLabel = 'Local mock only';
      _status = CrowdAlertStatus.loaded;
    } catch (_) {
      _errorMessage = 'Unable to load crowd alert.';
      _status = CrowdAlertStatus.error;
    } finally {
      _safeNotifyListeners();
    }
  }

  void selectAlternative(AlternativePlace alternative) {
    _selectedAlternative = alternative;
    _safeNotifyListeners();
  }

  Future<bool> keepOriginalPlan() async {
    _status = CrowdAlertStatus.switching;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _repository.keepOriginalPlan();
      _status = CrowdAlertStatus.loaded;
      return true;
    } catch (_) {
      _errorMessage = 'Unable to keep the original plan.';
      _status = CrowdAlertStatus.error;
      return false;
    } finally {
      _safeNotifyListeners();
    }
  }

  Future<bool> switchPlan() async {
    final currentAlert = _alert;
    if (currentAlert == null || currentAlert.alternatives.isEmpty) {
      _errorMessage = 'No alternative is ready yet.';
      _status = CrowdAlertStatus.error;
      _safeNotifyListeners();
      return false;
    }

    final alternative = _selectedAlternative ?? currentAlert.alternatives.first;
    return switchToAlternative(alternative);
  }

  Future<bool> switchToAlternative(AlternativePlace alternative) async {
    _selectedAlternative = alternative;
    _status = CrowdAlertStatus.switching;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _repository.switchToAlternative(alternative);
      _status = CrowdAlertStatus.loaded;
      return true;
    } catch (_) {
      _errorMessage = 'Unable to switch the plan.';
      _status = CrowdAlertStatus.error;
      return false;
    } finally {
      _safeNotifyListeners();
    }
  }

  Future<void> generateRetripAlternatives() async {
    _isGeneratingRetrip = true;
    _errorMessage = null;
    _safeNotifyListeners();

    final request = RetripAgentRequest.defaults();

    try {
      final result = await _ennoiaRepository.fetchRetrip(request);
      _alert = result.toCrowdAlert();
      _selectedAlternative = null;
      final saved = result.isRealEnnoia
          ? await _saveReTripEvent(request, result)
          : false;
      _persistenceLabel = saved ? 'Saved to Supabase' : 'Local mock only';
      _status = CrowdAlertStatus.loaded;
    } catch (_) {
      final fallback = await _fallbackEnnoiaRepository.fetchRetrip(request);
      _alert = fallback.toCrowdAlert();
      _selectedAlternative = null;
      _persistenceLabel = 'Local mock only';
      _status = CrowdAlertStatus.loaded;
      _errorMessage = 'Using mock ennoia alternatives.';
    } finally {
      _isGeneratingRetrip = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> _saveReTripEvent(
    RetripAgentRequest request,
    RetripAgentResult result,
  ) async {
    try {
      await _ennoiaRepository.saveReTripEvent(request, result);
      return true;
    } catch (error) {
      developer.log(
        'Supabase Re-Trip persistence skipped.',
        name: 'CrowdAlertController',
        error: error.runtimeType,
      );
      return false;
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
