class InterestsAlerts {
  const InterestsAlerts({
    this.selectedInterests = const {
      'Food',
      'Dessert',
      'Traditional market',
      'Night view',
      'Photo spot',
    },
    this.crowdPreference = 0.35,
    this.realTimeCrowdAlerts = true,
    this.aiRerouting = true,
    this.culturalScanGuide = true,
    this.audioGuide = true,
    this.waitTimeReservationHelp = true,
    this.essentialAccessRequested = false,
  });

  final Set<String> selectedInterests;
  final double crowdPreference;
  final bool realTimeCrowdAlerts;
  final bool aiRerouting;
  final bool culturalScanGuide;
  final bool audioGuide;
  final bool waitTimeReservationHelp;
  final bool essentialAccessRequested;

  InterestsAlerts copyWith({
    Set<String>? selectedInterests,
    double? crowdPreference,
    bool? realTimeCrowdAlerts,
    bool? aiRerouting,
    bool? culturalScanGuide,
    bool? audioGuide,
    bool? waitTimeReservationHelp,
    bool? essentialAccessRequested,
  }) {
    return InterestsAlerts(
      selectedInterests: selectedInterests ?? this.selectedInterests,
      crowdPreference: crowdPreference ?? this.crowdPreference,
      realTimeCrowdAlerts: realTimeCrowdAlerts ?? this.realTimeCrowdAlerts,
      aiRerouting: aiRerouting ?? this.aiRerouting,
      culturalScanGuide: culturalScanGuide ?? this.culturalScanGuide,
      audioGuide: audioGuide ?? this.audioGuide,
      waitTimeReservationHelp:
          waitTimeReservationHelp ?? this.waitTimeReservationHelp,
      essentialAccessRequested:
          essentialAccessRequested ?? this.essentialAccessRequested,
    );
  }
}
