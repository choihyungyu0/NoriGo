import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
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
    'repository returns local demo fallback when Supabase is not configured',
    () async {
      final result = await const SupabaseCultureScanRepository(
        config: SupabaseConfig(),
      ).runCultureGuide(CultureScanRequest.defaultTemple());

      expect(result.sourceType, 'culture_fallback');
      expect(result.sourceBadge, 'Demo fallback');
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
}

http.Response _json(Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'Content-Type': 'application/json; charset=utf-8'},
  );
}
