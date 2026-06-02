import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/data/supabase_culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';

void main() {
  tearDown(SupabaseAuthSession.clear);

  test('culture guide request serializes correctly', () {
    final request = CultureScanRequest.defaultTemple(
      userLanguage: 'English',
    ).copyWith(userQuestion: 'Why is this here?');

    expect(request.toJson(), {
      'user_language': 'English',
      'current_location': 'Bulguksa',
      'place_type': 'temple',
      'detected_object': 'temple_stone_stack',
      'korean_keyword': '소원 성취',
      'user_intent': 'Understand local culture and etiquette',
      'user_question': 'Why is this here?',
    });
  });

  test(
    'repository returns local guide when Supabase is not configured',
    () async {
      final result = await const SupabaseCultureScanRepository(
        config: SupabaseConfig(),
      ).runCultureGuide(CultureScanRequest.defaultTemple());

      expect(result.sourceType, 'culture_local');
      expect(result.sourceBadge, 'Local guide');
      expect(result.persisted, isFalse);
    },
  );

  test('DB/basic fallback returns source_type culture_db_basic', () async {
    final repository = SupabaseCultureScanRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return _json({
          'question': 'Is it polite to press the bell?',
          'description': 'Use the bell once.',
          'meaning': 'Call bells request service calmly.',
          'etiquette': 'Press once and wait.',
          'story': 'Common in Korean restaurants.',
          'korean_phrase': '여기요',
          'pronunciation': 'yeo-gi-yo',
          'phrase_meaning': 'Excuse me.',
          'source_type': 'culture_db_basic',
          'source_badge': 'Culture DB',
          'ennoia_succeeded': false,
          'persisted': true,
          'cultureScanRecordId': 'scan-1',
        });
      }),
    );

    final result = await repository.runCultureGuide(
      CultureScanRequest.defaultTemple().copyWith(
        placeType: 'restaurant',
        detectedObject: 'restaurant_call_bell',
      ),
    );

    expect(result.sourceType, 'culture_db_basic');
    expect(result.sourceBadge, 'Culture DB');
    expect(result.koreanPhrase, '여기요');
  });

  test('ennoia success returns source_type culture_db_ennoia', () async {
    final repository = SupabaseCultureScanRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return _json({
          'question': 'Why do people stack stones?',
          'description': 'A practical temple guide.',
          'meaning': 'Each stone carries a wish.',
          'etiquette': 'Do not touch existing stacks.',
          'story': 'A quiet temple tradition.',
          'korean_phrase': '소원 성취하세요',
          'pronunciation': 'so-won seong-chwi-ha-se-yo',
          'phrase_meaning': 'May your wish come true.',
          'source_type': 'culture_db_ennoia',
          'source_badge': 'Culture DB + ennoia',
          'ennoia_succeeded': true,
          'persisted': true,
          'cultureScanRecordId': 'scan-2',
        });
      }),
    );

    final result = await repository.runCultureGuide(
      CultureScanRequest.defaultTemple(),
    );

    expect(result.sourceType, 'culture_db_ennoia');
    expect(result.sourceBadge, 'Culture DB + ennoia');
    expect(result.ennoiaSucceeded, isTrue);
  });

  test('OpenAI-style ennoia response content is extracted', () async {
    final repository = SupabaseCultureScanRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return _json({
          'choices': [
            {
              'message': {
                'content': [
                  {
                    'type': 'text',
                    'text': jsonEncode({
                      'question': 'What should I do at this temple?',
                      'description': 'A practical guide for this moment.',
                      'meaning': 'Small stones can represent wishes.',
                      'etiquette': 'Look without touching existing stacks.',
                      'story': 'A quiet temple tradition.',
                      'korean_phrase': '소원 성취하세요',
                      'pronunciation': 'so-won seong-chwi-ha-se-yo',
                      'phrase_meaning': 'May your wish come true.',
                      'confidence': 0.85,
                    }),
                  },
                ],
              },
            },
          ],
        });
      }),
    );

    final result = await repository.runCultureGuide(
      CultureScanRequest.defaultTemple(),
    );

    expect(result.question, 'What should I do at this temple?');
    expect(result.sourceType, 'ennoia_direct');
    expect(result.sourceBadge, 'ennoia');
    expect(result.ennoiaSucceeded, isTrue);
    expect(result.locationName, 'Bulguksa');
  });

  test('scope-limited responses are mapped from the Edge Function', () async {
    final repository = SupabaseCultureScanRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return _json({
          'question': 'What is the political history?',
          'description': 'Travel behavior only.',
          'meaning': 'Outside scope.',
          'etiquette': 'Ask about immediate behavior.',
          'source_type': 'culture_scope_limited',
          'source_badge': 'Travel behavior only',
          'scope_limited': true,
        });
      }),
    );

    final result = await repository.runCultureGuide(
      CultureScanRequest.defaultTemple().copyWith(
        userQuestion: 'What is the political history?',
      ),
    );

    expect(result.scopeLimited, isTrue);
    expect(result.sourceType, 'culture_scope_limited');
    expect(result.sourceBadge, 'Travel behavior only');
  });

  test('scan image upload uses authenticated storage path', () async {
    SupabaseAuthSession.updateAccessToken(
      _jwt({'role': 'authenticated', 'sub': 'user-1'}),
    );
    final repository = SupabaseCultureScanRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          startsWith('/storage/v1/object/culture-scans/user-1/'),
        );
        expect(request.headers['apikey'], 'anon-key');
        expect(request.headers['Content-Type'], 'image/jpeg');
        expect(request.bodyBytes, [1, 2, 3]);
        return http.Response('{}', 200);
      }),
    );

    final imagePath = await repository.uploadScanImage(
      CultureImageCapture(
        bytes: utf8.encode('\u0001\u0002\u0003'),
        contentType: 'image/jpeg',
        extension: 'jpg',
      ),
    );

    expect(imagePath, startsWith('culture-scans/user-1/'));
    expect(imagePath, endsWith('.jpg'));
  });
}

http.Response _json(Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'Content-Type': 'application/json; charset=utf-8'},
  );
}

String _jwt(Map<String, Object?> payload) {
  String part(Object value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${part({'alg': 'none'})}.${part(payload)}.signature';
}
