import 'package:flutter/material.dart';
import 'package:norigo/features/auth/presentation/login_screen.dart';
import 'package:norigo/features/culture_scan/presentation/culture_scan_screen.dart';
import 'package:norigo/features/dashboard/public_dashboard_screen.dart';
import 'package:norigo/features/itinerary/presentation/ai_itinerary_planner_screen.dart';
import 'package:norigo/features/itinerary/presentation/crowd_alert_screen.dart';
import 'package:norigo/features/itinerary/presentation/step3_mobile_mockups_screen.dart';
import 'package:norigo/features/onboarding/presentation/interests_alerts_screen.dart';
import 'package:norigo/features/onboarding/presentation/trip_basics_screen.dart';
import 'package:norigo/features/splash/presentation/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const root = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const tripBasics = '/onboarding/trip-basics';
  static const interests = '/onboarding/interests';
  static const interestsAlerts = '/onboarding/interests-alerts';
  static const itinerary = '/itinerary';
  static const itineraryCrowdAlert = '/itinerary/crowd-alert';
  static const step3MobileMockups = '/spec/step3-mobile-mockups';
  static const step3CrowdAlert = '/step3/crowd-alert';
  static const step3Alternatives = '/step3/alternatives';
  static const step3UpdatedItinerary = '/step3/updated-itinerary';
  static const home = '/home';
  static const scan = '/scan';
  static const cultureScan = '/culture-scan';
  static const crowdAlert = '/crowd-alert';
  static const dashboard = '/dashboard';
}

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.root: (_) => const SplashScreen(),
      AppRoutes.splash: (_) => const SplashScreen(),
      AppRoutes.login: (_) => const LoginScreen(),
      AppRoutes.tripBasics: (_) => const TripBasicsScreen(),
      AppRoutes.interests: (_) => const InterestsAlertsScreen(),
      AppRoutes.interestsAlerts: (_) => const InterestsAlertsScreen(),
      AppRoutes.itinerary: (_) => const AiItineraryPlannerScreen(),
      AppRoutes.itineraryCrowdAlert: (_) => const CrowdAlertScreen(),
      AppRoutes.step3MobileMockups: (_) => const Step3MobileMockupsScreen(),
      AppRoutes.step3CrowdAlert: (_) => const Step3CrowdAlertScreen(),
      AppRoutes.step3Alternatives: (_) => const Step3AlternativePlacesScreen(),
      AppRoutes.step3UpdatedItinerary: (_) =>
          const Step3UpdatedItineraryScreen(),
      AppRoutes.home: (_) => const Step3CrowdAlertScreen(),
      AppRoutes.scan: (_) => const CultureScanScreen(),
      AppRoutes.cultureScan: (_) => const CultureScanScreen(),
      AppRoutes.crowdAlert: (_) => const CrowdAlertScreen(),
      AppRoutes.dashboard: (_) => const PublicDashboardScreen(),
    };
  }
}
