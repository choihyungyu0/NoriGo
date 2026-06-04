import 'package:norigo/core/location/current_location_service.dart';

const userConsentVersion = '2026-06-03';

class UserConsent {
  const UserConsent({
    this.dataConsent = false,
    this.dataConsentAcceptedAt,
    this.locationConsent = false,
    this.locationConsentAcceptedAt,
    this.locationPermissionStatus,
    this.latestLocation,
    this.consentVersion = userConsentVersion,
    this.rawJson = const <String, Object?>{},
  });

  final bool dataConsent;
  final DateTime? dataConsentAcceptedAt;
  final bool locationConsent;
  final DateTime? locationConsentAcceptedAt;
  final String? locationPermissionStatus;
  final CurrentLocation? latestLocation;
  final String consentVersion;
  final Map<String, Object?> rawJson;

  UserConsent copyWith({
    bool? dataConsent,
    DateTime? dataConsentAcceptedAt,
    bool? locationConsent,
    DateTime? locationConsentAcceptedAt,
    String? locationPermissionStatus,
    CurrentLocation? latestLocation,
    String? consentVersion,
    Map<String, Object?>? rawJson,
    bool clearLatestLocation = false,
  }) {
    return UserConsent(
      dataConsent: dataConsent ?? this.dataConsent,
      dataConsentAcceptedAt:
          dataConsentAcceptedAt ?? this.dataConsentAcceptedAt,
      locationConsent: locationConsent ?? this.locationConsent,
      locationConsentAcceptedAt:
          locationConsentAcceptedAt ?? this.locationConsentAcceptedAt,
      locationPermissionStatus:
          locationPermissionStatus ?? this.locationPermissionStatus,
      latestLocation: clearLatestLocation
          ? null
          : latestLocation ?? this.latestLocation,
      consentVersion: consentVersion ?? this.consentVersion,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, Object?> toLocalJson() {
    return {
      'data_consent': dataConsent,
      'data_consent_accepted_at': dataConsentAcceptedAt?.toIso8601String(),
      'location_consent': locationConsent,
      'location_consent_accepted_at': locationConsentAcceptedAt
          ?.toIso8601String(),
      'location_permission_status': locationPermissionStatus,
      'consent_version': consentVersion,
      ...?latestLocation?.toJson(),
      'raw_json': rawJson,
    };
  }

  Map<String, Object?> toSupabaseJson(String? userId) {
    final locationJson = latestLocation?.toJson() ?? const <String, Object?>{};
    return {
      'user_id': ?userId,
      'data_consent': dataConsent,
      'data_consent_accepted_at': dataConsentAcceptedAt?.toIso8601String(),
      'location_consent': locationConsent,
      'location_consent_accepted_at': locationConsentAcceptedAt
          ?.toIso8601String(),
      'location_permission_status': locationPermissionStatus,
      'consent_version': consentVersion,
      'raw_json': {...rawJson, ...locationJson},
    };
  }

  factory UserConsent.fromJson(Map<String, Object?> json) {
    final lat = _double(json['latest_lat']);
    final lng = _double(json['latest_lng']);
    final updatedAt = _date(json['latest_location_updated_at']);
    return UserConsent(
      dataConsent: json['data_consent'] == true,
      dataConsentAcceptedAt: _date(json['data_consent_accepted_at']),
      locationConsent: json['location_consent'] == true,
      locationConsentAcceptedAt: _date(json['location_consent_accepted_at']),
      locationPermissionStatus: _string(json['location_permission_status']),
      consentVersion: _string(json['consent_version']) ?? userConsentVersion,
      latestLocation: lat == null || lng == null || updatedAt == null
          ? null
          : CurrentLocation(
              latitude: lat,
              longitude: lng,
              updatedAt: updatedAt,
            ),
      rawJson: json['raw_json'] is Map
          ? Map<String, Object?>.from(json['raw_json'] as Map)
          : const <String, Object?>{},
    );
  }

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  static double? _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}
