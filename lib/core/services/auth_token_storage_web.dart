import 'package:web/web.dart' as web;

class AuthTokenStorage {
  const AuthTokenStorage._();

  static const _accessTokenKey = 'norigo.supabase.access_token';

  static String? readAccessToken() {
    final token = web.window.localStorage.getItem(_accessTokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static void writeAccessToken(String? token) {
    final trimmed = token?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      clear();
      return;
    }
    web.window.localStorage.setItem(_accessTokenKey, trimmed);
  }

  static void clear() {
    web.window.localStorage.removeItem(_accessTokenKey);
  }
}
