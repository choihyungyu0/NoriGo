import 'dart:convert';

import 'package:norigo/features/onboarding/domain/user_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserConsentStore {
  const UserConsentStore._();

  static const _consentKey = 'norigo.user_consent';

  static UserConsent _current = const UserConsent();

  static UserConsent get current => _current;

  static Future<UserConsent> loadLocal() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_consentKey);
      if (encoded == null || encoded.isEmpty) return _current;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return _current;
      _current = UserConsent.fromJson(Map<String, Object?>.from(decoded));
      return _current;
    } catch (_) {
      return _current;
    }
  }

  static Future<void> saveLocal(UserConsent consent) async {
    _current = consent;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _consentKey,
        jsonEncode(consent.toLocalJson()),
      );
    } catch (_) {
      // In-memory consent still lets the app continue if local storage fails.
    }
  }

  static void resetForTesting([UserConsent consent = const UserConsent()]) {
    _current = consent;
  }
}
