import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:norigo/core/location/location_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CurrentLocationError {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unsupported,
}

class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return {
      'latest_lat': latitude,
      'latest_lng': longitude,
      'latest_location_updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CurrentLocationResult {
  const CurrentLocationResult({
    this.location,
    this.error,
    this.permissionStatus,
  });

  final CurrentLocation? location;
  final CurrentLocationError? error;
  final String? permissionStatus;

  bool get hasLocation => location != null;
}

abstract class CurrentPositionClient {
  const CurrentPositionClient();

  Future<geo.Position> getCurrentPosition({required Duration timeout});
}

class GeolocatorCurrentPositionClient extends CurrentPositionClient {
  const GeolocatorCurrentPositionClient();

  @override
  Future<geo.Position> getCurrentPosition({required Duration timeout}) {
    return geo.Geolocator.getCurrentPosition(
      locationSettings: geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );
  }
}

class CurrentLocationService {
  CurrentLocationService({
    LocationPermissionService? permissionService,
    CurrentPositionClient positionClient =
        const GeolocatorCurrentPositionClient(),
    SharedPreferences? preferences,
    Duration timeout = const Duration(seconds: 8),
  }) : _permissionService = permissionService ?? LocationPermissionService(),
       _positionClient = positionClient,
       _preferences = preferences,
       _timeout = timeout;

  static const _latKey = 'norigo.location.latest_lat';
  static const _lngKey = 'norigo.location.latest_lng';
  static const _updatedAtKey = 'norigo.location.latest_location_updated_at';

  final LocationPermissionService _permissionService;
  final CurrentPositionClient _positionClient;
  final SharedPreferences? _preferences;
  final Duration _timeout;

  CurrentLocation? _memoryLocation;

  Future<CurrentLocationResult> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    final permission = requestPermission
        ? await _permissionService.requestPermission()
        : await _permissionService.checkPermission();
    if (!permission.isGranted) {
      return CurrentLocationResult(
        error: _permissionError(permission.error),
        permissionStatus: permission.status,
      );
    }

    try {
      final position = await _positionClient.getCurrentPosition(
        timeout: _timeout,
      );
      final location = CurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        updatedAt: DateTime.now().toUtc(),
      );
      await cacheLocation(location);
      return CurrentLocationResult(
        location: location,
        permissionStatus: permission.status,
      );
    } on TimeoutException {
      return const CurrentLocationResult(error: CurrentLocationError.timeout);
    } on geo.LocationServiceDisabledException {
      return const CurrentLocationResult(
        error: CurrentLocationError.serviceDisabled,
        permissionStatus: 'service_disabled',
      );
    } on geo.PermissionDeniedException {
      return const CurrentLocationResult(
        error: CurrentLocationError.permissionDenied,
        permissionStatus: 'denied',
      );
    } on UnsupportedError {
      return const CurrentLocationResult(
        error: CurrentLocationError.unsupported,
      );
    } catch (_) {
      return const CurrentLocationResult(
        error: CurrentLocationError.unsupported,
      );
    }
  }

  Future<CurrentLocation?> latestKnownLocation() async {
    final memory = _memoryLocation;
    if (memory != null) return memory;

    try {
      final preferences = await _resolvedPreferences();
      final lat = preferences.getDouble(_latKey);
      final lng = preferences.getDouble(_lngKey);
      final updatedAtValue = preferences.getString(_updatedAtKey);
      final updatedAt = updatedAtValue == null
          ? null
          : DateTime.tryParse(updatedAtValue);
      if (lat == null || lng == null || updatedAt == null) return null;
      _memoryLocation = CurrentLocation(
        latitude: lat,
        longitude: lng,
        updatedAt: updatedAt,
      );
      return _memoryLocation;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheLocation(CurrentLocation location) async {
    _memoryLocation = location;
    try {
      final preferences = await _resolvedPreferences();
      await preferences.setDouble(_latKey, location.latitude);
      await preferences.setDouble(_lngKey, location.longitude);
      await preferences.setString(
        _updatedAtKey,
        location.updatedAt.toIso8601String(),
      );
    } catch (_) {
      // Memory cache is enough for the current session if local storage fails.
    }
  }

  Future<SharedPreferences> _resolvedPreferences() async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  static CurrentLocationError? _permissionError(
    LocationPermissionError? error,
  ) {
    return switch (error) {
      LocationPermissionError.permissionDenied =>
        CurrentLocationError.permissionDenied,
      LocationPermissionError.permissionDeniedForever =>
        CurrentLocationError.permissionDeniedForever,
      LocationPermissionError.serviceDisabled =>
        CurrentLocationError.serviceDisabled,
      LocationPermissionError.unsupported => CurrentLocationError.unsupported,
      null => null,
    };
  }
}
