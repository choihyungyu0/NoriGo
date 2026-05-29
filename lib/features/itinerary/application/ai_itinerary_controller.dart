import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:norigo/core/auth/demo_auth_service.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/mock_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/data/supabase_ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/itinerary/application/itinerary_request_builder.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

enum AiItineraryStatus { idle, loading, loaded, saving, saved, error }

class AiItineraryController extends ChangeNotifier {
  AiItineraryController({
    EnnoiaAgentRepository ennoiaRepository =
        const SupabaseEnnoiaAgentRepository(),
    EnnoiaAgentRepository fallbackRepository =
        const MockEnnoiaAgentRepository(),
    DemoAuthService demoAuthService = const DemoAuthService(),
    bool fallbackOnGenerateFailure = false,
  }) : _ennoiaRepository = ennoiaRepository,
       _fallbackRepository = fallbackRepository,
       _demoAuthService = demoAuthService,
       _fallbackOnGenerateFailure = fallbackOnGenerateFailure;

  final EnnoiaAgentRepository _ennoiaRepository;
  final EnnoiaAgentRepository _fallbackRepository;
  final DemoAuthService _demoAuthService;
  final bool _fallbackOnGenerateFailure;

  bool _disposed = false;
  AiItineraryStatus _status = AiItineraryStatus.idle;
  String _sourceType = 'mock_ennoia';
  String _persistenceLabel = 'Local mock only';
  String? _errorMessage;
  String? _snackBarMessage;
  String? _persistedPlanId;
  ItineraryRequest? _currentRequest;
  ItineraryAgentResult? _currentResult;
  ItineraryPlan? _plan;
  Future<void>? _generationFuture;

  AiItineraryStatus get status => _status;
  ItineraryPlan? get plan => _plan;
  String? get errorMessage => _errorMessage;
  String get sourceType => _sourceType;
  String get persistenceLabel => _persistenceLabel;
  String? get persistedPlanId => _persistedPlanId;
  bool get isLoading => _status == AiItineraryStatus.loading;
  bool get isSaving => _status == AiItineraryStatus.saving;
  bool get isGeneratingEnnoia => isLoading;
  String get sourceLabel {
    final sourceType = _sourceType.toLowerCase();
    if (sourceType == 'kto_openapi_ennoia') return 'KTO OpenAPI + ennoia';
    if (sourceType == 'ennoia_kto_mcp') return 'ennoia + KTO MCP';
    if (sourceType.contains('fallback') || sourceType.contains('mock')) {
      return 'Demo fallback';
    }
    return 'Generated itinerary';
  }

  Future<void> generateItinerary(ItineraryRequest request) async {
    if (_disposed) return;

    final inFlight = _generationFuture;
    if (inFlight != null) return inFlight;

    final future = _generateItinerary(request);
    _generationFuture = future;
    try {
      await future;
    } finally {
      if (identical(_generationFuture, future)) {
        _generationFuture = null;
      }
    }
  }

  Future<void> _generateItinerary(ItineraryRequest request) async {
    _status = AiItineraryStatus.loading;
    _errorMessage = null;
    _snackBarMessage = null;
    _safeNotifyListeners();

    try {
      final result = await _ennoiaRepository.generateItinerary(request);
      if (_disposed) return;

      _currentRequest = request;
      _currentResult = result;
      _plan = result.toItineraryPlan();
      _sourceType = result.isRealEnnoia ? result.sourceType : 'mock_ennoia';
      _persistedPlanId = result.persistedPlanId;
      _persistenceLabel = _persistenceLabelForResult(result);
      _status = AiItineraryStatus.loaded;
      _safeNotifyListeners();
    } catch (error) {
      final message = _messageForError(error);
      developer.log(
        _fallbackOnGenerateFailure
            ? 'AI itinerary generation fell back to mock.'
            : 'AI itinerary generation failed.',
        name: 'AiItineraryController',
        error: error.runtimeType,
      );

      if (_fallbackOnGenerateFailure) {
        _snackBarMessage = message;
        await loadMockPlan();
        return;
      }

      if (_disposed) return;
      _status = _plan == null
          ? AiItineraryStatus.error
          : AiItineraryStatus.loaded;
      _errorMessage = message;
      _snackBarMessage = message;
      _persistenceLabel = 'Local mock only';
      _safeNotifyListeners();
    }
  }

  Future<bool> saveCurrentPlan() async {
    final request = _currentRequest;
    final result = _currentResult;

    if (request == null || result == null || !result.isRealEnnoia) {
      _status = AiItineraryStatus.saved;
      _persistenceLabel = 'Local mock only';
      _safeNotifyListeners();
      return true;
    }

    if (result.persisted) {
      _status = AiItineraryStatus.saved;
      _persistenceLabel = 'Saved to Supabase';
      _safeNotifyListeners();
      return true;
    }

    if (_disposed) return false;
    _status = AiItineraryStatus.saving;
    _errorMessage = null;
    _safeNotifyListeners();

    final hasSession = await _demoAuthService.ensureDemoSession();
    if (_disposed) return false;

    if (!hasSession) {
      _status = AiItineraryStatus.loaded;
      _persistenceLabel = 'Generated, but not saved to Supabase.';
      _snackBarMessage = 'Generated, but not saved to Supabase.';
      _safeNotifyListeners();
      return false;
    }

    try {
      await _ennoiaRepository.saveItineraryPlan(request, result);
      if (_disposed) return false;
      _status = AiItineraryStatus.saved;
      _persistenceLabel = 'Saved to Supabase';
      _safeNotifyListeners();
      return true;
    } catch (error) {
      developer.log(
        'Supabase itinerary persistence failed.',
        name: 'AiItineraryController',
        error: error.runtimeType,
      );
      if (_disposed) return false;
      _status = AiItineraryStatus.loaded;
      _persistenceLabel = 'Generated, but not saved to Supabase.';
      _snackBarMessage = 'Generated, but not saved to Supabase.';
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> loadMockPlan() async {
    if (_disposed) return;

    _status = AiItineraryStatus.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final fallback = await _fallbackRepository.fetchItinerary(
        ItineraryAgentRequest.defaults(),
      );
      if (_disposed) return;
      _currentRequest = null;
      _currentResult = fallback;
      _plan = fallback.toItineraryPlan();
      _sourceType = 'mock_ennoia';
      _persistedPlanId = null;
      _persistenceLabel = 'Local mock only';
      _status = AiItineraryStatus.loaded;
    } catch (_) {
      if (_disposed) return;
      _status = AiItineraryStatus.error;
      _errorMessage = 'Unable to load itinerary.';
    } finally {
      _safeNotifyListeners();
    }
  }

  String? takeSnackBarMessage() {
    final message = _snackBarMessage;
    _snackBarMessage = null;
    return message;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String _messageForError(Object error) {
    if (error is EnnoiaAgentException) {
      return error.message;
    }

    return 'Unable to reach KTO OpenAPI + ennoia.';
  }

  String _persistenceLabelForResult(ItineraryAgentResult result) {
    if (result.persisted) return 'Saved to Supabase';
    if (result.isRealEnnoia) return 'Generated, but not saved to Supabase.';
    return 'Local mock only';
  }
}
