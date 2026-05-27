import 'package:flutter/foundation.dart';
import 'package:norigo/features/itinerary/data/crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/crowd_alert.dart';

enum CrowdAlertStatus { initial, loading, loaded, switching, error }

class CrowdAlertController extends ChangeNotifier {
  CrowdAlertController({required CrowdAlertRepository repository})
    : _repository = repository;

  final CrowdAlertRepository _repository;

  bool _disposed = false;
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
