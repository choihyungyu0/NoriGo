import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/core/localization/app_locale_controller.dart';
import 'package:norigo/features/onboarding/presentation/trip_basics_screen.dart';
import 'package:norigo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('TripBasicsScreen renders title, subtitle, and defaults', (
    tester,
  ) async {
    await _pumpTripBasics(tester);

    expect(find.text('Trip Basics'), findsOneWidget);
    expect(
      find.text('Set up your trip for smarter recommendations.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-language-English')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-firstVisit-Yes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-companion-Solo')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('selected-food-None')), findsOneWidget);
    expect(find.byKey(const ValueKey('tripBasicsNextButton')), findsOneWidget);
  });

  testWidgets('trip length stepper increases and does not go below one', (
    tester,
  ) async {
    await _pumpTripBasics(tester);

    final plusButton = find.byKey(const ValueKey('tripLengthPlus'));
    final minusButton = find.byKey(const ValueKey('tripLengthMinus'));
    await tester.ensureVisible(plusButton);

    expect(find.text('3 days'), findsOneWidget);

    await tester.tap(plusButton);
    await tester.pump();
    expect(find.text('4 days'), findsOneWidget);

    for (var i = 0; i < 5; i += 1) {
      await tester.tap(minusButton);
      await tester.pump();
    }

    expect(find.text('1 days'), findsOneWidget);
  });

  testWidgets('queue help toggle can be changed', (tester) async {
    await _pumpTripBasics(tester);

    final queueSwitch = find.byKey(const ValueKey('queueHelpSwitch'));
    await tester.ensureVisible(queueSwitch);

    expect(tester.widget<Switch>(queueSwitch).value, isTrue);

    await tester.tap(queueSwitch);
    await tester.pump();

    expect(tester.widget<Switch>(queueSwitch).value, isFalse);
  });

  testWidgets('missing header image uses fallback without crashing', (
    tester,
  ) async {
    await _pumpTripBasics(
      tester,
      headerAsset: 'assets/images/onboarding/missing_trip_header.png',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Trip Basics'), findsOneWidget);
  });

  testWidgets('language chips include Korean and switch locale copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final localeController = AppLocaleController(
      preferenceSync: const _NoopLocalePreferenceSync(),
    );
    await localeController.load(deviceLocale: const Locale('en'));

    await _pumpLocalizedTripBasics(tester, localeController);

    expect(
      find.byKey(const ValueKey('selected-language-English')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chip-language-Korean')), findsOneWidget);
    expect(find.text('Trip Basics'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chip-language-Korean')));
    await tester.pumpAndSettle();

    expect(localeController.locale, const Locale('ko'));
    expect(
      find.byKey(const ValueKey('selected-language-Korean')),
      findsOneWidget,
    );
    expect(find.text('여행 기본 정보'), findsOneWidget);
    expect(find.text('1. 선호 언어'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chip-language-English')));
    await tester.pumpAndSettle();

    expect(localeController.locale, const Locale('en'));
    expect(
      find.byKey(const ValueKey('selected-language-English')),
      findsOneWidget,
    );
    expect(find.text('Trip Basics'), findsOneWidget);
    expect(find.text('1. Preferred language'), findsOneWidget);
  });
}

Future<void> _pumpTripBasics(WidgetTester tester, {String? headerAsset}) {
  return tester.pumpWidget(
    MaterialApp(
      home: TripBasicsScreen(
        headerAsset:
            headerAsset ?? 'assets/images/onboarding/trip_basics_header.png',
      ),
    ),
  );
}

Future<void> _pumpLocalizedTripBasics(
  WidgetTester tester,
  AppLocaleController localeController,
) {
  return tester.pumpWidget(
    AppLocaleScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          return MaterialApp(
            locale: localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TripBasicsScreen(),
          );
        },
      ),
    ),
  );
}

class _NoopLocalePreferenceSync extends LocalePreferenceSync {
  const _NoopLocalePreferenceSync();

  @override
  Future<void> syncPreferredLanguage(String userLanguage) async {}
}
