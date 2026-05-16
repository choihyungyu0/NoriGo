import 'package:flutter_test/flutter_test.dart';
import 'package:norigo/data/models/user_preference.dart';

void main() {
  test('user preference parses complete json', () {
    final preference = UserPreference.fromJson({
      'preferredLanguage': 'French',
      'destination': 'South Korea',
      'firstVisit': false,
      'mainPurpose': 'Food',
      'tripLengthDays': 7,
      'needsQueueHelp': true,
      'companionType': 'Couple',
      'foodNeeds': 'Vegetarian',
      'interests': ['Food', 'Cafe'],
      'crowdPreference': 0.4,
      'enableCrowdAlerts': true,
      'enableAiRerouting': true,
      'enableCultureScan': true,
      'enableAudioGuide': true,
      'enableWaitTimeHelp': true,
    });

    expect(preference.preferredLanguage, 'French');
    expect(preference.tripLengthDays, 7);
    expect(preference.interests, contains('Cafe'));
  });

  test('user preference uses safe defaults for missing fields', () {
    final preference = UserPreference.fromJson({});

    expect(preference.preferredLanguage, 'English');
    expect(preference.destination, 'South Korea');
    expect(preference.needsQueueHelp, isTrue);
  });
}
