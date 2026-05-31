class TripBasics {
  const TripBasics({
    this.preferredLanguage = 'English',
    this.destination = 'South Korea',
    this.baseLocation = 'Myeongdong, Seoul',
    this.isFirstVisit = true,
    this.mainPurpose = 'Sightseeing',
    this.tripLengthDays = 3,
    this.needQueueHelp = true,
    this.companionType = 'Solo',
    this.foodNeed = 'None',
  });

  final String preferredLanguage;
  final String destination;
  final String baseLocation;
  final bool isFirstVisit;
  final String mainPurpose;
  final int tripLengthDays;
  final bool needQueueHelp;
  final String companionType;
  final String foodNeed;

  TripBasics copyWith({
    String? preferredLanguage,
    String? destination,
    String? baseLocation,
    bool? isFirstVisit,
    String? mainPurpose,
    int? tripLengthDays,
    bool? needQueueHelp,
    String? companionType,
    String? foodNeed,
  }) {
    return TripBasics(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      destination: destination ?? this.destination,
      baseLocation: baseLocation ?? this.baseLocation,
      isFirstVisit: isFirstVisit ?? this.isFirstVisit,
      mainPurpose: mainPurpose ?? this.mainPurpose,
      tripLengthDays: tripLengthDays ?? this.tripLengthDays,
      needQueueHelp: needQueueHelp ?? this.needQueueHelp,
      companionType: companionType ?? this.companionType,
      foodNeed: foodNeed ?? this.foodNeed,
    );
  }
}
