import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'user consents migration creates consent table and own-row policies',
    () {
      final sql = File(
        'supabase/migrations/202606040003_user_consents.sql',
      ).readAsStringSync();

      expect(sql, contains('create table if not exists public.user_consents'));
      expect(sql, contains('data_consent boolean'));
      expect(sql, contains('location_consent boolean'));
      expect(sql, contains('location_permission_status text'));
      expect(
        sql,
        contains("consent_version text not null default '2026-06-03'"),
      );
      expect(sql, contains('raw_json jsonb'));
      expect(
        sql,
        contains('alter table public.user_consents enable row level security'),
      );
      expect(sql, contains('user_consents_select_own'));
      expect(sql, contains('user_consents_insert_own'));
      expect(sql, contains('user_consents_update_own'));
    },
  );
}
