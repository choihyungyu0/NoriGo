import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:norigo/features/crowd/domain/seoul_realtime_risk.dart';

abstract interface class SeoulRealtimeRiskRepository {
  Future<SeoulRealtimeRisk> checkRisk(SeoulRealtimeRiskRequest request);
}

class SupabaseSeoulRealtimeRiskRepository
    implements SeoulRealtimeRiskRepository {
  const SupabaseSeoulRealtimeRiskRepository({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<SeoulRealtimeRisk> checkRisk(SeoulRealtimeRiskRequest request) async {
    if (!config.isConfigured) {
      return await _snapshotFallback(request) ??
          SeoulRealtimeRisk.unavailable(
            scheduledPlaceName: request.scheduledPlaceName,
            reason: 'Supabase is not configured.',
          );
    }

    try {
      final response = await _post(
        request,
      ).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return await _snapshotFallback(request) ??
            SeoulRealtimeRisk.unavailable(
              scheduledPlaceName: request.scheduledPlaceName,
              reason:
                  'Seoul real-time risk function failed with status ${response.statusCode}.',
            );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        final risk = SeoulRealtimeRisk.fromJson(decoded);
        if (risk.isUnavailable || risk.isUnmatched) {
          return await _snapshotFallback(request) ?? risk;
        }
        return risk;
      }
      if (decoded is Map) {
        final risk = SeoulRealtimeRisk.fromJson(
          Map<String, Object?>.from(decoded),
        );
        if (risk.isUnavailable || risk.isUnmatched) {
          return await _snapshotFallback(request) ?? risk;
        }
        return risk;
      }
    } catch (_) {
      return await _snapshotFallback(request) ??
          SeoulRealtimeRisk.unavailable(
            scheduledPlaceName: request.scheduledPlaceName,
          );
    }

    return await _snapshotFallback(request) ??
        SeoulRealtimeRisk.unavailable(
          scheduledPlaceName: request.scheduledPlaceName,
          reason: 'Seoul real-time risk function returned invalid JSON.',
        );
  }

  Future<http.Response> _post(SeoulRealtimeRiskRequest request) {
    final uri = Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/functions/v1/seoul-realtime-risk',
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
    if (client != null) {
      return client.post(uri, headers: headers, body: body);
    }
    return http.post(uri, headers: headers, body: body);
  }

  Future<SeoulRealtimeRisk?> _snapshotFallback(
    SeoulRealtimeRiskRequest request,
  ) {
    return _SeoulDangerSnapshotStore.matchRisk(request);
  }
}

class _SeoulDangerSnapshotStore {
  const _SeoulDangerSnapshotStore._();

  static const _csvAsset = 'assets/data/seoul_danger_result.csv';
  static Future<List<_SeoulDangerSnapshot>>? _snapshotsFuture;

  static Future<SeoulRealtimeRisk?> matchRisk(
    SeoulRealtimeRiskRequest request,
  ) async {
    final snapshots = await _loadSnapshots();
    if (snapshots.isEmpty) return null;

    final byName = _matchByName(request, snapshots);
    final snapshot = byName ?? _matchByCoordinates(request, snapshots);
    if (snapshot == null) return null;
    return snapshot.toRisk(request);
  }

  static Future<List<_SeoulDangerSnapshot>> _loadSnapshots() {
    return _snapshotsFuture ??= _readSnapshots();
  }

  static Future<List<_SeoulDangerSnapshot>> _readSnapshots() async {
    try {
      final csv = await rootBundle.loadString(_csvAsset);
      return _parseCsv(csv)
          .skip(1)
          .map(_SeoulDangerSnapshot.fromRow)
          .whereType<_SeoulDangerSnapshot>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static _SeoulDangerSnapshot? _matchByName(
    SeoulRealtimeRiskRequest request,
    List<_SeoulDangerSnapshot> snapshots,
  ) {
    final names = [
      request.currentPlaceName,
      request.scheduledPlaceName,
    ].whereType<String>().where((name) => name.trim().isNotEmpty).toList();

    for (final name in names) {
      final normalized = _normalize(name);
      for (final snapshot in snapshots) {
        final aliases = snapshot.aliases.map(_normalize);
        if (aliases.any((alias) => alias == normalized)) return snapshot;
      }
    }

    for (final name in names) {
      final normalized = _normalize(name);
      for (final snapshot in snapshots) {
        final aliases = snapshot.aliases.map(_normalize);
        if (aliases.any(
          (alias) =>
              alias.isNotEmpty &&
              (normalized.contains(alias) || alias.contains(normalized)),
        )) {
          return snapshot;
        }
      }
    }

    return null;
  }

  static _SeoulDangerSnapshot? _matchByCoordinates(
    SeoulRealtimeRiskRequest request,
    List<_SeoulDangerSnapshot> snapshots,
  ) {
    final lat = request.currentLat;
    final lng = request.currentLng;
    if (lat == null || lng == null) return null;

    _SeoulDangerSnapshot? nearest;
    var nearestKm = double.infinity;
    for (final snapshot in snapshots) {
      final distance = _haversineKm(
        lat,
        lng,
        snapshot.latitude,
        snapshot.longitude,
      );
      if (distance < nearestKm) {
        nearestKm = distance;
        nearest = snapshot;
      }
    }
    return nearestKm <= 2.0 ? nearest : null;
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < input.length; index += 1) {
      final char = input[index];
      if (inQuotes) {
        if (char == '"') {
          final nextIsQuote =
              index + 1 < input.length && input[index + 1] == '"';
          if (nextIsQuote) {
            cell.write('"');
            index += 1;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else if (char != '\r') {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }
}

class _SeoulDangerSnapshot {
  const _SeoulDangerSnapshot({
    required this.checkTime,
    required this.areaCode,
    required this.areaName,
    required this.latitude,
    required this.longitude,
    required this.riskScore,
    required this.riskLevel,
    required this.congestionLevel,
    required this.accidentCount,
    required this.accidentInfo,
  });

  final String checkTime;
  final String areaCode;
  final String areaName;
  final double latitude;
  final double longitude;
  final int riskScore;
  final String riskLevel;
  final String congestionLevel;
  final int accidentCount;
  final String accidentInfo;

  List<String> get aliases => [
    areaName,
    areaName.replaceAll(' 관광특구', ''),
    ..._englishAliasesFor(areaName),
  ];

  static _SeoulDangerSnapshot? fromRow(List<String> row) {
    if (row.length < 10) return null;
    final latitude = double.tryParse(row[3].trim());
    final longitude = double.tryParse(row[4].trim());
    final riskScore = int.tryParse(row[5].trim());
    if (latitude == null || longitude == null || riskScore == null) {
      return null;
    }
    return _SeoulDangerSnapshot(
      checkTime: row[0].trim(),
      areaCode: row[1].trim(),
      areaName: row[2].trim(),
      latitude: latitude,
      longitude: longitude,
      riskScore: riskScore,
      riskLevel: row[6].trim(),
      congestionLevel: row[7].trim(),
      accidentCount: int.tryParse(row[8].trim()) ?? 0,
      accidentInfo: row[9].trim(),
    );
  }

  SeoulRealtimeRisk toRisk(SeoulRealtimeRiskRequest request) {
    final incidentBonus = accidentCount > 0 ? 15 : 0;
    final normalizedScore = riskScore.clamp(0, 100).toInt();
    final level = _riskLevelFor(normalizedScore);
    final triggerType = _triggerTypeFor(normalizedScore);
    final hasIncident = accidentCount > 0 || accidentInfo.isNotEmpty;
    return SeoulRealtimeRisk(
      areaNm: areaName,
      matchedPlaceName: [request.currentPlaceName, request.scheduledPlaceName]
          .whereType<String>()
          .firstWhere((name) => name.trim().isNotEmpty, orElse: () => areaName),
      scheduledPlaceName: request.scheduledPlaceName ?? '',
      congestionLevel: congestionLevel,
      congestionMessage: '',
      populationMin: null,
      populationMax: null,
      populationTime: checkTime,
      crowdScore: normalizedScore,
      incidentBonus: incidentBonus,
      riskScore: normalizedScore,
      riskLevel: level,
      shouldAlert: normalizedScore >= 85,
      triggerType: triggerType,
      alertMessage: '$areaName is $level risk in the saved Seoul snapshot.',
      riskReason: hasIncident
          ? 'Saved Seoul risk snapshot from $checkTime. Accident/control data was present.'
          : 'Saved Seoul risk snapshot from $checkTime. This is not live crowd data.',
      sourceType: 'seoul_danger_snapshot',
      sourceBadge: 'Seoul Risk Snapshot',
    );
  }
}

List<String> _englishAliasesFor(String areaName) {
  final aliases = <String>[];
  void addIfContains(String keyword, List<String> values) {
    if (areaName.contains(keyword)) aliases.addAll(values);
  }

  addIfContains('강남', ['Gangnam', 'Gangnam Station', 'Gangnam MICE']);
  addIfContains('동대문', ['Dongdaemun', 'DDP']);
  addIfContains('명동', ['Myeongdong']);
  addIfContains('이태원', ['Itaewon']);
  addIfContains('잠실', ['Jamsil', 'Lotte World', 'Seokchon Lake']);
  addIfContains('종로', ['Jongno']);
  addIfContains('청계천', ['Cheonggyecheon']);
  addIfContains('홍대', ['Hongdae', 'Hongik University Street']);
  addIfContains('경복궁', ['Gyeongbokgung', 'Gyeongbokgung Palace']);
  addIfContains('광화문', ['Gwanghwamun', 'Gwanghwamun Plaza']);
  addIfContains('덕수궁', ['Deoksugung', 'Deoksu Palace']);
  addIfContains('광장', ['Gwangjang Market']);
  addIfContains('남산', ['Namsan', 'N Seoul Tower', 'Namsan Park']);
  addIfContains('북촌', ['Bukchon', 'Bukchon Hanok Village']);
  addIfContains('익선동', ['Ikseondong', 'Ikseon-dong']);
  addIfContains('성수', ['Seongsu', 'Seongsu Cafe Street']);
  addIfContains('여의도', ['Yeouido']);
  addIfContains('한강', ['Hangang', 'Han River']);
  return aliases;
}

String _riskLevelFor(int score) {
  if (score <= 39) return 'Low';
  if (score <= 64) return 'Moderate';
  if (score <= 84) return 'High';
  return 'Very High';
}

String _triggerTypeFor(int score) {
  if (score >= 85) return 'crowd_spike';
  if (score >= 65) return 'crowd_watch';
  return 'none';
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r"[\s._'’`·()-]+"), '').trim();
}

double _haversineKm(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  const earthRadiusKm = 6371;
  final dLat = _radians(toLat - fromLat);
  final dLng = _radians(toLng - fromLng);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(fromLat)) *
          math.cos(_radians(toLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double value) => value * math.pi / 180;
