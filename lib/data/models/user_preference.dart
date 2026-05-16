class UserPreference {
  const UserPreference({
    required this.preferredLanguage,
    required this.destination,
    required this.firstVisit,
    required this.mainPurpose,
    required this.tripLengthDays,
    required this.needsQueueHelp,
    required this.companionType,
    required this.foodNeeds,
    required this.interests,
    required this.crowdPreference,
    required this.enableCrowdAlerts,
    required this.enableAiRerouting,
    required this.enableCultureScan,
    required this.enableAudioGuide,
    required this.enableWaitTimeHelp,
  });

  final String preferredLanguage;
  final String destination;
  final bool firstVisit;
  final String mainPurpose;
  final int tripLengthDays;
  final bool needsQueueHelp;
  final String companionType;
  final String foodNeeds;
  final List<String> interests;
  final double crowdPreference;
  final bool enableCrowdAlerts;
  final bool enableAiRerouting;
  final bool enableCultureScan;
  final bool enableAudioGuide;
  final bool enableWaitTimeHelp;

  factory UserPreference.fromJson(Map<String, Object?> json) {
    return UserPreference(
      preferredLanguage: json['preferredLanguage'] as String? ?? 'English',
      destination: json['destination'] as String? ?? 'South Korea',
      firstVisit: json['firstVisit'] as bool? ?? true,
      mainPurpose: json['mainPurpose'] as String? ?? 'Sightseeing',
      tripLengthDays: json['tripLengthDays'] as int? ?? 3,
      needsQueueHelp: json['needsQueueHelp'] as bool? ?? true,
      companionType: json['companionType'] as String? ?? 'Solo',
      foodNeeds: json['foodNeeds'] as String? ?? 'None',
      interests: List<String>.from(
        (json['interests'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>(),
      ),
      crowdPreference: (json['crowdPreference'] as num?)?.toDouble() ?? 0.25,
      enableCrowdAlerts: json['enableCrowdAlerts'] as bool? ?? true,
      enableAiRerouting: json['enableAiRerouting'] as bool? ?? true,
      enableCultureScan: json['enableCultureScan'] as bool? ?? true,
      enableAudioGuide: json['enableAudioGuide'] as bool? ?? false,
      enableWaitTimeHelp: json['enableWaitTimeHelp'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'preferredLanguage': preferredLanguage,
      'destination': destination,
      'firstVisit': firstVisit,
      'mainPurpose': mainPurpose,
      'tripLengthDays': tripLengthDays,
      'needsQueueHelp': needsQueueHelp,
      'companionType': companionType,
      'foodNeeds': foodNeeds,
      'interests': interests,
      'crowdPreference': crowdPreference,
      'enableCrowdAlerts': enableCrowdAlerts,
      'enableAiRerouting': enableAiRerouting,
      'enableCultureScan': enableCultureScan,
      'enableAudioGuide': enableAudioGuide,
      'enableWaitTimeHelp': enableWaitTimeHelp,
    };
  }
}
