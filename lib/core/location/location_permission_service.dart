import 'package:geolocator/geolocator.dart' as geo;

enum LocationPermissionError {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unsupported,
}

class LocationPermissionOutcome {
  const LocationPermissionOutcome({required this.status, this.error});

  final String status;
  final LocationPermissionError? error;

  bool get isGranted => status == 'granted';
}

abstract class LocationPermissionClient {
  const LocationPermissionClient();

  Future<bool> isLocationServiceEnabled();

  Future<geo.LocationPermission> checkPermission();

  Future<geo.LocationPermission> requestPermission();
}

class GeolocatorLocationPermissionClient extends LocationPermissionClient {
  const GeolocatorLocationPermissionClient();

  @override
  Future<bool> isLocationServiceEnabled() {
    return geo.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<geo.LocationPermission> checkPermission() {
    return geo.Geolocator.checkPermission();
  }

  @override
  Future<geo.LocationPermission> requestPermission() {
    return geo.Geolocator.requestPermission();
  }
}

class LocationPermissionService {
  LocationPermissionService({
    LocationPermissionClient client =
        const GeolocatorLocationPermissionClient(),
  }) : _client = client;

  final LocationPermissionClient _client;

  Future<LocationPermissionOutcome> checkPermission() {
    return _permission(request: false);
  }

  Future<LocationPermissionOutcome> requestPermission() {
    return _permission(request: true);
  }

  Future<LocationPermissionOutcome> _permission({required bool request}) async {
    try {
      final enabled = await _client.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationPermissionOutcome(
          status: 'service_disabled',
          error: LocationPermissionError.serviceDisabled,
        );
      }

      final permission = request
          ? await _client.requestPermission()
          : await _client.checkPermission();
      return _map(permission);
    } on UnsupportedError {
      return const LocationPermissionOutcome(
        status: 'unsupported',
        error: LocationPermissionError.unsupported,
      );
    } catch (_) {
      return const LocationPermissionOutcome(
        status: 'unsupported',
        error: LocationPermissionError.unsupported,
      );
    }
  }

  static LocationPermissionOutcome _map(geo.LocationPermission permission) {
    switch (permission) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return const LocationPermissionOutcome(status: 'granted');
      case geo.LocationPermission.denied:
        return const LocationPermissionOutcome(
          status: 'denied',
          error: LocationPermissionError.permissionDenied,
        );
      case geo.LocationPermission.deniedForever:
        return const LocationPermissionOutcome(
          status: 'denied_forever',
          error: LocationPermissionError.permissionDeniedForever,
        );
      case geo.LocationPermission.unableToDetermine:
        return const LocationPermissionOutcome(
          status: 'unsupported',
          error: LocationPermissionError.unsupported,
        );
    }
  }
}
