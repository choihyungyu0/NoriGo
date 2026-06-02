import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'culture scan vision migration creates private storage and metadata',
    () {
      final file = File(
        'supabase/migrations/202606030004_culture_scan_vision_storage.sql',
      );

      expect(file.existsSync(), isTrue);
      final sql = file.readAsStringSync();

      expect(sql, contains("values ('culture-scans', 'culture-scans', false)"));
      expect(sql, contains('Users can upload their culture scan images'));
      expect(sql, contains('Users can read their culture scan images'));
      expect(sql, contains("bucket_id = 'culture-scans'"));
      expect(sql, contains("auth.uid()::text = (storage.foldername(name))[1]"));
      expect(sql, contains('add column if not exists image_path text'));
      expect(
        sql,
        contains("detected_object_source text not null default 'manual'"),
      );
      expect(
        sql,
        contains('add column if not exists vision_confidence double precision'),
      );
      expect(
        sql,
        contains('add column if not exists vision_alternatives jsonb'),
      );
    },
  );
}
