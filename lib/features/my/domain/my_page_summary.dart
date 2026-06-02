class MyPageSummary {
  const MyPageSummary({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.levelLabel,
    required this.level,
    required this.xp,
    required this.xpTarget,
    required this.locationLabel,
    required this.languageLabel,
    required this.savedPlansCount,
    required this.savedPlacesCount,
    required this.cultureScansCount,
    required this.timeSavedLabel,
    required this.interests,
    required this.foodNeeds,
    required this.latestPlanId,
    required this.localOnly,
    required this.errorMessage,
    this.itineraries = const [],
    this.savedPlaces = const [],
    this.cultureGuides = const [],
    this.retripEvents = const [],
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final String levelLabel;
  final int level;
  final int xp;
  final int xpTarget;
  final String locationLabel;
  final String languageLabel;
  final int savedPlansCount;
  final int savedPlacesCount;
  final int cultureScansCount;
  final String timeSavedLabel;
  final List<String> interests;
  final String foodNeeds;
  final String? latestPlanId;
  final bool localOnly;
  final String? errorMessage;
  final List<MyItineraryPlanPreview> itineraries;
  final List<MySavedPlacePreview> savedPlaces;
  final List<MyCultureGuidePreview> cultureGuides;
  final List<MyRetripEventPreview> retripEvents;

  double get xpProgress {
    if (xpTarget <= 0) return 0;
    return (xp / xpTarget).clamp(0, 1).toDouble();
  }

  String get levelBadge => 'LV.$level';

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'TR';
    if (parts.length == 1) {
      final value = parts.first;
      return value.length == 1
          ? value.toUpperCase()
          : value.substring(0, 2).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get hasPartialData => errorMessage != null && !localOnly;

  MyPageSummary copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? levelLabel,
    int? level,
    int? xp,
    int? xpTarget,
    String? locationLabel,
    String? languageLabel,
    int? savedPlansCount,
    int? savedPlacesCount,
    int? cultureScansCount,
    String? timeSavedLabel,
    List<String>? interests,
    String? foodNeeds,
    String? latestPlanId,
    bool? localOnly,
    String? errorMessage,
    List<MyItineraryPlanPreview>? itineraries,
    List<MySavedPlacePreview>? savedPlaces,
    List<MyCultureGuidePreview>? cultureGuides,
    List<MyRetripEventPreview>? retripEvents,
  }) {
    return MyPageSummary(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      levelLabel: levelLabel ?? this.levelLabel,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpTarget: xpTarget ?? this.xpTarget,
      locationLabel: locationLabel ?? this.locationLabel,
      languageLabel: languageLabel ?? this.languageLabel,
      savedPlansCount: savedPlansCount ?? this.savedPlansCount,
      savedPlacesCount: savedPlacesCount ?? this.savedPlacesCount,
      cultureScansCount: cultureScansCount ?? this.cultureScansCount,
      timeSavedLabel: timeSavedLabel ?? this.timeSavedLabel,
      interests: interests ?? this.interests,
      foodNeeds: foodNeeds ?? this.foodNeeds,
      latestPlanId: latestPlanId ?? this.latestPlanId,
      localOnly: localOnly ?? this.localOnly,
      errorMessage: errorMessage ?? this.errorMessage,
      itineraries: itineraries ?? this.itineraries,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      cultureGuides: cultureGuides ?? this.cultureGuides,
      retripEvents: retripEvents ?? this.retripEvents,
    );
  }

  factory MyPageSummary.localPreview({String? errorMessage}) {
    return MyPageSummary(
      displayName: 'Emma Kim',
      email: 'emma@example.com',
      avatarUrl: null,
      levelLabel: 'Local Explorer',
      level: 3,
      xp: 3250,
      xpTarget: 5000,
      locationLabel: 'Exploring Seoul',
      languageLabel: 'English',
      savedPlansCount: 0,
      savedPlacesCount: 0,
      cultureScansCount: 0,
      timeSavedLabel: '0m',
      interests: const ['Food', 'Hanok', 'Photo spot', 'Night view'],
      foodNeeds: 'None',
      latestPlanId: null,
      localOnly: true,
      errorMessage: errorMessage,
    );
  }
}

class MyItineraryPlanPreview {
  const MyItineraryPlanPreview({
    required this.id,
    required this.title,
    required this.createdAtLabel,
    required this.sourceBadge,
    required this.summary,
    required this.placeNames,
  });

  final String id;
  final String title;
  final String createdAtLabel;
  final String sourceBadge;
  final String summary;
  final List<String> placeNames;
}

class MySavedPlacePreview {
  const MySavedPlacePreview({required this.name, required this.subtitle});

  final String name;
  final String subtitle;
}

class MyCultureGuidePreview {
  const MyCultureGuidePreview({
    required this.title,
    required this.subtitle,
    required this.createdAtLabel,
    this.locationName = '',
    this.detectedObject = '',
    this.sourceBadge = '',
    this.koreanPhrase = '',
  });

  final String title;
  final String subtitle;
  final String createdAtLabel;
  final String locationName;
  final String detectedObject;
  final String sourceBadge;
  final String koreanPhrase;
}

class MyRetripEventPreview {
  const MyRetripEventPreview({
    required this.originalPlaceName,
    required this.triggerType,
    required this.sourceBadge,
    required this.createdAtLabel,
  });

  final String originalPlaceName;
  final String triggerType;
  final String sourceBadge;
  final String createdAtLabel;
}
