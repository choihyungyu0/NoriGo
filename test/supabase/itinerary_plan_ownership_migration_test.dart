import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('itinerary plan ownership migration adds user_id and RLS policies', () {
    final file = File(
      'supabase/migrations/202606030001_itinerary_plan_ownership.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('add column if not exists user_id uuid'));
    expect(sql, contains('itinerary_plans_user_id_idx'));
    expect(sql, contains('itinerary_plans_user_created_idx'));
    expect(
      sql,
      contains('alter table public.itinerary_plans enable row level security'),
    );
    expect(sql, contains('auth.uid() is not null and auth.uid() = user_id'));
    expect(sql, contains('on delete cascade'));
    expect(sql, contains('not valid'));
  });

  test('itinerary plan persistence migration keeps app columns available', () {
    final file = File(
      'supabase/migrations/202606030002_itinerary_plan_persistence_columns.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('add column if not exists title text'));
    expect(sql, contains('add column if not exists date_label text'));
    expect(sql, contains('add column if not exists source_type text'));
    expect(sql, contains('add column if not exists source_badge text'));
    expect(sql, contains('add column if not exists raw_json jsonb'));
    expect(sql, contains('add column if not exists created_at timestamptz'));
    expect(sql, contains('add column if not exists updated_at timestamptz'));
  });

  test('itinerary item ownership policies allow current user persistence', () {
    final file = File(
      'supabase/migrations/202606030003_itinerary_item_ownership_policies.sql',
    );

    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(
      sql,
      contains('alter table public.itinerary_items enable row level security'),
    );
    expect(
      sql,
      contains('Authenticated users can read their own itinerary items'),
    );
    expect(
      sql,
      contains('Authenticated users can insert their own itinerary items'),
    );
    expect(
      sql,
      contains('Authenticated users can update their own itinerary items'),
    );
    expect(sql, contains('auth.uid() is not null and auth.uid() = user_id'));
  });
}
