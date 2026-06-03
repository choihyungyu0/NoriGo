import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/crowd/domain/seoul_realtime_risk.dart';

abstract interface class SeoulRealtimeRiskRepository {
  Future<SeoulRealtimeRisk> checkRisk(SeoulRealtimeRiskRequest request);
}

class SupabaseSeoulRealtimeRiskRepository
    implements SeoulRealtimeRiskRepository {
  const SupabaseSeoulRealtimeRiskRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<SeoulRealtimeRisk> checkRisk(SeoulRealtimeRiskRequest request) async {
    if (!config.isConfigured) {
      return SeoulRealtimeRisk.unavailable(
        scheduledPlaceName: request.scheduledPlaceName,
        reason: 'Supabase is not configured.',
      );
    }

    try {
      final response = await _post(
        request,
      ).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SeoulRealtimeRisk.unavailable(
          scheduledPlaceName: request.scheduledPlaceName,
          reason:
              'Seoul real-time risk function failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        return SeoulRealtimeRisk.fromJson(decoded);
      }
      if (decoded is Map) {
        return SeoulRealtimeRisk.fromJson(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      return SeoulRealtimeRisk.unavailable(
        scheduledPlaceName: request.scheduledPlaceName,
      );
    }

    return SeoulRealtimeRisk.unavailable(
      scheduledPlaceName: request.scheduledPlaceName,
      reason: 'Seoul real-time risk function returned invalid JSON.',
    );
  }

  Future<http.Response> _post(SeoulRealtimeRiskRequest request) {
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/seoul-realtime-risk',
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
    if (client != null) {
      return client.post(uri, headers: headers, body: body);
    }
    return http.post(uri, headers: headers, body: body);
  }
}
