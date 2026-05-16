import 'package:norigo/data/models/crowd_forecast.dart';
import 'package:norigo/data/models/culture_guide.dart';
import 'package:norigo/data/models/dashboard_metric.dart';
import 'package:norigo/data/models/itinerary.dart';
import 'package:norigo/data/models/place.dart';
import 'package:norigo/data/models/recommendation.dart';
import 'package:norigo/data/models/user_preference.dart';
import 'package:norigo/data/models/user_profile.dart';

class MockNoriGoData {
  const MockNoriGoData._();

  static const user = UserProfile(
    id: 'demo-user-emma',
    displayName: 'Emma Kim',
    email: 'emma@example.com',
    badge: 'Local Explorer',
    currentCity: 'Exploring Seoul',
    language: 'English',
  );

  static const preference = UserPreference(
    preferredLanguage: 'English',
    destination: 'South Korea',
    firstVisit: true,
    mainPurpose: 'Culture',
    tripLengthDays: 5,
    needsQueueHelp: true,
    companionType: 'Friends',
    foodNeeds: 'None',
    interests: ['Food', 'Dessert', 'Hanok', 'Photo spot'],
    crowdPreference: 0.18,
    enableCrowdAlerts: true,
    enableAiRerouting: true,
    enableCultureScan: true,
    enableAudioGuide: false,
    enableWaitTimeHelp: true,
  );

  static const itinerary = Itinerary(
    id: 'seoul-day-1',
    title: 'Seoul without the squeeze',
    timeSavedMinutes: 85,
    items: [
      ItineraryItem(
        time: '09:00',
        title: 'Gyeongbokgung Palace',
        crowdLevel: 'Moderate',
        stayTime: '1h 30m',
        recommendationMessage:
            'Enter through the east gate first to avoid tour-bus groups.',
      ),
      ItineraryItem(
        time: '11:00',
        title: 'Bukchon Hanok Village',
        crowdLevel: 'High',
        stayTime: '1h',
        recommendationMessage:
            'Use the quieter north lane and keep voices low near homes.',
      ),
      ItineraryItem(
        time: '13:00',
        title: 'Dessert Cafe',
        crowdLevel: 'Very High',
        stayTime: '45m',
        recommendationMessage:
            'Switch to a nearby cafe before app queues close for lunch.',
      ),
      ItineraryItem(
        time: '15:00',
        title: 'Seongsu Select Shop',
        crowdLevel: 'Low',
        stayTime: '1h 15m',
        recommendationMessage:
            'Good quiet window for browsing local design stores.',
      ),
      ItineraryItem(
        time: '18:30',
        title: 'N Seoul Tower',
        crowdLevel: 'Moderate',
        stayTime: '1h 20m',
        recommendationMessage:
            'Arrive before sunset lines grow at the cable car.',
      ),
    ],
  );

  static const crowdForecast = CrowdForecast(
    placeName: 'Cafe Arte',
    crowdLevel: 'Very High',
    estimatedWaitMin: 40,
    estimatedWaitMax: 60,
    scheduledTime: '13:00',
    appQueueRiskMessage:
        'Even if no visible line, app-based queues may already be full.',
  );

  static const alertAlternatives = [
    Recommendation(
      id: 'cafe-owall',
      placeName: 'Cafe Owall',
      walkingMinutes: 5,
      diversityScore: 92,
      crowdLevel: 'Low',
      rating: 4.7,
      tags: ['Quiet', 'Local pick', 'Dessert'],
      message: 'Same dessert mood with lower app-queue risk.',
    ),
    Recommendation(
      id: 'seosullan-book-cafe',
      placeName: 'Seosullan Small Book Cafe',
      walkingMinutes: 7,
      diversityScore: 88,
      crowdLevel: 'Low',
      rating: 4.6,
      tags: ['Book cafe', 'Quiet', 'Culture'],
      message: 'Calm seating and easy ordering for foreign travelers.',
    ),
    Recommendation(
      id: 'yunsul-bakery',
      placeName: 'Yunsul Bakery',
      walkingMinutes: 8,
      diversityScore: 90,
      crowdLevel: 'Low',
      rating: 4.5,
      tags: ['Bakery', 'Photo-friendly', 'Local pick'],
      message: 'Fresh bakes without the long waitlist pressure.',
    ),
  ];

  static const hiddenSpots = [
    Place(
      id: 'yeonnam-small-garden',
      name: 'Yeonnam Small Garden',
      area: 'Yeonnam',
      category: 'Quiet cafe',
      walkingMinutes: 6,
      crowdLevel: 'Low',
      localVisitRatio: 76,
      diversityScore: 91,
      rating: 4.7,
      tags: ['Local pick', 'Quiet', 'Photo-friendly'],
    ),
    Place(
      id: 'dear-dessert',
      name: 'Dear Dessert',
      area: 'Mangwon',
      category: 'Dessert',
      walkingMinutes: 9,
      crowdLevel: 'Low',
      localVisitRatio: 69,
      diversityScore: 87,
      rating: 4.6,
      tags: ['Dessert', 'Quiet', 'Reservation friendly'],
    ),
    Place(
      id: 'page-turn',
      name: 'Page Turn',
      area: 'Seochon',
      category: 'Culture',
      walkingMinutes: 11,
      crowdLevel: 'Low',
      localVisitRatio: 82,
      diversityScore: 89,
      rating: 4.8,
      tags: ['Culture', 'Local pick', 'Slow travel'],
    ),
  ];

  static const cultureGuide = CultureGuide(
    location: 'Bulguksa',
    koreanText: '소원성취',
    englishMeaning: 'Wishing for your hopes to come true.',
    question: 'Why do Koreans stack stones here?',
    meaning:
        'Stacking stones can express a quiet wish for health, luck, or a safe journey.',
    etiquette:
        'Do not move stones that others placed, and avoid stacking on protected heritage surfaces.',
    story:
        'At temples, small repeated gestures often become personal prayers rather than public performances.',
  );

  static const dashboardMetrics = [
    DashboardMetric(
      label: 'Tourist concentration by area',
      value: '72%',
      trend: '+8%',
      description: 'Peak load in palace and cafe districts.',
    ),
    DashboardMetric(
      label: 'Crowd trend by time',
      value: '13:00',
      trend: 'Peak',
      description: 'Lunch waitlists close earlier than visible lines suggest.',
    ),
    DashboardMetric(
      label: 'Alternative route acceptance rate',
      value: '64%',
      trend: '+12%',
      description:
          'Travelers accept lower-crowd routes after clear AI context.',
    ),
    DashboardMetric(
      label: 'Hidden spot visits',
      value: '18.4k',
      trend: '+21%',
      description: 'Aggregate visits to recommended local alternatives.',
    ),
    DashboardMetric(
      label: 'Local business exposure',
      value: '2.7x',
      trend: '+0.4x',
      description: 'Visibility lift for places outside top tourist corridors.',
    ),
  ];
}
