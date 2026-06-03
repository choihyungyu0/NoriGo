import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:norigo/core/services/supabase_auth_session.dart';
import 'package:norigo/core/services/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalePreferenceSync {
  const LocalePreferenceSync();

  Future<void> syncPreferredLanguage(String userLanguage);
}

class SupabaseLocalePreferenceSync extends LocalePreferenceSync {
  const SupabaseLocalePreferenceSync({
    this.config = const SupabaseConfig(),
    http.Client? client,
  }) : _client = client;

  final SupabaseConfig config;
  final http.Client? _client;

  @override
  Future<void> syncPreferredLanguage(String userLanguage) async {
    if (!config.isConfigured) return;
    final token = SupabaseAuthSession.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final userId = SupabaseAuthSession.userId;
      final rowId = await _latestPreferenceId(userId);
      if (rowId == null) {
        await _insertPreference(userLanguage, userId);
        return;
      }
      await _patchPreference(rowId, userLanguage);
    } catch (_) {
      // Locale switching must keep working even when profile sync is unavailable.
    }
  }

  Future<String?> _latestPreferenceId(String? userId) async {
    var response = await _get(_latestPreferenceUri(userId));
    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _get(_latestPreferenceUri(null));
    }
    if (!_isSuccess(response.statusCode)) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final id = (decoded.first as Map)['id'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
      if (id is num) return id.toString();
    }
    return null;
  }

  Future<void> _patchPreference(String rowId, String userLanguage) async {
    final response = await _patch(
      _restUri('trip_preferences', {'id': 'eq.$rowId'}),
      {'preferred_language': userLanguage},
    );
    if (!_isSuccess(response.statusCode)) {
      throw const LocalePreferenceSyncException();
    }
  }

  Future<void> _insertPreference(String userLanguage, String? userId) async {
    final row = {'preferred_language': userLanguage, 'user_id': ?userId};
    var response = await _post(_restUri('trip_preferences'), row);
    if (userId != null && _isMissingColumn(response, 'user_id')) {
      response = await _post(_restUri('trip_preferences'), {
        'preferred_language': userLanguage,
      });
    }
    if (!_isSuccess(response.statusCode)) {
      throw const LocalePreferenceSyncException();
    }
  }

  Uri _latestPreferenceUri(String? userId) {
    return _restUri('trip_preferences', {
      'select': 'id',
      if (userId != null) 'user_id': 'eq.$userId',
      'order': 'created_at.desc',
      'limit': '1',
    });
  }

  Future<http.Response> _get(Uri uri) {
    final client = _client;
    if (client != null) return client.get(uri, headers: _headers());
    return http.get(uri, headers: _headers());
  }

  Future<http.Response> _patch(Uri uri, Map<String, Object?> body) {
    final headers = {..._headers(), 'Prefer': 'return=minimal'};
    final encoded = jsonEncode(body);
    final client = _client;
    if (client != null) {
      return client.patch(uri, headers: headers, body: encoded);
    }
    return http.patch(uri, headers: headers, body: encoded);
  }

  Future<http.Response> _post(Uri uri, Map<String, Object?> body) {
    final headers = {..._headers(), 'Prefer': 'return=minimal'};
    final encoded = jsonEncode(body);
    final client = _client;
    if (client != null) {
      return client.post(uri, headers: headers, body: encoded);
    }
    return http.post(uri, headers: headers, body: encoded);
  }

  Uri _restUri(String table, [Map<String, String>? query]) {
    return Uri.parse(
      '${config.url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/$table',
    ).replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    final authorizationToken =
        SupabaseAuthSession.accessToken ?? config.anonKey;
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer $authorizationToken',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  bool _isMissingColumn(http.Response response, String columnName) {
    if (response.statusCode < 400) return false;
    final body = response.body.toLowerCase();
    final column = columnName.toLowerCase();
    return body.contains(column) &&
        (body.contains('column') || body.contains('schema cache'));
  }
}

class LocalePreferenceSyncException implements Exception {
  const LocalePreferenceSyncException();
}

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    LocalePreferenceSync preferenceSync = const SupabaseLocalePreferenceSync(),
    SharedPreferences? preferences,
    Locale initialLocale = fallbackLocale,
  }) : _preferenceSync = preferenceSync,
       _preferences = preferences,
       _locale = _supportedLocaleFor(initialLocale) ?? fallbackLocale {
    _currentLocale = _locale;
    _currentUserLanguage = userLanguageForLocale(_locale);
  }

  static const fallbackLocale = Locale('en');
  static const supportedLocales = [Locale('en'), Locale('ko')];
  static const _localePreferenceKey = 'norigo.locale';

  static Locale _currentLocale = fallbackLocale;
  static String _currentUserLanguage = 'English';

  final LocalePreferenceSync _preferenceSync;
  SharedPreferences? _preferences;
  Locale _locale;

  Locale get locale => _locale;
  String get userLanguage => userLanguageForLocale(_locale);
  String get languageDisplayName => displayNameForLocale(_locale);

  static Locale get currentLocale => _currentLocale;
  static String get currentUserLanguage => _currentUserLanguage;

  Future<void> load({Locale? deviceLocale}) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_localePreferenceKey);
    final resolved =
        _supportedLocaleCode(savedCode) ??
        _supportedLocaleFor(
          deviceLocale ?? ui.PlatformDispatcher.instance.locale,
        ) ??
        fallbackLocale;
    _setLocale(resolved, notify: false);
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = _supportedLocaleFor(locale) ?? fallbackLocale;
    final changed = resolved.languageCode != _locale.languageCode;
    _setLocale(resolved, notify: changed);

    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(_localePreferenceKey, resolved.languageCode);
    await _preferenceSync.syncPreferredLanguage(userLanguage);
  }

  Future<void> setLocaleCode(String languageCode) {
    return setLocale(_supportedLocaleCode(languageCode) ?? fallbackLocale);
  }

  void _setLocale(Locale locale, {required bool notify}) {
    _locale = locale;
    _currentLocale = locale;
    _currentUserLanguage = userLanguageForLocale(locale);
    if (notify) notifyListeners();
  }

  static bool isSupported(Locale locale) {
    return _supportedLocaleFor(locale) != null;
  }

  static String userLanguageForLocale(Locale locale) {
    return locale.languageCode == 'ko' ? 'Korean' : 'English';
  }

  static String displayNameForLocale(Locale locale) {
    return locale.languageCode == 'ko' ? '한국어' : 'English';
  }

  static Locale localeForUserLanguage(String userLanguage) {
    final normalized = userLanguage.trim().toLowerCase();
    if (normalized == 'ko' ||
        normalized == 'kor' ||
        normalized == 'korean' ||
        normalized == '한국어') {
      return const Locale('ko');
    }
    return fallbackLocale;
  }

  static Locale? _supportedLocaleCode(String? languageCode) {
    if (languageCode == null) return null;
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _supportedLocaleFor(Locale(normalized));
  }

  static Locale? _supportedLocaleFor(Locale locale) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return null;
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static final AppLocaleController _fallbackController = AppLocaleController();

  AppLocaleController get controller => notifier!;

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    return scope?.controller ?? _fallbackController;
  }

  static AppLocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLocaleScope>()
        ?.controller;
  }
}
