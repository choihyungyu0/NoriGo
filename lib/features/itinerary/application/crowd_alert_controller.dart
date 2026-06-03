import 'package:flutter/foundation.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/itinerary/application/itinerary_source_label.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';
import 'package:norigo/features/itinerary/domain/retrip_context.dart';

enum CrowdAlertStatus { initial, loading, loaded, switching, error }

class CrowdAlertController extends ChangeNotifier {
  CrowdAlertController({
    required CrowdAlertRepository repository,
    EnnoiaAgentRepository ennoiaRepository =
        const SupabaseEnnoiaAgentRepository(),
    EnnoiaAgentRepository fallbackEnnoiaRepository =
        const MockEnnoiaAgentRepository(),
    RetripContext? retripContext,
  }) : _repository = repository,
       _ennoiaRepository = ennoiaRepository,
       _fallbackEnnoiaRepository = fallbackEnnoiaRepository,
       _retripContext = retripContext;

  final CrowdAlertRepository _repository;
  final EnnoiaAgentRepository _ennoiaRepository;
  final EnnoiaAgentRepository _fallbackEnnoiaRepository;
  final RetripContext? _retripContext;

  bool _disposed = false;
  bool _isGeneratingRetrip = false;
  CrowdAlertStatus _status = CrowdAlertStatus.initial;
  CrowdAlert? _alert;
  AlternativePlace? _selectedAlternative;
  String? _errorMessage;

  CrowdAlertStatus get status => _status;
  CrowdAlert? get alert => _alert;
  AlternativePlace? get selectedAlternative => _selectedAlternative;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CrowdAlertStatus.loading;
  bool get isSwitching => _status == CrowdAlertStatus.switching;
  bool get isGeneratingRetrip => _isGeneratingRetrip;
  String get sourceLabel {
    return itinerarySourceLabel(
      _alert?.sourceType,
      sourceBadge: _alert?.sourceBadge,
    );
  }

  bool get hasActualItem => _retripContext != null;

  RetripAgentRequest get currentRequest {
    final context = _retripContext;
    return context == null
        ? RetripAgentRequest.defaults().copyWith(
            userLanguage: AppLocaleController.currentUserLanguage,
          )
        : RetripAgentRequest.fromContext(
            context,
            userLanguage: AppLocaleController.currentUserLanguage,
          );
  }

  Future<void> loadAlert() async {
    _status = CrowdAlertStatus.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _alert = await _repository.fetchCurrentCrowdAlert();
      _selectedAlternative = null;
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
      final currentAlert = _alert;
      if (currentAlert == null) {
        throw StateError('No alert is ready.');
      }
      await _repository.switchToAlternative(currentAlert, alternative);
      _replaceCurrentPlanItem(currentAlert, alternative);
      _status = CrowdAlertStatus.loaded;
      return true;
    } catch (_) {
      final currentAlert = _alert;
      if (currentAlert != null) {
        _replaceCurrentPlanItem(currentAlert, alternative);
      }
      _errorMessage =
          'Recommendation selected, but plan update could not be saved.';
      _status = CrowdAlertStatus.error;
      return false;
    } finally {
      _safeNotifyListeners();
    }
  }

  void _replaceCurrentPlanItem(
    CrowdAlert currentAlert,
    AlternativePlace alternative,
  ) {
    final originalItemId =
        currentAlert.originalItemId ?? _retripContext?.item.id;
    if (originalItemId == null) return;
    ItinerarySessionStore.replaceItem(
      originalItemId: originalItemId,
      alternative: alternative,
    );
  }

  Future<void> generateRetripAlternatives() async {
    _isGeneratingRetrip = true;
    _errorMessage = null;
    _safeNotifyListeners();

    final request = currentRequest;

    try {
      final result = await _ennoiaRepository.fetchRetrip(request);
      _alert = result.toCrowdAlert();
      _selectedAlternative = null;
      _status = CrowdAlertStatus.loaded;
    } catch (_) {
      final fallback = await _fallbackEnnoiaRepository.fetchRetrip(request);
      _alert = fallback.toCrowdAlert();
      _selectedAlternative = null;
      _status = CrowdAlertStatus.loaded;
      _errorMessage = 'Using mock ennoia alternatives.';
    } finally {
      _isGeneratingRetrip = false;
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
