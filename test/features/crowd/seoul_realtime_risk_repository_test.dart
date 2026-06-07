import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/crowd/application/seoul_realtime_risk_controller.dart';
import 'package:norigo/features/crowd/data/seoul_realtime_risk_repository.dart';
import 'package:norigo/features/crowd/domain/seoul_realtime_risk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Supabase API failure falls back to Seoul risk snapshot', () async {
    final repository = SupabaseSeoulRealtimeRiskRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return http.Response('server unavailable', 500);
      }),
    );

    final risk = await repository.checkRisk(
      const SeoulRealtimeRiskRequest(
        scheduledPlaceName: 'Myeongdong',
        scheduledTime: '14:00',
      ),
    );

    expect(risk.sourceType, 'seoul_danger_snapshot');
    expect(risk.sourceBadge, 'Seoul Risk Snapshot');
    expect(risk.areaNm, '명동 관광특구');
    expect(risk.riskScore, 25);
    expect(risk.shouldAlert, isFalse);
  });

  test(
    'unconfigured Supabase uses Seoul risk snapshot when place matches',
    () async {
      const repository = SupabaseSeoulRealtimeRiskRepository();

      final risk = await repository.checkRisk(
        const SeoulRealtimeRiskRequest(
          scheduledPlaceName: '잠실 관광특구',
          scheduledTime: '18:00',
        ),
      );

      expect(risk.sourceType, 'seoul_danger_snapshot');
      expect(risk.areaNm, '잠실 관광특구');
      expect(risk.riskScore, 100);
      expect(risk.shouldAlert, isTrue);
    },
  );

  test('controller throttles and returns cached repeated checks', () async {
    var calls = 0;
    var now = DateTime(2026, 6, 3, 14);
    final controller = SeoulRealtimeRiskController(
      repository: _CountingRiskRepository(() {
        calls += 1;
        return _risk(riskScore: calls == 1 ? 70 : 85);
      }),
      now: () => now,
    );
    addTearDown(controller.dispose);

    const request = SeoulRealtimeRiskRequest(
      scheduledPlaceName: 'Bukchon Hanok Village',
      scheduledTime: '14:00',
    );

    final first = await controller.checkRisk(request);
    now = now.add(const Duration(minutes: 2));
    final second = await controller.checkRisk(request);
    now = now.add(const Duration(minutes: 2));
    final third = await controller.checkRisk(request);

    expect(first.riskScore, 70);
    expect(second.riskScore, 70);
    expect(third.riskScore, 85);
    expect(calls, 2);
  });

  test('successful response parses Seoul real-time fields', () async {
    final repository = SupabaseSeoulRealtimeRiskRepository(
      config: const SupabaseConfig(
        url: 'https://project.supabase.co',
        anonKey: 'anon-key',
      ),
      client: MockClient((request) async {
        return http.Response(
          jsonEncode(_risk(riskScore: 85).toJson()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final risk = await repository.checkRisk(
      const SeoulRealtimeRiskRequest(
        scheduledPlaceName: 'Bukchon Hanok Village',
        scheduledTime: '14:00',
      ),
    );

    expect(risk.sourceType, 'seoul_realtime_citydata');
    expect(risk.sourceBadge, 'Seoul Real-time');
    expect(risk.shouldAlert, isTrue);
  });
}

SeoulRealtimeRisk _risk({required int riskScore}) {
  return SeoulRealtimeRisk.fromJson({
    'area_nm': '북촌한옥마을',
    'matched_place_name': 'Bukchon Hanok Village',
    'scheduled_place_name': 'Bukchon Hanok Village',
    'congestion_level': riskScore >= 85 ? '붐빔' : '약간 붐빔',
    'congestion_message': 'Busy nearby.',
    'population_min': 1000,
    'population_max': 2000,
    'population_time': '2026-06-03 14:00',
    'crowd_score': riskScore,
    'incident_bonus': 0,
    'risk_score': riskScore,
    'risk_level': riskScore >= 85 ? 'Very High' : 'High',
    'should_alert': riskScore >= 85,
    'trigger_type': riskScore >= 85 ? 'crowd_spike' : 'crowd_watch',
    'alert_message': 'Bukchon is busy.',
    'risk_reason': 'No incident data was used.',
    'source_type': 'seoul_realtime_citydata',
    'source_badge': 'Seoul Real-time',
  });
}

extension on SeoulRealtimeRisk {
  Map<String, Object?> toJson() {
    return {
      'area_nm': areaNm,
      'matched_place_name': matchedPlaceName,
      'scheduled_place_name': scheduledPlaceName,
      'congestion_level': congestionLevel,
      'congestion_message': congestionMessage,
      'population_min': populationMin,
      'population_max': populationMax,
      'population_time': populationTime,
      'crowd_score': crowdScore,
      'incident_bonus': incidentBonus,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'should_alert': shouldAlert,
      'trigger_type': triggerType,
      'alert_message': alertMessage,
      'risk_reason': riskReason,
      'source_type': sourceType,
      'source_badge': sourceBadge,
    };
  }
}

class _CountingRiskRepository implements SeoulRealtimeRiskRepository {
  const _CountingRiskRepository(this.nextRisk);

  final SeoulRealtimeRisk Function() nextRisk;

  @override
  Future<SeoulRealtimeRisk> checkRisk(SeoulRealtimeRiskRequest request) async {
    return nextRisk();
  }
}
