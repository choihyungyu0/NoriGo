import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/data/models/user_profile.dart';
import 'package:norigo/data/repositories/repository_interfaces.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<UserProfile?> getCurrentUser() async {
    final token = SupabaseAuthSession.accessToken;
    if (token == null || token.isEmpty || !config.isConfigured) return null;

    final response = await _send(
      _authUri('user'),
      method: 'GET',
      accessToken: token,
    );
    if (response.statusCode == 401) {
      SupabaseAuthSession.clear();
      return null;
    }
    if (!_isSuccess(response.statusCode)) {
      throw AuthRepositoryException(_errorMessage(response));
    }

    final decoded = _decodeMap(response.body);
    return _profileFromUser(decoded);
  }

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _send(
      _authUri('token', query: {'grant_type': 'password'}),
      body: {'email': email.trim(), 'password': password},
    );
    return _profileFromAuthResponse(response, fallbackEmail: email);
  }

  @override
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _send(
      _authUri('signup'),
      body: {
        'email': email.trim(),
        'password': password,
        'data': {'display_name': _displayNameFromEmail(email)},
      },
    );
    return _profileFromAuthResponse(response, fallbackEmail: email);
  }

  @override
  Future<void> signOut() async {
    final token = SupabaseAuthSession.accessToken;
    SupabaseAuthSession.clear();
    if (token == null || token.isEmpty || !config.isConfigured) return;

    final response = await _send(_authUri('logout'), accessToken: token);
    if (!_isSuccess(response.statusCode) && response.statusCode != 401) {
      throw AuthRepositoryException(_errorMessage(response));
    }
  }

  Future<http.Response> _send(
    Uri uri, {
    String method = 'POST',
    Map<String, Object?>? body,
    String? accessToken,
  }) {
    final headers = {
      'apikey': config.anonKey,
      'Authorization': 'Bearer ${accessToken ?? config.anonKey}',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final client = _client;

    return switch (method) {
      'GET' =>
        client?.get(uri, headers: headers) ?? http.get(uri, headers: headers),
      _ =>
        client?.post(uri, headers: headers, body: encodedBody) ??
            http.post(uri, headers: headers, body: encodedBody),
    };
  }

  UserProfile _profileFromAuthResponse(
    http.Response response, {
    required String fallbackEmail,
  }) {
    if (!_isSuccess(response.statusCode)) {
      throw AuthRepositoryException(_errorMessage(response));
    }

    final decoded = _decodeMap(response.body);
    final accessToken = decoded['access_token'];
    if (accessToken is String && accessToken.isNotEmpty) {
      SupabaseAuthSession.updateAccessToken(accessToken);
    }

    final user = decoded['user'];
    if (user is Map) {
      return _profileFromUser(Map<String, Object?>.from(user));
    }

    return UserProfile(
      id: '',
      displayName: _displayNameFromEmail(fallbackEmail),
      email: fallbackEmail.trim(),
      badge: 'Local Explorer',
      currentCity: 'Seoul',
      language: 'English',
    );
  }

  UserProfile _profileFromUser(Map<String, Object?> user) {
    final metadata = user['user_metadata'];
    final metadataMap = metadata is Map
        ? Map<String, Object?>.from(metadata)
        : const <String, Object?>{};
    final email = _string(user['email']) ?? '';

    return UserProfile(
      id: _string(user['id']) ?? '',
      displayName:
          _string(metadataMap['display_name']) ?? _displayNameFromEmail(email),
      email: email,
      badge: 'Local Explorer',
      currentCity: 'Seoul',
      language: 'English',
    );
  }

  Uri _authUri(String path, {Map<String, String>? query}) {
    final base = config.url.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/auth/v1/$path').replace(queryParameters: query);
  }

  void _ensureConfigured() {
    if (!config.isConfigured) {
      throw const AuthRepositoryException(
        'Supabase URL and anon key are not configured.',
      );
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _errorMessage(http.Response response) {
    final decoded = _tryDecodeMap(response.body);
    final message =
        _string(decoded?['msg']) ??
        _string(decoded?['message']) ??
        _string(decoded?['error_description']) ??
        _string(decoded?['error']);
    return message ??
        'Supabase Auth failed with status ${response.statusCode}.';
  }

  Map<String, Object?> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
    throw const AuthRepositoryException('Supabase Auth returned invalid JSON.');
  }

  Map<String, Object?>? _tryDecodeMap(String body) {
    try {
      return _decodeMap(body);
    } catch (_) {
      return null;
    }
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.trim().split('@').first;
    return localPart.isEmpty ? 'Traveler' : localPart;
  }

  String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
