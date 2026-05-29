import 'package:norigo/core/services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DemoAuthService {
  const DemoAuthService({
    this.config = const SupabaseConfig(),
    SupabaseClient? client,
  }) : _client = client;

  final SupabaseConfig config;
  final SupabaseClient? _client;

  static bool _initialized = false;

  static Future<bool> initializeIfConfigured({
    SupabaseConfig config = const SupabaseConfig(),
  }) async {
    if (!config.isConfigured) return false;
    if (_initialized) return true;

    try {
      await Supabase.initialize(url: config.url, anonKey: config.anonKey);
      _initialized = true;
      return true;
    } catch (_) {
      return _initialized;
    }
  }

  Future<bool> ensureDemoSession() async {
    if (!config.isConfigured) return false;

    final initialized = await initializeIfConfigured(config: config);
    if (!initialized && _client == null) return false;

    final client = _safeClient;
    if (client == null) return false;

    if (client.auth.currentSession != null) return true;

    try {
      await client.auth.signInAnonymously();
    } catch (_) {
      return client.auth.currentSession != null;
    }

    return client.auth.currentSession != null;
  }

  SupabaseClient? get _safeClient {
    final client = _client;
    if (client != null) return client;

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
