import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';

class SupabaseEnnoiaAgentRepository implements EnnoiaAgentRepository {
  const SupabaseEnnoiaAgentRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) async {
    final payload = await _invokeFunction(
      'ennoia-culture-guide',
      request.toJson(),
      listKey: 'items',
    );
    return CultureGuideResult.fromJson(payload);
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(
    ItineraryAgentRequest request,
  ) async {
    final payload = await _invokeFunction(
      'ennoia-itinerary',
      request.toJson(),
      listKey: 'items',
    );
    return ItineraryAgentResult.fromJson(payload);
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    final payload = await _invokeFunction(
      'ennoia-retrip',
      request.toJson(),
      listKey: 'alternatives',
    );
    return RetripAgentResult.fromJson(payload);
  }

  Future<Map<String, Object?>> _invokeFunction(
    String functionName,
    Map<String, Object?> body, {
    required String listKey,
  }) async {
    if (!config.isConfigured) {
      throw const EnnoiaAgentException('Supabase is not configured.');
    }

    _debugLogRequest(functionName, body);

    final response = await _post(functionName, body).timeout(
      const Duration(seconds: 24),
      onTimeout: () =>
          throw const EnnoiaAgentException('Supabase Edge Function timed out.'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EnnoiaAgentException(
        'Supabase Edge Function failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    final payload = _extractAgentPayload(decoded, listKey: listKey);
    _debugLogResponse(functionName, payload, listKey: listKey);
    return payload;
  }

  void _debugLogRequest(String functionName, Map<String, Object?> body) {
    if (!kDebugMode) return;

    if (functionName == 'ennoia-itinerary') {
      final safeLog = {
        'base_location': body['base_location'],
        'interests': body['interests'],
        'companion_type': body['companion_type'],
        'crowd_preference': body['crowd_preference'],
        'trip_days': body['trip_days'],
      };
      debugPrint('NoriGo itinerary request ${jsonEncode(safeLog)}');
      return;
    }

    if (functionName == 'ennoia-retrip') {
      final safeLog = {
        'original_place_name':
            body['original_place_name'] ?? body['original_place'],
        'trigger_type': body['trigger_type'],
      };
      debugPrint('NoriGo retrip request ${jsonEncode(safeLog)}');
    }
  }

  void _debugLogResponse(
    String functionName,
    Map<String, Object?> payload, {
    required String listKey,
  }) {
    if (!kDebugMode || functionName != 'ennoia-retrip') return;

    final alternatives = payload[listKey];
    final safeLog = {
      'source_type': payload['source_type'] ?? payload['sourceType'],
      'alternative_count': alternatives is List ? alternatives.length : 0,
    };
    debugPrint('NoriGo retrip response ${jsonEncode(safeLog)}');
  }

  Future<http.Response> _post(String functionName, Map<String, Object?> body) {
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/$functionName',
    );
    final authorizationToken =
        SupabaseAuthSession.accessToken ?? config.anonKey;
    final headers = {
      'Authorization': 'Bearer $authorizationToken',
      'apikey': config.anonKey,
      'Content-Type': 'application/json; charset=utf-8',
    };
    final encodedBody = jsonEncode(body);

    final client = _client;
    if (client != null) {
      return client.post(uri, headers: headers, body: encodedBody);
    }
    return http.post(uri, headers: headers, body: encodedBody);
  }

  Map<String, Object?> _extractAgentPayload(
    Object? decoded, {
    required String listKey,
  }) {
    final payload = _extractOpenAiContent(decoded) ?? decoded;
    final parsed = payload is String ? _parseContentString(payload) : payload;

    if (parsed is Map<String, Object?>) return parsed;
    if (parsed is Map) return Map<String, Object?>.from(parsed);
    if (parsed is List) return {listKey: parsed};

    throw const EnnoiaAgentException('ennoia response was not valid JSON.');
  }

  Object? _extractOpenAiContent(Object? decoded) {
    if (decoded is! Map) return null;
    if (decoded['output_text'] is String) return decoded['output_text'];
    if (decoded['content'] is String) return decoded['content'];
    if (decoded['content'] is Map) return decoded['content'];
    if (decoded['data'] is Map || decoded['data'] is List) {
      return decoded['data'];
    }
    final message = decoded['message'];
    if (message is Map) {
      final content = message['content'];
      if (content is String) return content;
      if (content is List) return _textFromContentParts(content);
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final firstChoice = choices.first;
    if (firstChoice is! Map) return null;

    final choiceMessage = firstChoice['message'];
    if (choiceMessage is Map) {
      final content = choiceMessage['content'];
      if (content is String) return content;
      if (content is List) return _textFromContentParts(content);
    }
    if (firstChoice['text'] is String) return firstChoice['text'];
    return null;
  }

  String _textFromContentParts(List<Object?> parts) {
    return parts
        .map((part) {
          if (part is String) return part;
          if (part is Map && part['text'] is String) return part['text'];
          if (part is Map && part['content'] is String) return part['content'];
          return '';
        })
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  Object? _parseContentString(String content) {
    final trimmed = _stripMarkdownFence(content.trim());
    if (trimmed.isEmpty) {
      throw const EnnoiaAgentException('ennoia returned empty content.');
    }

    try {
      return jsonDecode(trimmed);
    } on FormatException {
      final jsonLike = _extractJsonLikeText(trimmed);
      if (jsonLike == null) rethrow;
      return jsonDecode(jsonLike);
    }
  }

  String _stripMarkdownFence(String content) {
    return content
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String? _extractJsonLikeText(String content) {
    final objectStart = content.indexOf('{');
    final objectEnd = content.lastIndexOf('}');
    final arrayStart = content.indexOf('[');
    final arrayEnd = content.lastIndexOf(']');

    final hasObject = objectStart != -1 && objectEnd > objectStart;
    final hasArray = arrayStart != -1 && arrayEnd > arrayStart;

    if (hasObject && (!hasArray || objectStart < arrayStart)) {
      return content.substring(objectStart, objectEnd + 1);
    }
    if (hasArray) {
      return content.substring(arrayStart, arrayEnd + 1);
    }
    return null;
  }
}

class EnnoiaAgentException implements Exception {
  const EnnoiaAgentException(this.message);

  final String message;

  @override
  String toString() => 'EnnoiaAgentException: $message';
}
