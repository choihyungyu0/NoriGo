import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seoul realtime area migration creates mapping table and aliases', () {
    final sql = File(
      'supabase/migrations/202606030005_seoul_realtime_areas.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('create table if not exists public.seoul_realtime_areas'),
    );
    expect(sql, contains('area_nm text unique not null'));
    expect(sql, contains('aliases text[]'));
    expect(sql, contains('coord_confidence text'));
    expect(sql, contains('is_estimated boolean'));
    expect(sql, contains('Bukchon Hanok Village'));
    expect(sql, contains('Gyeongbokgung Palace'));
    expect(sql, contains('Gwangjang Market'));
    expect(sql, contains('Myeongdong'));
    expect(sql, contains('Hongdae'));
  });
}
