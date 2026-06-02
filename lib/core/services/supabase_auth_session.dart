import 'dart:convert';

import 'package:norigo/core/services/auth_token_storage.dart';

class SupabaseAuthSession {
  const SupabaseAuthSession._();

  static String? _accessToken;
  static bool _didLoadStoredToken = false;

  static String? get accessToken {
    _loadStoredToken();
    return _accessToken;
  }

  static String? get userId {
    final token = accessToken;
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padded = payload.padRight(
        payload.length + ((4 - payload.length % 4) % 4),
        '=',
      );
      final decoded = jsonDecode(utf8.decode(base64Decode(padded)));
      if (decoded is Map) {
        final sub = decoded['sub'];
        return sub is String && sub.trim().isNotEmpty ? sub.trim() : null;
      }
    } catch (_) {
      return null;
    }
    return null;
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
