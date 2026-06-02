import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class SupabaseCultureScanRepository extends CultureScanRepository {
  const SupabaseCultureScanRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<String?> uploadScanImage(CultureImageCapture capture) async {
    if (!config.isConfigured || capture.isEmpty) return null;

    final accessToken = SupabaseAuthSession.accessToken;
    final userId = _userIdFromAccessToken(accessToken);
    if (accessToken == null || userId == null) return null;

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final objectPath = '$userId/$timestamp.${capture.extension}';
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}'
      '/storage/v1/object/culture-scans/$objectPath',
    );
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'apikey': config.anonKey,
      'Content-Type': capture.contentType,
      'Cache-Control': '3600',
    };

    final client = _client;
    final response = client != null
        ? await client.post(uri, headers: headers, body: capture.bytes)
        : await http.post(uri, headers: headers, body: capture.bytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return objectPath;
  }

  @override
  Future<CultureVisionResult> detectCultureObject(
    CultureVisionRequest request,
  ) async {
    if (!config.isConfigured) {
      return CultureVisionResult.heuristic(request);
    }

    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}'
      '/functions/v1/culture-vision-detect',
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
    final http.Response response;
    try {
      response =
          await (client != null
                  ? client.post(uri, headers: headers, body: body)
                  : http.post(uri, headers: headers, body: body))
              .timeout(const Duration(seconds: 18));
    } catch (_) {
      return CultureVisionResult.heuristic(request);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return CultureVisionResult.heuristic(request);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        return CultureVisionResult.fromJson(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      return CultureVisionResult.heuristic(request);
    }
    return CultureVisionResult.heuristic(request);
  }

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
    final payload = _extractCultureGuidePayload(decoded, request);
    if (payload != null) return CultureGuideResult.fromJson(payload);

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

  Map<String, Object?>? _extractCultureGuidePayload(
    Object? decoded,
    CultureScanRequest request,
  ) {
    final payload = _extractOpenAiContent(decoded) ?? decoded;
    final parsed = payload is String ? _parseContentString(payload) : payload;

    Map<String, Object?>? map;
    if (parsed is Map<String, Object?>) {
      map = parsed;
    } else if (parsed is Map) {
      map = Map<String, Object?>.from(parsed);
    }
    if (map == null) return null;

    final hasSource =
        _hasText(map['source_type']) ||
        _hasText(map['sourceType']) ||
        _hasText(map['source']);
    if (hasSource) return map;

    return {
      ...map,
      'source_type': 'ennoia_direct',
      'source_badge': 'ennoia',
      'ennoia_succeeded': true,
      'persisted': false,
      'location_name': request.currentLocation,
      'place_type': request.placeType,
      'detected_object': request.detectedObject,
      'korean_keyword': request.koreanKeyword,
    };
  }

  Object? _extractOpenAiContent(Object? decoded) {
    if (decoded is! Map) return null;
    if (decoded['output_text'] is String) return decoded['output_text'];
    if (decoded['content'] is String || decoded['content'] is Map) {
      return decoded['content'];
    }
    if (decoded['data'] is Map) return decoded['data'];

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
          if (part is Map && part['text'] is String) {
            return part['text'] as String;
          }
          if (part is Map && part['content'] is String) {
            return part['content'] as String;
          }
          return '';
        })
        .where((part) => part.trim().isNotEmpty)
        .join('\n');
  }

  Object? _parseContentString(String content) {
    final trimmed = _stripMarkdownFence(content.trim());
    if (trimmed.isEmpty) {
      throw const CultureScanRepositoryException(
        'Culture Guide returned empty content.',
      );
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
    if (objectStart == -1 || objectEnd <= objectStart) return null;
    return content.substring(objectStart, objectEnd + 1);
  }

  bool _hasText(Object? value) => value is String && value.trim().isNotEmpty;

  String? _userIdFromAccessToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final role = payload['role'];
      final subject = payload['sub'];
      if (role != 'authenticated') return null;
      if (subject is String && subject.trim().isNotEmpty) {
        return subject.trim();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
