import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/onboarding/domain/user_consent.dart';

abstract class UserConsentRepository {
  const UserConsentRepository();

  Future<UserConsentSaveResult> saveConsent(UserConsent consent);
}

class UserConsentSaveResult {
  const UserConsentSaveResult({
    required this.saved,
    required this.localOnly,
    this.message,
  });

  final bool saved;
  final bool localOnly;
  final String? message;
}

class SupabaseUserConsentRepository extends UserConsentRepository {
  const SupabaseUserConsentRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<UserConsentSaveResult> saveConsent(UserConsent consent) async {
    final userId = SupabaseAuthSession.userId;
    if (!config.isConfigured || userId == null) {
      return const UserConsentSaveResult(saved: true, localOnly: true);
    }

    try {
      final response = await _post(
        Uri.parse('${_baseUrl()}/rest/v1/user_consents?on_conflict=user_id'),
        consent.toSupabaseJson(userId),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const UserConsentSaveResult(saved: true, localOnly: false);
      }
      return const UserConsentSaveResult(
        saved: true,
        localOnly: true,
        message:
            'Consent saved locally. Cloud sync is not available right now.',
      );
    } catch (_) {
      return const UserConsentSaveResult(
        saved: true,
        localOnly: true,
        message:
            'Consent saved locally. Cloud sync is not available right now.',
      );
    }
  }

  Future<http.Response> _post(Uri uri, Object body) {
    final client = _client;
    final encoded = jsonEncode(body);
    final headers = {
      ..._headers(),
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    };
    if (client != null) {
      return client.post(uri, headers: headers, body: encoded);
    }
    return http.post(uri, headers: headers, body: encoded);
  }

  Map<String, String> _headers() {
    final authToken = SupabaseAuthSession.accessToken ?? config.anonKey;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  String _baseUrl() => config.url.replaceAll(RegExp(r'/+$'), '');
}
