import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/location/current_location_service.dart';
import 'package:norigo/features/onboarding/application/user_consent_store.dart';
import 'package:norigo/features/onboarding/data/user_consent_repository.dart';
import 'package:norigo/features/onboarding/domain/user_consent.dart';
import 'package:norigo/features/onboarding/presentation/data_location_consent_screen.dart';
import 'package:norigo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserConsentStore.resetForTesting();
  });

  testWidgets('consent screen stores data_consent', (tester) async {
    final repository = _FakeConsentRepository();
    await tester.pumpWidget(
      _LocalizedApp(
        child: DataLocationConsentScreen(
          repository: repository,
          locationService: _FakeLocationService(),
          onComplete: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('agreeDataConsentButton')));
    await tester.pumpAndSettle();

    expect(UserConsentStore.current.dataConsent, isTrue);
    expect(repository.saved.last.dataConsent, isTrue);
    expect(find.text('Consent saved.'), findsOneWidget);
  });

  testWidgets('location permission is requested only after allow tap', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      result: CurrentLocationResult(
        location: CurrentLocation(
          latitude: 37.5563,
          longitude: 126.9236,
          updatedAt: DateTime.utc(2026, 6, 4),
        ),
        permissionStatus: 'granted',
      ),
    );
    await tester.pumpWidget(
      _LocalizedApp(
        child: DataLocationConsentScreen(
          repository: _FakeConsentRepository(),
          locationService: locationService,
          onComplete: () {},
        ),
      ),
    );

    expect(locationService.requestCount, 0);

    await tester.tap(find.byKey(const ValueKey('skipDataConsentButton')));
    await tester.pumpAndSettle();
    expect(locationService.requestCount, 0);

    await tester.tap(find.byKey(const ValueKey('allowLocationButton')));
    await tester.pumpAndSettle();

    expect(locationService.requestCount, 1);
    expect(UserConsentStore.current.locationConsent, isTrue);
    expect(UserConsentStore.current.latestLocation?.latitude, 37.5563);
  });

  testWidgets('denied location stores fallback status without crashing', (
    tester,
  ) async {
    final repository = _FakeConsentRepository();
    await tester.pumpWidget(
      _LocalizedApp(
        child: DataLocationConsentScreen(
          repository: repository,
          locationService: _FakeLocationService(
            result: const CurrentLocationResult(
              error: CurrentLocationError.permissionDenied,
              permissionStatus: 'denied',
            ),
          ),
          onComplete: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('allowLocationButton')));
    await tester.pumpAndSettle();

    expect(UserConsentStore.current.locationConsent, isFalse);
    expect(UserConsentStore.current.locationPermissionStatus, 'denied');
    expect(repository.saved.last.locationPermissionStatus, 'denied');
    expect(find.textContaining('Using base location instead'), findsOneWidget);
  });
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _FakeConsentRepository extends UserConsentRepository {
  final saved = <UserConsent>[];

  @override
  Future<UserConsentSaveResult> saveConsent(UserConsent consent) async {
    saved.add(consent);
    return const UserConsentSaveResult(saved: true, localOnly: false);
  }
}

class _FakeLocationService extends CurrentLocationService {
  _FakeLocationService({
    this.result = const CurrentLocationResult(
      error: CurrentLocationError.permissionDenied,
      permissionStatus: 'denied',
    ),
  });

  final CurrentLocationResult result;
  var requestCount = 0;

  @override
  Future<CurrentLocationResult> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    if (requestPermission) requestCount += 1;
    return result;
  }
}
