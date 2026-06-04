import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';

class DemoAuthService {
  const DemoAuthService({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  static bool _initialized = false;

  static Future<bool> initializeIfConfigured({
    SupabaseConfig config = const SupabaseConfig(),
  }) async {
    if (!config.isConfigured) return false;
    if (_initialized) return true;

    _initialized = true;
    return true;
  }

  Future<bool> ensureDemoSession() async {
    if (!config.isConfigured) return false;
    if (SupabaseAuthSession.accessToken != null) return true;

    final initialized = await initializeIfConfigured(config: config);
    if (!initialized) return false;

    try {
      final response = await _postAnonymousSignIn().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SupabaseAuthSession.accessToken != null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final accessToken = decoded['access_token'];
        if (accessToken is String && accessToken.trim().isNotEmpty) {
          SupabaseAuthSession.updateAccessToken(accessToken);
        }
      }
    } catch (_) {
      return SupabaseAuthSession.accessToken != null;
    }

    return SupabaseAuthSession.accessToken != null;
  }

  Future<http.Response> _postAnonymousSignIn() {
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/auth/v1/signup',
    );
    final headers = {
      'apikey': config.anonKey,
      'Authorization': 'Bearer ${config.anonKey}',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final body = jsonEncode({
      'data': {'source': 'norigo_demo'},
    });
    final client = _client;
    return client?.post(uri, headers: headers, body: body) ??
        http.post(uri, headers: headers, body: body);
  }
}
