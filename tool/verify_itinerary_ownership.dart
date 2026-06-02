import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/data/repositories/supabase_auth_repository.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/itinerary/data/supabase_itinerary_repository.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final anonKey = Platform.environment['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (url.isEmpty || anonKey.isEmpty) {
    throw StateError('Set SUPABASE_URL and SUPABASE_ANON_KEY.');
  }

  final config = SupabaseConfig(url: url, anonKey: anonKey);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final email =
      Platform.environment['NORIGO_TEST_EMAIL']?.trim().isNotEmpty == true
      ? Platform.environment['NORIGO_TEST_EMAIL']!.trim()
      : 'codex-itinerary-$timestamp@example.com';
  final password =
      Platform.environment['NORIGO_TEST_PASSWORD']?.trim().isNotEmpty == true
      ? Platform.environment['NORIGO_TEST_PASSWORD']!.trim()
      : 'NoriGo-$timestamp-Aa1!';

  final auth = SupabaseAuthRepository(config: config);
  stderr.writeln('step: sign up test user');
  await auth
      .signUpWithEmail(email: email, password: password)
      .timeout(const Duration(seconds: 30));
  if (SupabaseAuthSession.accessToken == null) {
    stderr.writeln('step: sign in test user');
    await auth
        .signInWithEmail(email: email, password: password)
        .timeout(const Duration(seconds: 30));
  }

  final token = SupabaseAuthSession.accessToken;
  final userId = SupabaseAuthSession.userId;
  if (token == null || userId == null) {
    throw StateError('Authenticated Supabase user session was not created.');
  }

  stderr.writeln('step: invoke ennoia-itinerary');
  final itineraryPayload = await _invokeItinerary(
    config,
    token,
  ).timeout(const Duration(seconds: 120));
  final result = ItineraryAgentResult.fromJson(itineraryPayload);
  stderr.writeln('step: save itinerary through app repository');
  final saved = await SupabaseItineraryRepository(
    config: config,
    client: _PreviewClient(),
  ).savePlan(result.toItineraryPlan()).timeout(const Duration(seconds: 30));
  final persistedPlanId = saved.persistedPlanId;
  if (persistedPlanId == null || persistedPlanId.isEmpty) {
    throw StateError('Itinerary plan was not persisted.');
  }

  stderr.writeln('step: read persisted plan row');
  final planRows = await _restList(config, token, 'itinerary_plans', {
    'select': 'id,user_id,source_type,source_badge,created_at',
    'id': 'eq.$persistedPlanId',
    'limit': '1',
  });
  if (planRows.isEmpty) {
    throw StateError('Persisted itinerary plan was not readable by user.');
  }
  final planRow = planRows.first;

  stderr.writeln('step: read persisted item rows');
  final itemRows = await _restList(config, token, 'itinerary_items', {
    'select': 'id,user_id,plan_id',
    'plan_id': 'eq.$persistedPlanId',
    'limit': '10',
  });

  final planUserId = planRow['user_id'];
  final sourceType = planRow['source_type'];
  final itemUserIdsMatch =
      itemRows.isNotEmpty && itemRows.every((row) => row['user_id'] == userId);

  stdout.writeln('testEmail: $email');
  stdout.writeln('userId: $userId');
  stdout.writeln('planId: $persistedPlanId');
  stdout.writeln('plan.user_id: $planUserId');
  stdout.writeln('plan.source_type: $sourceType');
  stdout.writeln('plan.source_badge: ${planRow['source_badge']}');
  stdout.writeln('itemCount: ${itemRows.length}');
  stdout.writeln('planUserIdMatches: ${planUserId == userId}');
  stdout.writeln('itemUserIdsMatch: $itemUserIdsMatch');

  if (planUserId != userId) {
    throw StateError('Persisted plan user_id did not match auth user.');
  }
  if (sourceType != 'kto_openapi_ennoia') {
    throw StateError('Persisted plan source_type was not kto_openapi_ennoia.');
  }
  if (!itemUserIdsMatch) {
    throw StateError(
      'Persisted itinerary item user_id did not match auth user.',
    );
  }
}

class _PreviewClient extends http.BaseClient {
  _PreviewClient() : _inner = http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode < 400) return response;

    final bytes = await response.stream.toBytes();
    final body = utf8.decode(bytes, allowMalformed: true);
    final preview = body.length > 800 ? '${body.substring(0, 800)}...' : body;
    stderr.writeln(
      'nonSuccessResponse: ${request.method} ${request.url.path} '
      '${response.statusCode} $preview',
    );

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

Future<Map<String, Object?>> _invokeItinerary(
  SupabaseConfig config,
  String token,
) async {
  final endpoint = Uri.parse(
    '${config.url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/ennoia-itinerary',
  );
  final response = await http.post(
    endpoint,
    headers: {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: jsonEncode(ItineraryAgentRequest.defaults().toJson()),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Itinerary function failed: ${response.statusCode}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is Map) return Map<String, Object?>.from(decoded);
  throw StateError('Itinerary function returned invalid JSON.');
}

Future<List<Map<String, Object?>>> _restList(
  SupabaseConfig config,
  String token,
  String table,
  Map<String, String> query,
) async {
  final uri = Uri.parse(
    '${config.url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/$table',
  ).replace(queryParameters: query);
  final response = await http.get(
    uri,
    headers: {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('REST query failed for $table: ${response.statusCode}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  }
  throw StateError('REST query returned invalid JSON for $table.');
}
