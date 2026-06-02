import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

class SupabaseCultureScanRepository extends CultureScanRepository {
  const SupabaseCultureScanRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    if (!config.isConfigured) {
      return CultureGuideResult.localDemo(request);
    }

    final response = await _post(request).timeout(
      const Duration(seconds: 24),
      onTimeout: () => throw const CultureScanRepositoryException(
        'Culture Guide Edge Function timed out.',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CultureScanRepositoryException(
        'Culture Guide Edge Function failed with status '
        '${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, Object?>) {
      return CultureGuideResult.fromJson(decoded);
    }
    if (decoded is Map) {
      return CultureGuideResult.fromJson(Map<String, Object?>.from(decoded));
    }
    throw const CultureScanRepositoryException(
      'Culture Guide response was not a JSON object.',
    );
  }

  Future<http.Response> _post(CultureScanRequest request) {
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}'
      '/functions/v1/ennoia-culture-guide',
    );
    final authorizationToken =
        SupabaseAuthSession.accessToken ?? config.anonKey;
    final headers = {
      'Authorization': 'Bearer $authorizationToken',
      'apikey': config.anonKey,
      'Content-Type': 'application/json; charset=utf-8',
    };
    final body = jsonEncode(request.toJson());

    final client = _client;
    if (client != null) return client.post(uri, headers: headers, body: body);
    return http.post(uri, headers: headers, body: body);
  }
}
