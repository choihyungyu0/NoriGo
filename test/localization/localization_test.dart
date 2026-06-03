import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/features/culture_scan/application/culture_camera_service.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';
import 'package:norigo/features/culture_scan/data/culture_scan_repository.dart';
import 'package:norigo/features/culture_scan/domain/culture_guide_result.dart';
import 'package:norigo/features/culture_scan/domain/culture_scan_request.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';
import 'package:norigo/features/ennoia/data/ennoia_agent_repository.dart';
import 'package:norigo/features/ennoia/domain/culture_guide_result.dart'
    as ennoia;
import 'package:norigo/features/ennoia/domain/itinerary_agent_result.dart';
import 'package:norigo/features/ennoia/domain/retrip_agent_result.dart';
import 'package:norigo/features/home/home_shell.dart';
import 'package:norigo/features/itinerary/application/crowd_alert_controller.dart';
import 'package:norigo/features/itinerary/application/itinerary_controller.dart';
import 'package:norigo/features/itinerary/application/itinerary_session_store.dart';
import 'package:norigo/features/itinerary/data/mock_crowd_alert_repository.dart';
import 'package:norigo/features/itinerary/data/mock_itinerary_repository.dart';
import 'package:norigo/features/itinerary/presentation/ai_itinerary_planner_screen.dart';
import 'package:norigo/features/itinerary/presentation/crowd_alert_screen.dart';
import 'package:norigo/features/my/data/my_page_repository.dart';
import 'package:norigo/features/my/domain/my_page_summary.dart';
import 'package:norigo/features/my/presentation/my_page_screen.dart';
import 'package:norigo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ItinerarySessionStore.resetForTesting();
  });

  test('app supports English and Korean locales', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('ko')));
  });

  test('locale selection persists locally', () async {
    final controller = AppLocaleController(
      preferenceSync: const _NoopLocalePreferenceSync(),
    );
    await controller.load(deviceLocale: const Locale('en'));
    await controller.setLocale(const Locale('ko'));

    final restored = AppLocaleController(
      preferenceSync: const _NoopLocalePreferenceSync(),
    );
    await restored.load(deviceLocale: const Locale('en'));

    expect(restored.locale, const Locale('ko'));
    expect(restored.userLanguage, 'Korean');
  });

  testWidgets('bottom nav labels switch language', (tester) async {
    final controller = _localeController(const Locale('en'));
    await tester.pumpWidget(
      _LocalizedHarness(controller: controller, child: const HomeShell()),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Itinerary'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('My'), findsOneWidget);

    await controller.setLocale(const Locale('ko'));
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('스캔'), findsOneWidget);
    expect(find.text('발견'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('My Page language bottom sheet switches locale', (tester) async {
    final controller = _localeController(const Locale('en'));
    await tester.pumpWidget(
      _LocalizedHarness(
        controller: controller,
        child: const MyPageScreen(
          repository: _StaticMyPageRepository(_summary),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Language & notifications'));
    await tester.tap(find.text('Language & notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.text('한국어'), findsOneWidget);

    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();

    expect(controller.locale, const Locale('ko'));
    expect(find.text('언어가 변경되었습니다.'), findsOneWidget);
  });

  testWidgets('major action buttons localize to Korean', (tester) async {
    final controller = _localeController(const Locale('ko'));

    await tester.pumpWidget(
      _LocalizedHarness(
        controller: controller,
        child: const AiItineraryPlannerScreen(
          repository: MockItineraryRepository(),
          autoGenerateOnOpen: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AI 일정 생성'), findsOneWidget);

    await tester.pumpWidget(
      _LocalizedHarness(
        controller: controller,
        child: CultureScanScreen(
          controller: CultureScanController(
            cameraService: const _UnavailableCameraService(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('문화 스캔'), findsOneWidget);

    await tester.pumpWidget(
      _LocalizedHarness(
        controller: controller,
        child: const CrowdAlertScreen(repository: MockCrowdAlertRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('혼잡 알림'), findsOneWidget);
    expect(find.text('Re-Trip 대안 생성'), findsOneWidget);
  });

  test(
    'selected locale is passed to itinerary, culture scan, and Re-Trip',
    () async {
      final controller = _localeController(const Locale('ko'));
      expect(controller.userLanguage, 'Korean');

      final ennoiaRepository = _CapturingEnnoiaRepository();
      final itineraryController = ItineraryController(
        repository: const MockItineraryRepository(),
        ennoiaRepository: ennoiaRepository,
        fallbackEnnoiaRepository: ennoiaRepository,
      );
      await itineraryController.generateWithEnnoia();
      expect(ennoiaRepository.itineraryRequest?.userLanguage, 'Korean');
      itineraryController.dispose();

      final cultureRepository = _CapturingCultureScanRepository();
      final cultureController = CultureScanController(
        cameraService: const _UnavailableCameraService(),
        repository: cultureRepository,
      );
      await cultureController.runCultureGuide(cultureController.defaultRequest);
      expect(cultureRepository.lastRequest?.userLanguage, 'Korean');
      cultureController.dispose();

      final crowdController = CrowdAlertController(
        repository: const MockCrowdAlertRepository(),
        ennoiaRepository: ennoiaRepository,
        fallbackEnnoiaRepository: ennoiaRepository,
      );
      await crowdController.generateRetripAlternatives();
      expect(ennoiaRepository.retripRequest?.userLanguage, 'Korean');
      crowdController.dispose();
    },
  );

  testWidgets('existing saved content displays as stored in Korean locale', (
    tester,
  ) async {
    final controller = _localeController(const Locale('ko'));
    await tester.pumpWidget(
      _LocalizedHarness(
        controller: controller,
        child: const MyPageScreen(
          repository: _StaticMyPageRepository(_summary),
          showBottomNavigation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('내 일정'));
    await tester.tap(find.text('내 일정'));
    await tester.pumpAndSettle();

    expect(find.text('Spring Seoul route'), findsOneWidget);
    expect(find.textContaining('Low-crowd route'), findsOneWidget);
  });
}

AppLocaleController _localeController(Locale locale) {
  return AppLocaleController(
    initialLocale: locale,
    preferenceSync: const _NoopLocalePreferenceSync(),
  );
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness({required this.controller, required this.child});

  final AppLocaleController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            theme: NoriGoTheme.light(),
            locale: controller.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          );
        },
      ),
    );
  }
}

class _NoopLocalePreferenceSync extends LocalePreferenceSync {
  const _NoopLocalePreferenceSync();

  @override
  Future<void> syncPreferredLanguage(String userLanguage) async {}
}

class _StaticMyPageRepository extends MyPageRepository {
  const _StaticMyPageRepository(this.summary);

  final MyPageSummary summary;

  @override
  Future<MyPageSummary> fetchSummary() async => summary;
}

class _CapturingEnnoiaRepository implements EnnoiaAgentRepository {
  ItineraryAgentRequest? itineraryRequest;
  RetripAgentRequest? retripRequest;

  @override
  Future<ennoia.CultureGuideResult> fetchCultureGuide(
    CultureGuideAgentRequest request,
  ) async {
    return ennoia.CultureGuideResult.mock();
  }

  @override
  Future<ItineraryAgentResult> fetchItinerary(
    ItineraryAgentRequest request,
  ) async {
    itineraryRequest = request;
    return ItineraryAgentResult.mock(sourceType: 'kto_openapi_ennoia');
  }

  @override
  Future<ItineraryAgentResult> generateItinerary(
    ItineraryAgentRequest request,
  ) {
    return fetchItinerary(request);
  }

  @override
  Future<RetripAgentResult> fetchRetrip(RetripAgentRequest request) async {
    retripRequest = request;
    return RetripAgentResult.mock(sourceType: 'kto_openapi_ennoia');
  }

  @override
  Future<void> saveCultureScanRecord(
    CultureGuideAgentRequest request,
    ennoia.CultureGuideResult result,
  ) async {}

  @override
  Future<void> saveItineraryPlan(
    ItineraryAgentRequest request,
    ItineraryAgentResult result,
  ) async {}

  @override
  Future<void> saveReTripEvent(
    RetripAgentRequest request,
    RetripAgentResult result,
  ) async {}
}

class _CapturingCultureScanRepository extends CultureScanRepository {
  CultureScanRequest? lastRequest;

  @override
  Future<CultureGuideResult> runCultureGuide(CultureScanRequest request) async {
    lastRequest = request;
    return CultureGuideResult.localDemo(request);
  }

  @override
  Future<String?> uploadScanImage(CultureImageCapture capture) async => null;

  @override
  Future<CultureVisionResult> detectCultureObject(
    CultureVisionRequest request,
  ) async {
    return CultureVisionResult.noMatch(request);
  }
}

class _UnavailableCameraService implements CultureCameraService {
  const _UnavailableCameraService();

  @override
  Future<CultureCameraSession> initialize() async {
    return const CultureCameraSession(
      unavailableMessage: 'No camera detected. Showing guide preview.',
    );
  }
}

const _summary = MyPageSummary(
  displayName: 'Mina Park',
  email: 'mina@example.com',
  avatarUrl: null,
  levelLabel: 'Local Explorer',
  level: 4,
  xp: 4250,
  xpTarget: 6000,
  locationLabel: 'Exploring Hongdae',
  languageLabel: 'English',
  savedPlansCount: 12,
  savedPlacesCount: 41,
  cultureScansCount: 9,
  timeSavedLabel: '7h',
  interests: ['Markets', 'Dessert'],
  foodNeeds: 'Vegetarian',
  latestPlanId: 'plan-1',
  localOnly: false,
  errorMessage: null,
  itineraries: [
    MyItineraryPlanPreview(
      id: 'plan-1',
      title: 'Spring Seoul route',
      createdAtLabel: '2026-06-02',
      sourceBadge: 'KTO OpenAPI',
      summary: 'Low-crowd route with markets and palace stops.',
      placeNames: ['Gyeongbokgung Palace', 'Mangwon Market'],
    ),
  ],
);
