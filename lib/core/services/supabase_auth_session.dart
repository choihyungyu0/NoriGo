import 'package:norigo/core/services/auth_token_storage.dart';

class SupabaseAuthSession {
  const SupabaseAuthSession._();

  static String? _accessToken;
  static bool _didLoadStoredToken = false;

  static String? get accessToken {
    _loadStoredToken();
    return _accessToken;
  }

  static void updateAccessToken(String? token) {
    final trimmed = token?.trim();
    _accessToken = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _didLoadStoredToken = true;
    AuthTokenStorage.writeAccessToken(_accessToken);
  }

  static void clear() {
    _accessToken = null;
    _didLoadStoredToken = true;
    AuthTokenStorage.clear();
  }

  static void _loadStoredToken() {
    if (_didLoadStoredToken) return;
    _didLoadStoredToken = true;
    _accessToken = AuthTokenStorage.readAccessToken();
  }
}
