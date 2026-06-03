import 'package:flutter/foundation.dart';
import 'package:norigo/features/crowd/data/seoul_realtime_risk_repository.dart';
import 'package:norigo/features/crowd/domain/seoul_realtime_risk.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';

class SeoulRealtimeRiskController extends ChangeNotifier {
  SeoulRealtimeRiskController({
    required SeoulRealtimeRiskRepository repository,
    DateTime Function()? now,
    this.throttleDuration = const Duration(minutes: 3),
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final SeoulRealtimeRiskRepository _repository;
  final DateTime Function() _now;
  final Duration throttleDuration;
  final Map<String, _CachedRisk> _cache = {};

  bool _disposed = false;
  bool _isChecking = false;
  SeoulRealtimeRisk? _latestRisk;

  bool get isChecking => _isChecking;
  SeoulRealtimeRisk? get latestRisk => _latestRisk;

  Future<SeoulRealtimeRisk> checkItineraryItem(
    ItineraryItem item, {
    String? currentPlaceName,
    double? currentLat,
    double? currentLng,
    bool forceRefresh = false,
  }) {
    return checkRisk(
      SeoulRealtimeRiskRequest(
        currentLat: currentLat ?? item.mapY,
        currentLng: currentLng ?? item.mapX,
        currentPlaceName: currentPlaceName,
        scheduledPlaceName: item.placeName,
        scheduledTime: item.time,
        triggerContext: 'itinerary_check',
      ),
      forceRefresh: forceRefresh,
    );
  }

  Future<SeoulRealtimeRisk> checkRisk(
    SeoulRealtimeRiskRequest request, {
    bool forceRefresh = false,
  }) async {
    final lookupKey = request.cacheKey;
    final cached = _cache[lookupKey];
    final now = _now();

    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.checkedAt) < throttleDuration) {
      _latestRisk = cached.risk;
      _safeNotifyListeners();
      return cached.risk;
    }

    _isChecking = true;
    _safeNotifyListeners();

    final risk = await _repository.checkRisk(request);
    final checkedAt = _now();
    final entry = _CachedRisk(risk: risk, checkedAt: checkedAt);
    _cache[lookupKey] = entry;
    if (risk.areaNm.trim().isNotEmpty) {
      _cache[_normalizeCacheKey(risk.areaNm)] = entry;
    }
    _latestRisk = risk;
    _isChecking = false;
    _safeNotifyListeners();
    return risk;
  }

  void clearCacheForTesting() {
    _cache.clear();
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
}

class _CachedRisk {
  const _CachedRisk({required this.risk, required this.checkedAt});

  final SeoulRealtimeRisk risk;
  final DateTime checkedAt;
}

String _normalizeCacheKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r"[\s._'`-]+"), '').trim();
}
